# 嵌入

## 本集目標

用「嵌入」把一個 struct 放進另一個 struct 裡，並知道被嵌入的欄位叫什麼名字。

## 正文

假設我們有一個 `Animal`，記錄名字和腳的數量。現在想定義 `Dog`，除了 `Animal` 的資料之外，還要多記錄品種。

### 先用一般欄位試試

最直接的方法是讓 `Dog` 有一個型別是 `Animal` 的欄位：

```go
package main

import "fmt"

type Animal struct {
	Name string
	Legs int
}

type Dog struct {
	Info  Animal
	Breed string
}

func main() {
	d := Dog{
		Info:  Animal{Name: "Lucky", Legs: 4},
		Breed: "柴犬",
	}
	fmt.Println(d.Info.Name, d.Breed)
}
```

執行結果：

```text
Lucky 柴犬
```

這完全沒問題。struct 的欄位可以是任何型別，當然也可以是另一個 struct。存取時一層一層用點往下走：`d.Info.Name`。

### 嵌入：只寫型別，不寫欄位名稱

Go 有另一種寫法：在 struct 裡**只寫型別名稱**，不寫欄位名稱。這叫做**嵌入**（embedding）：

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
	fmt.Printf("%+v\n", d)
	fmt.Println(d.Animal.Name, d.Breed)
}
```

執行結果：

```text
{Animal:{Name:Lucky Legs:4} Breed:柴犬}
Lucky 柴犬
```

`Dog` 裡的 `Animal` 這一行，叫做**嵌入欄位**。它仍然是一個欄位，只是沒有另外取名字。那它叫什麼？**嵌入欄位的名字就是型別名稱**。所以：

- 在 literal 裡寫 `Animal: Animal{...}`，前面的 `Animal` 是欄位名稱，後面的是型別。
- 存取時寫 `d.Animal.Name`。
- `%+v` 印出來也看得到 `Animal:{...}` 這個欄位。

### 嵌入欄位也可以整個替換

既然它是一個欄位，就能整個讀出來、整個換掉：

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
	var d Dog
	d.Breed = "柴犬"
	d.Animal = Animal{Name: "Lucky", Legs: 4}

	a := d.Animal
	fmt.Println(a.Name, a.Legs)
}
```

執行結果：

```text
Lucky 4
```

`var d Dog` 的零值裡，`Animal` 欄位也是零值，也就是 `Animal{}`。

### 一個 struct 可以嵌入好幾個

```go
package main

import "fmt"

type Animal struct {
	Name string
}

type Owner struct {
	OwnerName string
}

type Dog struct {
	Animal
	Owner
	Breed string
}

func main() {
	d := Dog{
		Animal: Animal{Name: "Lucky"},
		Owner:  Owner{OwnerName: "Andy"},
		Breed:  "柴犬",
	}
	fmt.Println(d.Animal.Name, d.Owner.OwnerName)
}
```

執行結果：

```text
Lucky Andy
```

看到這裡，嵌入好像只是少寫一個欄位名稱而已。它真正方便的地方是：可以省掉中間那一層 `.Animal`，直接寫 `d.Name`。這是下一集的主題。

## 重點整理

- 在 struct 裡只寫型別名稱、不寫欄位名稱，叫做嵌入。
- 嵌入欄位仍然是一個欄位，它的名字就是型別名稱，例如 `d.Animal`。
- literal 裡用 `Animal: Animal{...}` 設定嵌入欄位。
- 一個 struct 可以嵌入多個型別。
