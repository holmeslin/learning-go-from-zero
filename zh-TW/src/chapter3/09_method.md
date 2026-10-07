# 方法

## 本集目標

幫自己的型別加上方法，用 `值.方法()` 的方式呼叫。

## 正文

第 2 章我們寫過很多函式。假設要算一個長方形的面積，可能會這樣寫：

```go
package main

import "fmt"

type Rect struct {
	Width  int
	Height int
}

func area(r Rect) int {
	return r.Width * r.Height
}

func main() {
	r := Rect{Width: 3, Height: 4}
	fmt.Println(area(r))
}
```

執行結果：

```text
12
```

這樣沒問題，但 `area` 只是一個普通函式，跟 `Rect` 沒有綁在一起。Go 讓我們把函式「掛」在型別上，變成這個型別的**方法**（method）。

### 定義方法

```go
package main

import "fmt"

type Rect struct {
	Width  int
	Height int
}

func (r Rect) Area() int {
	return r.Width * r.Height
}

func main() {
	r := Rect{Width: 3, Height: 4}
	fmt.Println(r.Area())
}
```

執行結果：

```text
12
```

和函式比起來，只差在 `func` 和名字中間多了一組小括號 `(r Rect)`。這組小括號叫做**接收者**（receiver），意思是「這個方法屬於 `Rect`，呼叫時那個 `Rect` 值叫做 `r`」。

呼叫時寫 `r.Area()`：點的左邊是值，右邊是方法名稱，跟讀欄位很像。方法裡的 `r` 就是點左邊的那個值。

接收者的名字慣例上取型別名稱的第一個字母小寫，例如 `Rect` 用 `r`、`Person` 用 `p`，不用 `this` 或 `self`。

### 方法可以有參數和多個回傳值

除了接收者，方法和函式寫法完全一樣：

```go
package main

import "fmt"

type Rect struct {
	Width  int
	Height int
}

func (r Rect) Area() int {
	return r.Width * r.Height
}

func (r Rect) Scaled(n int) (int, int) {
	return r.Width * n, r.Height * n
}

func main() {
	r := Rect{Width: 3, Height: 4}
	w, h := r.Scaled(2)
	fmt.Println(r.Area(), w, h)
}
```

執行結果：

```text
12 6 8
```

### 不只 struct 才能有方法

上一集的自訂型別也可以加方法：

```go
package main

import "fmt"

type Celsius float64

func (c Celsius) IsHot() bool {
	return c >= 30
}

func (c Celsius) ToFahrenheit() float64 {
	return float64(c*9/5 + 32)
}

func main() {
	today := Celsius(32)
	fmt.Println(today.IsHot(), today.ToFahrenheit())
}
```

執行結果：

```text
true 89.6
```

只要是自己用 `type` 定義的型別，都能加方法。但不能幫 `int`、`string` 這種內建型別直接加方法，也不能幫其他套件的型別加。想要的話，就先像 `Celsius` 一樣定義一個新型別。

同一個型別的方法不能重名，但不同型別可以各自有一個叫 `Area` 的方法，彼此不衝突。

## 重點整理

- 方法是有**接收者**的函式：`func (r Rect) Area() int { ... }`。
- 用 `值.方法(參數)` 呼叫，方法裡的接收者就是點左邊的那個值。
- 接收者名稱慣例用型別名稱的第一個字母小寫。
- 自己定義的型別（不只 struct）都能加方法；內建型別不能直接加。
