# struct literal 與零值

## 本集目標

用 struct literal 一行建立 struct，並知道沒給值的欄位會是零值。

## 正文

上一集我們先宣告變數，再一個一個設定欄位。其實可以一次寫完：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	p := Person{Name: "Andy", Age: 20}
	fmt.Printf("%+v\n", p)
}
```

執行結果：

```text
{Name:Andy Age:20}
```

`Person{Name: "Andy", Age: 20}` 叫做 **struct literal**：型別名稱後面接大括號，裡面用 `欄位: 值` 的形式填資料，欄位之間用逗號隔開。

### 沒寫到的欄位是零值

第 1 章學過，每個型別都有零值：`int` 是 `0`，`string` 是 `""`，`bool` 是 `false`。struct literal 裡沒寫到的欄位，就會是它的零值：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	a := Person{Name: "Andy"}
	b := Person{Age: 30}
	c := Person{}
	fmt.Printf("%+v\n", a)
	fmt.Printf("%+v\n", b)
	fmt.Printf("%+v\n", c)
}
```

執行結果：

```text
{Name:Andy Age:0}
{Name: Age:30}
{Name: Age:0}
```

`Person{}` 什麼都沒寫，所有欄位都是零值。這和上一集 `var p Person` 得到的結果一模一樣：**struct 的零值，就是每個欄位都是零值**。

欄位的順序可以隨意寫，`Person{Age: 20, Name: "Andy"}` 也可以。

### 不寫欄位名稱的寫法

也可以省略欄位名稱，只照順序寫值：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	p := Person{"Andy", 20}
	fmt.Printf("%+v\n", p)
}
```

執行結果：

```text
{Name:Andy Age:20}
```

這種寫法有兩個規矩：每個欄位**都要**給值，而且順序要和定義時一樣。

看起來比較短，但我們不推薦。以後如果有人在 `Person` 裡加了一個欄位，所有這樣寫的地方都會編譯失敗；而且讀程式的人得回頭去看定義，才知道 `"Andy"` 和 `20` 分別是什麼。寫欄位名稱比較清楚，也比較不怕改動。

### 多行的寫法

欄位多的時候，可以把 literal 拆成好幾行。注意**最後一個欄位後面也要加逗號**：

```go
package main

import "fmt"

type Book struct {
	Title  string
	Author string
	Pages  int
}

func main() {
	b := Book{
		Title:  "小王子",
		Author: "聖修伯里",
		Pages:  96,
	}
	fmt.Println(b.Title, b.Pages)
}
```

執行結果：

```text
小王子 96
```

如果最後的逗號漏掉，Go 會編譯失敗。這是因為 Go 會在行尾自動補上分號，少了逗號就會變成語法錯誤。規矩記起來就好：多行的 literal，每一行結尾都有逗號。

## 重點整理

- struct literal 的寫法是 `型別{欄位: 值, 欄位: 值}`，可以一次建立 struct。
- 沒寫到的欄位是零值；`型別{}` 就是整個 struct 的零值。
- 也能省略欄位名稱照順序寫，但必須給齊所有欄位，不推薦。
- 拆成多行時，最後一個欄位後面也要加逗號。
