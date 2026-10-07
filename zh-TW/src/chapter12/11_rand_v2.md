# `math/rand/v2`

## 本集目標

用 `math/rand/v2` 產生亂數：`IntN`、泛型的 `rand.N`、`Shuffle`，並學會用固定的種子讓「亂數」可以重現。

## 正文

### 擲骰子

```go
package main

import (
	"fmt"
	"math/rand/v2"
)

func main() {
	for range 5 {
		fmt.Print(rand.IntN(6)+1, " ")
	}
	fmt.Println()
	fmt.Println(rand.Float64())
}
```

執行結果（某一次）：

```text
4 6 3 5 6 
0.8711263607182381
```

- `rand.IntN(n)` 回傳 `0` 到 `n-1` 之間的整數，包含 0、不包含 n。所以骰子要 `+1`。
- `rand.Float64()` 回傳 `0.0`（含）到 `1.0`（不含）之間的小數。
- 每次執行結果都不同。v2 的套件函式一開始就自動用隨機的種子，不需要（也沒辦法）自己呼叫 `Seed`。網路上舊的教學會叫你寫 `rand.Seed(time.Now().UnixNano())`，那是舊版 `math/rand` 的做法，v2 不用。

套件路徑結尾的 `/v2` 表示這是第二版，套件名稱仍然是 `rand`。

### 泛型的 `rand.N`

`IntN` 只能用在 `int`。`rand.N` 是第 6 章介紹的泛型函式，可以用在**任何整數型別**，連 `time.Duration` 也可以，因為它的底層型別是 `int64`：

```go
package main

import (
	"fmt"
	"math/rand/v2"
	"time"
)

func main() {
	var small uint8 = rand.N(uint8(100))
	fmt.Println("uint8:", small)

	wait := rand.N(3 * time.Second)
	fmt.Println("隨機等待:", wait)
}
```

執行結果（某一次）：

```text
uint8: 92
隨機等待: 820.283349ms
```

`rand.N(3 * time.Second)` 回傳 0 到 3 秒之間隨機的一段時間，型別仍然是 `time.Duration`。重試網路連線時，常用它在每次重試之間加一點隨機的延遲，避免所有程式同時重試。

### 固定種子：讓亂數可以重現

寫測試、做模擬、或像這本書一樣需要固定的輸出時，我們希望「亂數」每次都一樣。做法是自己建立一個 `*rand.Rand`，並給它固定的**種子**（seed）：

```go
package main

import (
	"fmt"
	"math/rand/v2"
)

func main() {
	r := rand.New(rand.NewPCG(1, 2))
	for range 5 {
		fmt.Print(r.IntN(6)+1, " ")
	}
	fmt.Println()

	r2 := rand.New(rand.NewPCG(1, 2))
	for range 5 {
		fmt.Print(r2.IntN(6)+1, " ")
	}
	fmt.Println()
}
```

執行結果：

```text
5 4 5 5 2 
5 4 5 5 2 
```

- `rand.NewPCG(1, 2)` 建立一個 PCG 演算法的亂數來源，`1` 和 `2` 就是種子。
- `rand.New(來源)` 回傳 `*rand.Rand`，它有和套件函式同名的方法：`r.IntN`、`r.Float64` 等。
- 種子相同，產生的數列就完全相同，所以 `r` 和 `r2` 印出一樣的結果。這就是「偽亂數」：看起來亂，其實是從種子算出來的。

注意 `*rand.Rand` **不能**同時被多個 goroutine 使用（第 9 章的 data race），需要的話要加鎖；套件層級的 `rand.IntN` 等函式則可以安全地並行呼叫。

### 洗牌：`Shuffle` 與 `Perm`

```go
package main

import (
	"fmt"
	"math/rand/v2"
)

func main() {
	r := rand.New(rand.NewPCG(1, 2))

	cards := []string{"A", "2", "3", "4", "5", "6"}
	r.Shuffle(len(cards), func(i, j int) {
		cards[i], cards[j] = cards[j], cards[i]
	})
	fmt.Println(cards)

	fmt.Println(r.Perm(5))
}
```

執行結果：

```text
[2 6 3 A 4 5]
[4 2 3 1 0]
```

- `Shuffle(n, swap)` 把 `0` 到 `n-1` 的位置隨機打亂。它不知道你的切片長什麼樣子，所以要傳一個「交換第 i 個和第 j 個」的函式給它，這裡用第 2 章的多重賦值交換。
- `Perm(n)` 回傳 `0` 到 `n-1` 的一個隨機排列。

### Go 1.27：`(*Rand).N` 泛型方法

以前 `rand.N` 只有套件層級的函式版本，因為 Go 的方法不能有自己的型別參數。Go 1.27 加入了泛型方法（第 6 章第 13 集），`*rand.Rand` 也跟著有了 `N` 方法：

```go
package main

import (
	"fmt"
	"math/rand/v2"
	"time"
)

func main() {
	r := rand.New(rand.NewPCG(1, 2))
	fmt.Println(r.N(int64(1000)))
	fmt.Println(r.N(uint16(10)))
	fmt.Println(r.N(10 * time.Second))
}
```

執行結果：

```text
769
6
7.844280016s
```

這樣固定種子的 `*rand.Rand` 也能直接產生 `time.Duration` 或其他整數型別的亂數，不必先產生 `int64` 再轉型。

### 不要用在安全相關的地方

`math/rand/v2` 的亂數是可以被預測的，**不能**拿來產生密碼、登入權杖、加密金鑰。這些情況要用 `crypto/rand`，例如 `crypto/rand.Text()` 會產生一段適合當密碼或權杖的隨機文字。下一集的 `uuid` 也是用安全的亂數產生器。

## 重點整理

- `rand.IntN(n)` 產生 `[0, n)` 的整數，`rand.Float64()` 產生 `[0.0, 1.0)` 的小數；v2 自動使用隨機種子。
- `rand.N` 是泛型函式，適用任何整數型別，包括 `time.Duration`。
- `rand.New(rand.NewPCG(種子1, 種子2))` 建立固定種子的 `*rand.Rand`，結果可以重現；它不能被多個 goroutine 同時使用。
- `r.Shuffle` 打亂切片、`r.Perm` 產生隨機排列；Go 1.27 起 `*rand.Rand` 也有泛型方法 `N`。
- 安全相關的亂數要用 `crypto/rand`。
