# `fmt.Stringer`

## 本集目標

幫自己的型別加上 `String()` 方法，實作標準庫的 `fmt.Stringer` 介面，讓 `fmt.Println` 用你想要的格式印出它。

## 正文

用 `fmt.Println` 印 struct，只會得到 `{Andy 20}` 這種格式。能不能讓它印成我們想要的樣子？可以，而且只要加一個方法。

### `fmt.Stringer` 介面

`fmt` 套件裡定義了這樣一個介面：

```go,ignore
type Stringer interface {
	String() string
}
```

`fmt.Println`、`fmt.Printf` 的 `%v`、`%s` 在印一個值之前，會先檢查它有沒有實作 `fmt.Stringer`（用的就是第 6 集的型別斷言）。有的話，就呼叫它的 `String()`，印出回傳的字串。

### 實作 `String()`

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func (p Person) String() string {
	return fmt.Sprintf("%s（%d 歲）", p.Name, p.Age)
}

func main() {
	p := Person{Name: "Andy", Age: 20}
	fmt.Println(p)
	fmt.Printf("我是 %v，朋友是 %s\n", p, Person{Name: "Betty", Age: 25})
}
```

執行結果：

```text
Andy（20 歲）
我是 Andy（20 歲），朋友是 Betty（25 歲）
```

`fmt.Sprintf` 的用法跟 `fmt.Printf` 一模一樣，差別只在它不會印出來，而是把排好的結果當成字串回傳。

我們沒有寫「`Person` 實作了 `fmt.Stringer`」，只是剛好有一個 `String() string` 方法。這就是第 2 集的隱式實作：`fmt` 套件和 `Person` 互不認識，卻能合作。

### 印切片時也有效

放在切片、struct 欄位裡的值，`fmt` 一樣會用它們的 `String()`：

```go
package main

import "fmt"

type Celsius float64

func (c Celsius) String() string {
	return fmt.Sprintf("%.1f°C", float64(c))
}

func main() {
	temps := []Celsius{23.5, 30, 18.25}
	fmt.Println(temps)
	fmt.Println(temps[0])
}
```

執行結果：

```text
[23.5°C 30.0°C 18.2°C]
23.5°C
```

`String()` 裡把 `c` 轉成 `float64` 再交給 `Sprintf`，是為了明確地「印數字」。千萬不要在 `String()` 裡用 `%v` 或 `%s` 印接收者自己：`fmt` 會再呼叫一次 `String()`，然後又一次……永遠不會結束。

### 用 iota 常數的好夥伴

第 2 章學過用 `iota` 定義一組常數。配上 `String()`，印出來就不再只是數字：

```go
package main

import "fmt"

type Weekday int

const (
	Sunday Weekday = iota
	Monday
	Tuesday
)

func (d Weekday) String() string {
	switch d {
	case Sunday:
		return "星期日"
	case Monday:
		return "星期一"
	case Tuesday:
		return "星期二"
	}
	return "未知"
}

func main() {
	day := Monday
	fmt.Println(day)
	fmt.Printf("%v %d\n", Tuesday, Tuesday)
}
```

執行結果：

```text
星期一
星期二 2
```

`%v` 會用 `String()`，`%d` 則照樣印出底層的整數。

## 重點整理

- `fmt.Stringer` 是只有一個方法 `String() string` 的介面。
- 型別有 `String()` 方法，`fmt.Println`、`%v`、`%s` 就會用它的回傳值來印。
- `fmt.Sprintf` 和 `fmt.Printf` 用法相同，但回傳字串而不是印出來。
- 在 `String()` 裡不要用 `%v`、`%s` 印接收者自己，否則會無限呼叫自己。
