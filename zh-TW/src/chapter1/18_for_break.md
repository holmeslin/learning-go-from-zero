# `for` 無限迴圈 + `break`

## 本集目標

用 `for` 讓程式重複執行同一段程式碼，並用 `break` 跳出來。

## 正文

上一集的程式只能問一次。如果使用者打錯了，程式就結束了，得重新執行一次。要是能「一直問，直到答對為止」就好了。

讓程式重複做事的東西，叫做**迴圈**。Go 的迴圈只有一個關鍵字：`for`。

### 最簡單的 `for`

```go,norun
package main

import "fmt"

func main() {
	for {
		fmt.Println("停不下來！")
	}
}
```

`for` 後面直接接大括號，大括號裡的程式碼會**一直重複執行，永遠不會停**。這叫做**無限迴圈**。

這支程式會不停地印出「停不下來！」。如果你執行了它，在終端機按 `Ctrl` + `C` 就能強制停止程式。

### 用 `break` 跳出迴圈

要讓迴圈停下來，就在裡面放一個 `break`。程式一執行到 `break`，就會立刻跳出迴圈，接著執行迴圈後面的程式碼。`break` 通常會搭配 `if` 使用：

```go
package main

import "fmt"

func main() {
	count := 1
	for {
		fmt.Println("第", count, "次")
		if count == 3 {
			break
		}
		count++
	}
	fmt.Println("結束")
}
```

執行結果：

```text
第 1 次
第 2 次
第 3 次
結束
```

一步一步看：

1. `count` 是 1，印出「第 1 次」。1 不等於 3，不 `break`，`count` 變成 2，回到迴圈開頭。
2. 印出「第 2 次」，`count` 變成 3，回到開頭。
3. 印出「第 3 次」。這次 `count == 3` 成立，執行 `break`，跳出迴圈。
4. 執行迴圈後面的程式碼，印出「結束」。

### 一直問，直到輸入正確

`for` + `break` 最適合用在「不知道要重複幾次」的情況，例如一直問到使用者輸入整數為止：

```go,stdin=abc\n3.5\n42
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("請輸入一個整數：")
		scanner.Scan()
		line := scanner.Text()
		n, err := strconv.Atoi(line)
		if err != nil {
			fmt.Println("這不是整數，再試一次")
		} else {
			fmt.Println("你輸入的是", n)
			break
		}
	}
}
```

依序輸入 `abc`、`3.5`、`42`，程式印出：

```text
請輸入一個整數：
這不是整數，再試一次
請輸入一個整數：
這不是整數，再試一次
請輸入一個整數：
你輸入的是 42
```

注意這裡轉換失敗時**沒有**用 `return` 結束程式，而是印出提示，讓迴圈回到開頭再問一次。只有輸入正確時才 `break`。

## 重點整理

- `for { ... }` 會一直重複執行大括號裡的程式碼，叫做無限迴圈。
- 執行到 `break` 會立刻跳出迴圈，接著執行迴圈後面的程式碼。
- 不知道要重複幾次時，可以用 `for` + `if` + `break`。
- 程式停不下來時，在終端機按 `Ctrl` + `C` 強制結束。
