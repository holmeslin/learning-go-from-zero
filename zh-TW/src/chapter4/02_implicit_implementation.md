# 隱式實作

## 本集目標

知道 Go 的型別不用宣告「我實作了某個介面」，只要方法對了就自動符合；並學會在編譯時確認某個型別符合介面。

## 正文

上一集的 `Rect` 有一個 `Area` 方法，它就能當成 `Shape` 使用。但你有沒有發現，我們從頭到尾都沒寫過「`Rect` 是一種 `Shape`」這種話？

### 不用宣告，方法對了就算

在 Go 裡，型別擁有介面要求的所有方法，就叫做**實作**（implement）了這個介面。不需要任何關鍵字，也不需要事先講好，這叫做**隱式實作**。

好處是：介面和型別可以由不同的人、在不同的時間寫。下面的 `Celsius` 和 `Dog` 互不相識，寫的時候也不知道有 `Describer` 這個介面，但它們都剛好有 `Describe() string` 方法：

```go
package main

import "fmt"

type Celsius float64

func (c Celsius) Describe() string {
	if c >= 30 {
		return "很熱"
	}
	return "還好"
}

type Dog struct {
	Name string
}

func (d Dog) Describe() string {
	return "一隻叫 " + d.Name + " 的狗"
}

type Describer interface {
	Describe() string
}

func show(d Describer) {
	fmt.Println(d.Describe())
}

func main() {
	show(Celsius(33))
	show(Dog{Name: "Lucky"})
}
```

執行結果：

```text
很熱
一隻叫 Lucky 的狗
```

`Describer` 是最後才寫的，`Celsius` 和 `Dog` 一行都沒改，就能傳給 `show`。

### 一個型別可以實作好幾個介面

同樣的道理，一個型別只要方法夠多，就能同時符合好幾個介面：

```go
package main

import "fmt"

type Namer interface {
	GetName() string
}

type Speaker interface {
	Speak() string
}

type Dog struct {
	Name string
}

func (d Dog) GetName() string {
	return d.Name
}

func (d Dog) Speak() string {
	return "汪汪"
}

func main() {
	d := Dog{Name: "Lucky"}
	var n Namer = d
	var s Speaker = d
	fmt.Println(n.GetName(), s.Speak())
}
```

執行結果：

```text
Lucky 汪汪
```

`Dog` 同時是 `Namer` 也是 `Speaker`。

### 少了方法會怎樣？

如果型別缺了介面要求的方法，把它當成介面使用時，Go 會在編譯時就擋下來：

```go,compile_fail
package main

import "fmt"

type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rect struct {
	Width  float64
	Height float64
}

func (r Rect) Area() float64 {
	return r.Width * r.Height
}

func main() {
	var s Shape = Rect{Width: 3, Height: 4}
	fmt.Println(s.Area())
}
```

編譯錯誤：

```text
cannot use Rect{…} (value of struct type Rect) as Shape value in variable declaration: Rect does not implement Shape (missing method Perimeter)
```

錯誤訊息直接告訴你缺了 `Perimeter`。

### 在編譯時確認

有時候我們寫了一個型別，想確定它符合某個介面，但程式裡暫時還沒有地方用到。這時可以加上這一行：

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

var _ Shape = Rect{}

func main() {
	fmt.Println("編譯通過")
}
```

執行結果：

```text
編譯通過
```

`var _ Shape = Rect{}` 宣告一個 `Shape` 型別的變數，把 `Rect{}` 放進去，然後用第 2 章學過的底線 `_` 把它丟掉。這行什麼事都不做，唯一的作用是：如果 `Rect` 不符合 `Shape`，編譯就會失敗。很多 Go 程式碼都會看到這種寫法。

## 重點整理

- 型別擁有介面的所有方法，就自動實作了這個介面，不需要任何宣告，這叫隱式實作。
- 介面可以在型別之後才寫，一個型別也可以同時實作多個介面。
- 缺少方法時，編譯錯誤會指出缺了哪一個方法。
- `var _ 介面 = 型別{}` 可以在編譯時確認型別符合介面。
