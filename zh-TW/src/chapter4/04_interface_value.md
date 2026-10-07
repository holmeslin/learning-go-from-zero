# 介面值

## 本集目標

理解介面變數裡裝了兩樣東西：動態型別和動態值，並知道介面的零值是 `nil`。

## 正文

一個 `Shape` 變數可以裝 `Rect`，也可以裝 `Circle`。那它怎麼知道呼叫 `Area()` 時，要執行哪一個型別的方法？

### 介面值 =（型別, 值）

介面變數裡其實存了兩樣東西：

- **動態型別**：目前裝進來的值是什麼型別，例如 `Rect`。
- **動態值**：那個值本身，例如 `{3 4}`。

叫「動態」是因為它們會隨著你放進去的東西改變。`fmt.Printf` 的 `%T` 和 `%v` 正好可以把這兩樣印出來：

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

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 {
	return 3.14 * c.Radius * c.Radius
}

func main() {
	var s Shape
	s = Rect{Width: 3, Height: 4}
	fmt.Printf("%T %v %v\n", s, s, s.Area())

	s = Circle{Radius: 1}
	fmt.Printf("%T %v %v\n", s, s, s.Area())
}
```

執行結果：

```text
main.Rect {3 4} 12
main.Circle {1} 3.14
```

同一個變數 `s`，第一次的動態型別是 `Rect`，第二次換成了 `Circle`。呼叫 `s.Area()` 時，Go 會看目前的動態型別，去執行那個型別的 `Area` 方法。

變數 `s` 本身的型別一直都是 `Shape`，這個不會變。會變的只有裡面裝的東西。

### 放進去的是複本

把一個值放進介面，介面裡存的是那個值的**複本**：

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
	r := Rect{Width: 3, Height: 4}
	var s Shape = r
	r.Width = 100
	fmt.Println(r.Area(), s.Area())
}
```

執行結果：

```text
400 12
```

之後再改 `r`，介面裡的那份不受影響。這也是上一集「指標接收者的方法要放指標進介面」的原因。如果放進去的是指標，動態值就是那個位址，透過介面改到的會是原本的資料。

### 介面的零值是 `nil`

宣告了介面變數卻沒放任何東西，動態型別和動態值都是空的。這就是介面的零值 `nil`：

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

func main() {
	var s Shape
	fmt.Printf("%T %v\n", s, s)
	fmt.Println(s == nil)
}
```

執行結果：

```text
<nil> <nil>
true
```

**只有當型別和值兩格都是空的，介面才等於 `nil`。** 這句話先記著，第 11 集會看到一個因為它而產生的陷阱。

對 `nil` 介面呼叫方法，跟對 `nil` 指標解參考一樣會 panic。介面可能是 `nil` 時，先用 `s == nil` 檢查。

## 重點整理

- 介面值裡存了兩樣東西：動態型別和動態值；`%T`、`%v` 可以分別印出來。
- 呼叫介面的方法時，Go 依照目前的動態型別決定執行哪個方法。
- 放進介面的是值的複本；放指標的話，動態值就是那個位址。
- 介面的零值是 `nil`，此時動態型別和動態值都是空的；對 `nil` 介面呼叫方法會 panic。
