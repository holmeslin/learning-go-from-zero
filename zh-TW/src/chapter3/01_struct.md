# `struct`

## 本集目標

用 `struct` 把好幾個相關的資料綁成一個新的型別，並學會讀寫裡面的欄位。

## 正文

假設我們要記錄一個人的名字和年齡。用目前學過的東西，大概會這樣寫：

```go
package main

import "fmt"

func main() {
	name := "Andy"
	age := 20
	fmt.Println(name, age)
}
```

執行結果：

```text
Andy 20
```

一個人還好，但如果有三個人，就要 `name1`、`age1`、`name2`、`age2`……變數越來越多，也很容易把 A 的名字配到 B 的年齡。我們真正想要的是：把「名字」和「年齡」綁在一起，當成**一個東西**。

### 定義一個 struct

`struct`（結構）就是做這件事的：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	var p Person
	p.Name = "Andy"
	p.Age = 20
	fmt.Println(p)
}
```

執行結果：

```text
{Andy 20}
```

一行一行來看：

- `type Person struct { ... }` 定義了一個新的型別，名字叫 `Person`。這段寫在 `func main()` 外面。
- 大括號裡每一行是一個**欄位**（field）：欄位名稱在前，型別在後。`Person` 有 `Name` 和 `Age` 兩個欄位。
- `var p Person` 宣告一個 `Person` 型別的變數 `p`，用法就跟 `var x int` 一樣。
- `p.Name` 用一個點 `.` 來取出 `p` 裡面的 `Name` 欄位，可以讀也可以寫。

`fmt.Println` 印 struct 時，會用大括號把所有欄位的值依序包起來。

### 讀取欄位

欄位就像一般的變數，可以拿來計算、比較、傳給函式：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	var p Person
	p.Name = "Andy"
	p.Age = 20
	p.Age++
	if p.Age >= 18 {
		fmt.Println(p.Name, "已經成年了，今年", p.Age, "歲")
	}
}
```

執行結果：

```text
Andy 已經成年了，今年 21 歲
```

### 用 `%+v` 連欄位名稱一起印

欄位一多，`{Andy 20}` 就看不出哪個值是哪個欄位。第 2 章學過的 `fmt.Printf` 有個 `%+v`，會把欄位名稱一起印出來：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	var p Person
	p.Name = "Andy"
	p.Age = 20
	fmt.Printf("%v\n", p)
	fmt.Printf("%+v\n", p)
}
```

執行結果：

```text
{Andy 20}
{Name:Andy Age:20}
```

除錯時用 `%+v` 會清楚很多。

### struct 可以放進切片

`Person` 是一個型別，所以第 2 章學過的切片、map 都能裝它：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	var people []Person
	var p Person
	p.Name = "Andy"
	p.Age = 20
	people = append(people, p)
	p.Name = "Betty"
	p.Age = 25
	people = append(people, p)
	for _, person := range people {
		fmt.Println(person.Name, person.Age)
	}
}
```

執行結果：

```text
Andy 20
Betty 25
```

一個一個欄位設定有點囉嗦，下一集我們會學更簡潔的寫法。

## 重點整理

- `type 名稱 struct { 欄位 型別 ... }` 定義一個新的 struct 型別，寫在函式外面。
- struct 由多個**欄位**組成，用 `變數.欄位` 讀寫。
- `fmt.Println` 印出 `{值1 值2}`；`fmt.Printf` 的 `%+v` 會連欄位名稱一起印。
- struct 型別和 `int`、`string` 一樣，可以放進切片和 map。
