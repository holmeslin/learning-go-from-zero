# `make`

## 本集目標

用內建的 `make` 建立指定長度（和容量）的切片。

## 正文

到目前為止，我們建立切片的方法有兩種：直接寫出元素 `[]int{1, 2, 3}`，或從 `nil` 開始 `append`。如果想要「一個長度 100、先全部是 0 的切片」，總不能寫一百個 0 吧？這時就用 `make`。

### 指定長度

```go
package main

import "fmt"

func main() {
	scores := make([]int, 5)
	fmt.Println(scores, len(scores), cap(scores))

	scores[2] = 80
	fmt.Println(scores)
}
```

執行結果：

```text
[0 0 0 0 0] 5 5
[0 0 80 0 0]
```

`make([]int, 5)` 建立一個長度 5 的切片，每個元素都是零值。長度可以是執行時才知道的數字，例如使用者輸入的人數：

```go,stdin=3
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	line := scanner.Text()

	n, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}

	seats := make([]string, n)
	for i := range seats {
		seats[i] = "空位"
	}
	fmt.Println(seats)
}
```

輸入 `3` 的執行結果：

```text
[空位 空位 空位]
```

陣列的長度必須寫死在程式裡，`make` 就沒有這個限制。

### 配合 `copy`

第 19 集我們手動寫了 `[]int{0, 0, 0}` 當作 `copy` 的目的地。用 `make` 就能做出剛好一樣長的目的地：

```go
package main

import "fmt"

func main() {
	src := []int{1, 2, 3, 4}
	dst := make([]int, len(src))
	copy(dst, src)

	dst[0] = 99
	fmt.Println(src, dst)
}
```

執行結果：

```text
[1 2 3 4] [99 2 3 4]
```

這是 Go 裡複製切片最經典的兩行。

### 同時指定容量

`make` 還可以有第三個值：容量。

```go
package main

import "fmt"

func main() {
	nums := make([]int, 0, 10)
	fmt.Println(len(nums), cap(nums))

	for i := range 5 {
		nums = append(nums, i*i)
	}
	fmt.Println(nums, len(nums), cap(nums))
}
```

執行結果：

```text
0 10
[0 1 4 9 16] 5 10
```

`make([]int, 0, 10)` 建立一個長度 0、容量 10 的切片：一開始一個元素都沒有，但底層陣列已經準備好 10 格。只要 `append` 不超過 10 個，就不需要換新陣列。

如果事先知道大概會放多少東西，這樣寫可以省下多次「換大陣列再複製」的工夫。不知道的話，從 `nil` 開始 `append` 也完全沒問題。

### 長度和容量別搞混

常見的錯誤是想要「準備空間然後 `append`」，卻寫成了 `make([]int, 5)`：

```go
package main

import "fmt"

func main() {
	nums := make([]int, 5)
	nums = append(nums, 1)
	fmt.Println(nums)
}
```

執行結果：

```text
[0 0 0 0 0 1]
```

長度 5 代表**已經有** 5 個 0 了，`append` 會接在它們後面。想先準備空間再 `append`，要寫 `make([]int, 0, 5)`。

## 重點整理

- `make([]T, n)` 建立長度與容量都是 `n` 的切片，元素為零值；`n` 可以是執行時才決定的值。
- `make([]T, 0, c)` 建立長度 0、容量 `c` 的切片，適合之後用 `append` 放入元素。
- `dst := make([]T, len(src))` 加上 `copy(dst, src)` 是複製切片的經典寫法。
- 長度是「已經有幾個元素」，容量是「準備了幾格空間」，用 `make` 時別搞混。
