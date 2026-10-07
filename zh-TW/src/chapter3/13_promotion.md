# 欄位提升與方法提升

## 本集目標

知道嵌入型別的欄位和方法會被「提升」到外層，可以直接用 `d.Name`、`d.Speak()` 存取，並了解遇到同名時的規則。

## 正文

上一集我們用 `d.Animal.Name` 一層一層往下拿名字。其實可以直接寫 `d.Name`。

### 欄位提升

```go
package main

import "fmt"

type Animal struct {
	Name string
	Legs int
}

type Dog struct {
	Animal
	Breed string
}

func main() {
	d := Dog{
		Animal: Animal{Name: "Lucky", Legs: 4},
		Breed:  "柴犬",
	}
	fmt.Println(d.Name, d.Legs, d.Breed)
	d.Name = "Max"
	fmt.Println(d.Animal.Name)
}
```

執行結果：

```text
Lucky 4 柴犬
Max
```

`Dog` 本身沒有 `Name` 欄位，但它嵌入的 `Animal` 有。Go 會把嵌入型別的欄位**提升**（promote）到外層，所以 `d.Name` 就等於 `d.Animal.Name`。兩種寫法指的是同一個欄位，改了其中一個，另一個也跟著變。

### 方法提升

方法也會被提升：

```go
package main

import "fmt"

type Animal struct {
	Name string
}

func (a Animal) Hello() {
	fmt.Println("我是", a.Name)
}

func (a *Animal) Rename(name string) {
	a.Name = name
}

type Dog struct {
	Animal
	Breed string
}

func main() {
	d := Dog{Animal: Animal{Name: "Lucky"}, Breed: "柴犬"}
	d.Hello()
	d.Rename("Max")
	d.Hello()
}
```

執行結果：

```text
我是 Lucky
我是 Max
```

`d.Hello()` 會變成 `d.Animal.Hello()`，`d.Rename("Max")` 會變成 `(&d.Animal).Rename("Max")`，第 10 集學過的自動取址在這裡一樣有效。

注意方法裡的接收者是 `Animal`，不是 `Dog`。`Hello` 看不到 `Breed`，它只知道自己是一個 `Animal`。

### 外層的同名欄位或方法優先

如果 `Dog` 自己也定義了同名的東西，外層的優先：

```go
package main

import "fmt"

type Animal struct {
	Name string
}

func (a Animal) Hello() {
	fmt.Println("我是", a.Name)
}

type Dog struct {
	Animal
	Breed string
}

func (d Dog) Hello() {
	fmt.Printf("汪！我是 %s，品種是 %s\n", d.Name, d.Breed)
}

func main() {
	d := Dog{Animal: Animal{Name: "Lucky"}, Breed: "柴犬"}
	d.Hello()
	d.Animal.Hello()
}
```

執行結果：

```text
汪！我是 Lucky，品種是 柴犬
我是 Lucky
```

`d.Hello()` 用的是 `Dog` 自己的方法。內層的方法並沒有消失，用 `d.Animal.Hello()` 還是叫得到。

如果同一層有兩個嵌入型別都有 `Name`，例如 `Dog` 同時嵌入 `Animal` 和 `Owner`，兩者都有 `Name`，Go 不知道你要哪一個，寫 `d.Name` 會編譯失敗，訊息是 `ambiguous selector d.Name`。這時就要寫完整：`d.Animal.Name` 或 `d.Owner.Name`。

### 嵌入不是繼承

你可能聽說過其他語言的「繼承」：狗是一種動物，所以需要動物的地方都可以放狗。Go 的嵌入**不是**這樣。`Dog` 只是「裡面有一個 `Animal`」，它本身不是 `Animal`：

```go,compile_fail
package main

import "fmt"

type Animal struct {
	Name string
}

func describe(a Animal) {
	fmt.Println(a.Name)
}

type Dog struct {
	Animal
	Breed string
}

func main() {
	d := Dog{Animal: Animal{Name: "Lucky"}}
	describe(d)
}
```

編譯錯誤：

```text
cannot use d (variable of struct type Dog) as Animal value in argument to describe
```

要傳的話，就明確地把裡面那個 `Animal` 拿出來：`describe(d.Animal)`。

「需要某種能力的地方，可以放好幾種不同的型別」這件事，Go 是用下一章的**介面**來做的。

## 重點整理

- 嵌入型別的欄位和方法會提升到外層：`d.Name` 等於 `d.Animal.Name`，`d.Hello()` 等於 `d.Animal.Hello()`。
- 提升上來的方法，接收者仍然是內層的型別。
- 外層有同名的欄位或方法時，外層優先；同一層有兩個同名的則會編譯失敗，要寫完整路徑。
- 嵌入不是繼承：`Dog` 不能當成 `Animal` 使用。
