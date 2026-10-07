# type switch

## 本集目標

用 type switch 一次判斷介面裡裝的是哪一種型別，取代一連串的型別斷言。

## 正文

上一集的 `describe` 用了好幾個 `if` 加型別斷言。型別一多，就會變成一長串。第 1 章學過的 `switch` 有一個專門處理這件事的變化版：**type switch**。

### 基本寫法

```go
package main

import "fmt"

func describe(x any) {
	switch v := x.(type) {
	case int:
		fmt.Println("整數，兩倍是", v*2)
	case string:
		fmt.Println("字串，長度是", len(v))
	case bool:
		fmt.Println("布林值，反過來是", !v)
	default:
		fmt.Printf("不認識的型別 %T\n", v)
	}
}

func main() {
	describe(21)
	describe("Go")
	describe(true)
	describe(3.14)
}
```

執行結果：

```text
整數，兩倍是 42
字串，長度是 2
布林值，反過來是 false
不認識的型別 float64
```

- `x.(type)` 長得像型別斷言，但括號裡寫的是關鍵字 `type`。這種寫法**只能**出現在 `switch` 裡。
- 每個 `case` 後面寫的是型別，不是值。
- `v := ...` 的 `v` 很特別：在 `case int` 裡，`v` 的型別是 `int`；在 `case string` 裡，`v` 是 `string`。所以每個分支都能直接拿 `v` 做那個型別能做的事。
- `default` 處理其他所有型別，這時 `v` 的型別和 `x` 一樣，還是 `any`。

和一般的 `switch` 一樣，符合的 `case` 執行完就結束，不會往下掉。

### 一個 case 寫好幾個型別

`case` 後面可以用逗號列出好幾個型別：

```go
package main

import "fmt"

func kind(x any) string {
	switch x.(type) {
	case int, int64, float64:
		return "數字"
	case string:
		return "文字"
	case nil:
		return "什麼都沒有"
	default:
		return "其他"
	}
}

func main() {
	fmt.Println(kind(1))
	fmt.Println(kind(2.5))
	fmt.Println(kind("hi"))
	fmt.Println(kind(nil))
	fmt.Println(kind([]int{1}))
}
```

執行結果：

```text
數字
數字
文字
什麼都沒有
其他
```

這裡有兩個小細節：

- 不需要用到值的時候，可以省略 `v :=`，直接寫 `switch x.(type)`。
- `case nil` 會在介面本身是 `nil`（裡面什麼都沒裝）時符合。

如果一個 `case` 列了好幾個型別，那個分支裡的 `v` 沒辦法確定是哪一種，所以型別還是原本的 `any`。

### 也能判斷自己的型別和介面

`case` 後面可以是任何型別，包括自己定義的 struct 和介面：

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

type Point struct {
	X int
	Y int
}

func show(x any) {
	switch v := x.(type) {
	case Point:
		fmt.Println("座標", v.X, v.Y)
	case Shape:
		fmt.Println("形狀，面積", v.Area())
	default:
		fmt.Println("其他：", v)
	}
}

func main() {
	show(Point{X: 1, Y: 2})
	show(Rect{Width: 3, Height: 3})
	show("hi")
}
```

執行結果：

```text
座標 1 2
形狀，面積 9
其他： hi
```

`case Shape` 會讓所有實作了 `Shape` 的型別都進到這個分支。`case` 是由上往下檢查的，如果某個型別同時符合好幾個 `case`，只會執行第一個。

## 重點整理

- type switch 的寫法是 `switch v := x.(type) { case 型別: ... }`，`x.(type)` 只能用在 `switch` 裡。
- 只列一個型別的 `case` 裡，`v` 就是那個型別；`default` 或列多個型別的 `case` 裡，`v` 維持原本的介面型別。
- 不需要值時可以寫 `switch x.(type)`；`case nil` 用來處理介面是 `nil` 的情況。
- `case` 可以是自己的型別或介面，由上往下比對，只執行第一個符合的分支。
