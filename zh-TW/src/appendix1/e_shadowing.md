# shadowing 陷阱

## 本集目標

認出 `:=` 在內層作用域「意外建立新變數」的情況，尤其是常見的 `err` 被遮蔽問題。

## 正文

第 1 章學過作用域：大括號裡面可以宣告和外面同名的變數。這時內層的新變數會把外層那個「遮住」，在內層看不到外層的變數。這叫做 **shadowing**（遮蔽）。

shadowing 本身是合法的，問題是它很容易在**不小心**的時候發生。

### `:=` 一不小心就是新變數

```go
package main

import "fmt"

func main() {
	count := 0
	for i := range 3 {
		count := count + i
		fmt.Println("迴圈裡", count)
	}
	fmt.Println("迴圈外", count)
}
```

執行結果：

```text
迴圈裡 0
迴圈裡 1
迴圈裡 2
迴圈外 0
```

本來想把 `i` 累加進 `count`，結果最後還是 0。原因是迴圈裡寫的是 `:=`，它在迴圈的區塊裡**建立了一個新的** `count`。每一輪都是新變數，外面的 `count` 從頭到尾沒被動過。把 `:=` 改成 `=`，或者寫成 `count += i`，就會修改外面那個。

### 最常見的受害者：`err`

`err` 幾乎每個函式都會用到，所以它最容易被遮蔽。看這個例子：

```go
package main

import (
	"fmt"
	"strconv"
)

func parseAll(a, b string) (int, error) {
	var err error
	x, err := strconv.Atoi(a)
	if err != nil {
		return 0, err
	}
	if b != "" {
		y, err := strconv.Atoi(b)
		if err == nil {
			x += y
		}
	}
	return x, err
}

func main() {
	n, err := parseAll("10", "abc")
	fmt.Println(n, err)
}
```

執行結果：

```text
10 <nil>
```

`"abc"` 明明不是數字，函式卻回傳了 `nil` 錯誤。問題在 `if b != ""` 裡面那行 `y, err := ...`：因為 `y` 是新變數，`:=` 就在這個區塊裡**連 `err` 也一起建立了新的**。轉換失敗的錯誤存進了內層的 `err`，離開區塊就消失了；最後回傳的是外層那個，還是 `nil`。

修正方法是在內層用 `=`，讓錯誤寫進外層的 `err`：

```go
package main

import (
	"fmt"
	"strconv"
)

func parseAll(a, b string) (int, error) {
	x, err := strconv.Atoi(a)
	if err != nil {
		return 0, err
	}
	if b != "" {
		var y int
		y, err = strconv.Atoi(b)
		if err == nil {
			x += y
		}
	}
	return x, err
}

func main() {
	n, err := parseAll("10", "abc")
	fmt.Println(n, err)
}
```

執行結果：

```text
10 strconv.Atoi: parsing "abc": invalid syntax
```

更好的做法，通常是一發現錯誤就 early `return`，讓錯誤沒機會在區塊裡「待太久」。

### `:=` 什麼時候會建立新變數？

規則是：`:=` 左邊**至少要有一個**這個作用域裡的新變數。

- 在**同一個**作用域裡，已經存在的變數會被重新賦值，新的才會被建立。所以有問題的那個版本裡，`x, err := strconv.Atoi(a)` 只建立了 `x`，`err` 沿用了前一行 `var err error` 宣告的那個。
- 在**內層**作用域裡，左邊所有名字都會建立新變數，就算外層已經有同名的也一樣。

### 工具抓得到嗎？

`go vet` 預設**不會**檢查 shadowing，所以上面這些程式都能順利通過 `go vet`。Go 團隊另外提供了一個專門的 shadow 分析工具，但它不在預設的檢查裡，而且會有不少誤報。

最可靠的還是自己的習慣：在 `if`、`for` 的大括號裡看到 `:=`，問自己一句「我是要新變數，還是要改外面那個？」

## 重點整理

- 內層作用域用 `:=` 會建立新變數，遮蔽外層同名變數，外層的值不會改變。
- `err` 最容易被遮蔽：內層的 `y, err := ...` 會連 `err` 一起新建。
- 想修改外層變數就用 `=`，必要時先用 `var` 宣告其他新變數。
- `go vet` 預設不會抓 shadowing，要靠自己留意。
