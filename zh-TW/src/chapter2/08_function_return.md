# 函式回傳值

## 本集目標

讓函式用 `return` 把算好的結果交回給呼叫的人。

## 正文

上一集的 `addOne` 只能自己把結果印出來，呼叫的人拿不到。很多時候我們希望函式「算完之後把答案交回來」，讓呼叫的人決定要拿它做什麼。這個交回來的值叫做**回傳值**。

### 宣告回傳型別，用 `return` 交回去

```go
package main

import "fmt"

func add(a, b int) int {
	return a + b
}

func main() {
	sum := add(3, 4)
	fmt.Println(sum)
	fmt.Println(add(10, 20) * 2)
}
```

執行結果：

```text
7
60
```

和之前比，有兩個地方不一樣：

- 參數的小括號後面多了一個 `int`，這是**回傳型別**，表示「這個函式會交回一個 `int`」。
- 函式裡用 `return a + b` 把結果交回去。

呼叫 `add(3, 4)` 的地方，就會變成函式交回來的值 7。所以我們可以把它存進變數，也可以直接拿去做計算，像 `add(10, 20) * 2`。

### `return` 會立刻離開函式

執行到 `return`，函式就結束了，後面的程式碼不會執行：

```go
package main

import "fmt"

func check(n int) string {
	if n > 100 {
		return "太大了"
	}
	fmt.Println("檢查", n, "通過")
	return "OK"
}

func main() {
	fmt.Println(check(500))
	fmt.Println(check(5))
}
```

執行結果：

```text
太大了
檢查 5 通過
OK
```

`check(500)` 走進 `if`，碰到 `return "太大了"` 就直接離開，所以「檢查……通過」那行只在 `check(5)` 時印出來。

### 有回傳型別，就一定要 `return`

宣告了回傳型別，函式就必須保證每一條路最後都有 `return`。只寫在 `if` 裡面是不夠的：

```go,compile_fail
package main

import "fmt"

func sign(n int) string {
	if n >= 0 {
		return "正數或零"
	}
}

func main() {
	fmt.Println(sign(-3))
}
```

```text
missing return
```

`n` 小於 0 的時候，函式會走到結尾卻沒有東西可以交回去，所以 Go 不讓它編譯。補上 `else` 或在最後加一個 `return` 就好：

```go
package main

import "fmt"

func sign(n int) string {
	if n >= 0 {
		return "正數或零"
	}
	return "負數"
}

func main() {
	fmt.Println(sign(-3))
	fmt.Println(sign(8))
}
```

執行結果：

```text
負數
正數或零
```

### 回傳值的型別要對

`return` 交回去的值，型別必須和宣告的回傳型別一致。宣告了 `int` 就不能 `return "七"`，否則一樣無法編譯。

## 重點整理

- 在參數小括號後寫上回傳型別，例如 `func add(a, b int) int`。
- 用 `return 值` 把結果交回呼叫端，呼叫的地方就會變成那個值。
- 執行到 `return`，函式立刻結束。
- 有回傳型別的函式，每一條執行路徑都必須以 `return` 結束。
