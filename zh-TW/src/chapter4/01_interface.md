# `interface`

## 本集目標

用 `interface` 描述「需要哪些方法」，寫出一個能接受多種型別的函式。

## 正文

假設我們有長方形和圓形兩種型別，都有算面積的 `Area` 方法。現在想寫一個函式，印出任何形狀的面積：

```go
package main

import "fmt"

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

func printRectArea(r Rect) {
	fmt.Println("面積是", r.Area())
}

func printCircleArea(c Circle) {
	fmt.Println("面積是", c.Area())
}

func main() {
	printRectArea(Rect{Width: 3, Height: 4})
	printCircleArea(Circle{Radius: 1})
}
```

執行結果：

```text
面積是 12
面積是 3.14
```

兩個函式長得幾乎一樣，只差在參數的型別。如果再多一個三角形，就要再寫一個。問題在於：參數只能寫一種型別。

但仔細想想，這個函式根本不在乎拿到的是長方形還是圓形，它只在乎「這個東西能不能呼叫 `Area()`」。

### 定義介面

**介面**（interface）就是用來描述「需要哪些方法」的型別：

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

func printArea(s Shape) {
	fmt.Println("面積是", s.Area())
}

func main() {
	printArea(Rect{Width: 3, Height: 4})
	printArea(Circle{Radius: 1})
}
```

執行結果：

```text
面積是 12
面積是 3.14
```

- `type Shape interface { Area() float64 }` 定義了一個介面型別 `Shape`。大括號裡列出方法的名稱、參數和回傳值，但**沒有**方法內容。
- 意思是：「只要有 `Area() float64` 這個方法，就算是 `Shape`。」
- `Rect` 和 `Circle` 都有這個方法，所以都能傳給 `printArea`。
- 在 `printArea` 裡，我們只能對 `s` 做介面裡寫到的事，也就是呼叫 `s.Area()`。

一個函式取代了兩個，以後多了三角形，只要三角形也有 `Area` 方法，`printArea` 一行都不用改。

### 介面型別的變數與切片

介面是一個型別，所以也能宣告變數、放進切片：

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
	shapes := []Shape{
		Rect{Width: 3, Height: 4},
		Circle{Radius: 2},
		Rect{Width: 1, Height: 1},
	}
	total := 0.0
	for _, s := range shapes {
		total += s.Area()
	}
	fmt.Printf("總面積 %.2f\n", total)
}
```

執行結果：

```text
總面積 25.56
```

`[]Shape` 裡可以混著放 `Rect` 和 `Circle`，迴圈裡不用管每個元素是什麼型別，一律呼叫 `Area()`。

介面裡可以列好幾個方法，一行一個。型別要**全部都有**才算符合。

## 重點整理

- 介面用 `type 名稱 interface { 方法(參數) 回傳值 }` 定義，只列方法，不寫內容。
- 擁有介面裡所有方法的型別，就能當成那個介面使用。
- 參數寫介面型別，函式就能接受多種型別；函式裡只能呼叫介面列出的方法。
- 介面型別也能用來宣告變數、組成切片。
