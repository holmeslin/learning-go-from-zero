# 巢狀欄位的 struct literal

## 本集目標

使用 Go 1.27 的新寫法：在 struct literal 裡直接填提升上來的欄位，不用再包一層嵌入型別。

## 正文

上一集我們可以用 `d.Name` 直接讀寫 `Animal` 裡的 `Name`。但建立 `Dog` 時，卻還是得寫成 `Animal: Animal{Name: ...}`，有點不一致。

### Go 1.27 起可以直接寫

從 Go 1.27 開始，struct literal 裡也能直接用提升上來的欄位名稱：

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
	d := Dog{Name: "Lucky", Legs: 4, Breed: "柴犬"}
	fmt.Printf("%+v\n", d)
}
```

執行結果：

```text
{Animal:{Name:Lucky Legs:4} Breed:柴犬}
```

`Name` 和 `Legs` 是 `Animal` 的欄位，但因為 `d.Name`、`d.Legs` 是合法的寫法，所以 literal 裡也可以直接寫 `Name:`、`Legs:`。印出來的結果和以前的寫法 `Dog{Animal: Animal{Name: "Lucky", Legs: 4}, Breed: "柴犬"}` 一模一樣，只是寫起來比較短。

沒寫到的欄位一樣是零值。例如 `Dog{Name: "Lucky"}` 的 `Legs` 是 `0`、`Breed` 是 `""`。

### 好幾層也可以

嵌入了好幾層也沒關係，只要用 `.欄位` 能一步拿到，literal 裡就能直接寫：

```go
package main

import "fmt"

type Base struct {
	ID int
}

type Animal struct {
	Base
	Name string
}

type Dog struct {
	Animal
	Breed string
}

func main() {
	d := Dog{ID: 7, Name: "Lucky", Breed: "柴犬"}
	fmt.Println(d.ID, d.Name, d.Breed)
	fmt.Printf("%+v\n", d)
}
```

執行結果：

```text
7 Lucky 柴犬
{Animal:{Base:{ID:7} Name:Lucky} Breed:柴犬}
```

`ID` 在 `Dog` 裡面的 `Animal` 裡面的 `Base` 裡面，但 `d.ID` 可以直接拿到，所以 `ID: 7` 也能直接寫。

### 三個限制

這個新寫法有幾個規矩，不符合的話會編譯失敗。

**第一，不能同時寫嵌入欄位本身和它裡面的欄位。** 下面同時寫了 `Animal:` 和 `Name:`，Go 不知道該聽哪一個：

```go,compile_fail
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
	d := Dog{Animal: Animal{Legs: 4}, Name: "Lucky"}
	fmt.Println(d)
}
```

編譯錯誤：

```text
cannot specify promoted field Name and enclosing embedded field Animal
```

兩種寫法擇一：要嘛全部包在 `Animal: Animal{...}` 裡，要嘛全部攤開寫。

**第二，key 只能寫欄位名稱，不能寫成一串路徑。** 例如 `Animal.Name: "Lucky"` 是不行的，編譯器會說 `invalid field name Animal.Name in struct literal`。

**第三，有歧義的名稱不能用。** 上一集提過，如果 `Dog` 同時嵌入兩個都有 `Name` 的型別，`d.Name` 會編譯失敗。literal 裡也一樣，寫 `Name:` 會得到 `unknown field Name in struct literal of type Dog`，這時只能用 `Animal: Animal{...}` 的寫法。

### 需要 Go 1.27

這是 Go 1.27 才加入的寫法。是否能用，看的是 `go.mod` 裡的 `go` 版本：如果寫的是 `go 1.26` 或更舊，就算你裝的是 Go 1.27，編譯器也會把 `Name:` 當成 `Dog` 沒有的欄位，回報 `unknown field Name in struct literal of type Dog`。本書的範例都是 `go 1.27`，可以放心使用。

如果你在網路上看到別人一律寫 `Animal: Animal{...}`，那是因為以前只能這樣寫，兩種寫法的結果完全相同。

## 重點整理

- 從 Go 1.27 起，struct literal 可以直接寫提升上來的欄位，例如 `Dog{Name: "Lucky", Breed: "柴犬"}`。
- 嵌入好幾層也可以，只要 `d.欄位` 能直接存取就行。
- 不能同時寫嵌入欄位本身（`Animal:`）和它裡面的欄位（`Name:`）；key 也不能寫成 `Animal.Name` 這種路徑。
- 有歧義的欄位名稱不能這樣寫；`go.mod` 的 `go` 版本要是 1.27 以上。
