# 多個回傳值

## 本集目標

讓一個函式同時回傳好幾個值，並看懂 `strconv.Atoi` 的真面目。

## 正文

### 一次交回兩個值

Go 的函式可以回傳不只一個值。把回傳型別用小括號包起來就行了：

```go
package main

import "fmt"

func divide(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	q, r := divide(17, 5)
	fmt.Println("商", q, "餘", r)
}
```

執行結果：

```text
商 3 餘 2
```

- `(int, int)` 表示這個函式會回傳兩個 `int`。
- `return a / b, a % b` 用逗號隔開，一次交回兩個值。
- 呼叫端用第 4 集學過的多重賦值 `q, r := ...` 接住，第一個值給 `q`，第二個給 `r`。

回傳幾個值，就要用幾個變數接。只想要其中一個的話，另一個交給 `_`：

```go
package main

import "fmt"

func divide(a, b int) (int, int) {
	return a / b, a % b
}

func main() {
	_, r := divide(17, 5)
	fmt.Println("餘數是", r)
}
```

執行結果：

```text
餘數是 2
```

### 原來 `strconv.Atoi` 也是這樣

第 1 章我們照抄過這個固定句型：

```go,ignore
n, err := strconv.Atoi(line)
if err != nil {
	fmt.Println("請輸入整數")
	return
}
```

現在你看得懂它了：`strconv.Atoi` 就是一個**回傳兩個值**的函式。第一個是轉好的整數，第二個是「錯誤」。轉換成功時，`err` 是 `nil`（代表「沒有錯誤」）；失敗時，`err` 裡就會裝著錯誤的資訊。

Go 很常用這種「結果 + 錯誤」的組合回傳值，讓呼叫的人一定會看到可能出錯的情況。`err` 的型別 `error` 到底是什麼，第 5 章會正式介紹，目前照固定句型檢查 `if err != nil` 就好。

### 自己寫一個「結果 + 成不成功」

我們還不會自己做出 `error`，但可以用 `bool` 模仿同樣的精神：

```go,stdin=0
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func safeDivide(a, b int) (int, bool) {
	if b == 0 {
		return 0, false
	}
	return a / b, true
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	line := scanner.Text()

	n, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}

	result, ok := safeDivide(100, n)
	if !ok {
		fmt.Println("不能除以 0")
		return
	}
	fmt.Println("100 除以", n, "等於", result)
}
```

輸入 `0` 的執行結果：

```text
不能除以 0
```

`safeDivide` 除了答案，還多回傳一個 `bool` 告訴我們「這次算得成不成功」。呼叫的人先檢查 `ok`，再使用 `result`。

## 重點整理

- 回傳型別寫成 `(型別1, 型別2)`，函式就能用 `return 值1, 值2` 回傳多個值。
- 呼叫端用 `a, b := f()` 接住所有回傳值，不需要的用 `_` 丟掉。
- `strconv.Atoi` 回傳「整數」和「錯誤」兩個值，`err` 為 `nil` 代表沒有錯誤；`error` 的細節第 5 章再談。
- 「結果 + 成不成功」是 Go 很常見的回傳方式。
