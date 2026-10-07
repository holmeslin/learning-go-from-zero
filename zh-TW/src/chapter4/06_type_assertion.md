# 型別斷言

## 本集目標

用型別斷言 `x.(型別)` 從介面裡取出原本的值，並用 comma-ok 寫法安全地檢查型別。

## 正文

上一集我們發現，`any` 裡裝了 `10` 也不能直接拿來加。我們需要一個方法告訴 Go：「我確定裡面是 `int`，請把它拿出來給我。」

### `x.(型別)`

```go
package main

import "fmt"

func main() {
	var x any = 10
	n := x.(int)
	fmt.Println(n + 1)
}
```

執行結果：

```text
11
```

`x.(int)` 叫做**型別斷言**（type assertion）。意思是：「我斷定 `x` 的動態型別是 `int`。」如果猜對了，就會得到裡面的值，型別是 `int`，可以正常做加法。

型別斷言只能用在介面上，`any` 和上一章的 `Shape` 這類介面都可以。

### 猜錯就 panic

如果猜錯了呢？

```go,exit=2
package main

import "fmt"

func main() {
	var x any = "hello"
	n := x.(int)
	fmt.Println(n)
}
```

執行結果：

```text
panic: interface conversion: interface {} is string, not int
```

（後面幾行出錯位置的資訊省略。）錯誤訊息說得很清楚：介面裡裝的是 `string`，不是 `int`。程式以結束碼 2 結束。注意訊息裡寫的是 `interface {}`，因為 `any` 只是它的別名。

### comma-ok：先問再拿

不確定裡面是什麼型別時，可以多接一個 `bool`，這就是第 2 章在 map 學過的 comma-ok 寫法：

```go
package main

import "fmt"

func main() {
	var x any = "hello"

	n, ok := x.(int)
	fmt.Println(n, ok)

	s, ok := x.(string)
	fmt.Println(s, ok)
}
```

執行結果：

```text
0 false
hello true
```

- 猜對：`ok` 是 `true`，第一個值是裡面的值。
- 猜錯：`ok` 是 `false`，第一個值是那個型別的零值，**不會** panic。

搭配 `if` 的初始化敘述，常常會寫成這樣：

```go
package main

import "fmt"

func describe(x any) {
	if n, ok := x.(int); ok {
		fmt.Println("整數，兩倍是", n*2)
		return
	}
	if s, ok := x.(string); ok {
		fmt.Println("字串，長度是", len(s))
		return
	}
	fmt.Println("不認識的型別")
}

func main() {
	describe(21)
	describe("Go")
	describe(3.14)
}
```

執行結果：

```text
整數，兩倍是 42
字串，長度是 2
不認識的型別
```

### 斷言成另一個介面

斷言的目標也可以是介面，意思是「裡面的值有沒有實作這個介面」：

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Rect struct {
	Width  float64
	Height float64
}

func (r Rect) Area() float64 {
	return r.Width * r.Height
}

func main() {
	items := []any{Rect{Width: 2, Height: 5}, "hello"}
	for _, item := range items {
		if s, ok := item.(Shape); ok {
			fmt.Println("是形狀，面積", s.Area())
		} else {
			fmt.Println("不是形狀：", item)
		}
	}
}
```

執行結果：

```text
是形狀，面積 10
不是形狀： hello
```

`Rect` 有 `Area` 方法，所以 `item.(Shape)` 成功；字串沒有，所以 `ok` 是 `false`。

## 重點整理

- 型別斷言 `x.(T)` 從介面 `x` 中取出型別為 `T` 的值。
- 只寫 `v := x.(T)` 時，型別不對會 panic（結束碼 2）。
- `v, ok := x.(T)` 是 comma-ok 寫法：型別不對時 `ok` 為 `false`、`v` 是零值，不會 panic。
- `T` 也可以是介面，用來檢查裡面的值有沒有實作該介面。
