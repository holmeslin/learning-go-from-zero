# 自訂型別

## 本集目標

用 `type 新名字 既有型別` 定義自己的型別，讓編譯器幫你擋掉「單位搞混」這類錯誤。

## 正文

`type Person struct { ... }` 其實是 `type` 的一種用法：用 struct 當底子，定義一個新型別。`type` 後面也可以接 `int`、`float64`、`string` 這些現成的型別。

### 定義溫度型別

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func main() {
	var c Celsius = 30
	f := Fahrenheit(86)
	fmt.Println(c, f)
	fmt.Printf("%T %T\n", c, f)
}
```

執行結果：

```text
30 86
main.Celsius main.Fahrenheit
```

- `type Celsius float64` 定義了一個新型別 `Celsius`（攝氏），它底下存的資料跟 `float64` 一樣，這叫做它的**底層型別**。
- `Fahrenheit(86)` 是型別轉換，第 1 章學過，寫法就是「型別名稱加小括號」。
- `%T` 印出型別名稱，前面的 `main.` 表示這個型別是在 `main` 套件定義的。

### 新型別是不同的型別

雖然 `Celsius` 和 `Fahrenheit` 底層都是 `float64`，但它們是**不同**的型別，不能直接混在一起算：

```go,compile_fail
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func main() {
	c := Celsius(30)
	f := Fahrenheit(86)
	fmt.Println(c + f)
}
```

編譯錯誤：

```text
invalid operation: c + f (mismatched types Celsius and Fahrenheit)
```

這正是我們要的效果！攝氏加華氏本來就沒有意義，Go 在編譯時就幫我們抓出來了。如果只用 `float64`，兩個數字加起來不會有任何警告，錯誤就會悄悄混進程式裡。

### 需要時明確轉換

真的要換算時，就寫一個函式，並用型別轉換把結果轉成正確的型別：

```go
package main

import "fmt"

type Celsius float64
type Fahrenheit float64

func toFahrenheit(c Celsius) Fahrenheit {
	return Fahrenheit(c*9/5 + 32)
}

func main() {
	c := Celsius(30)
	f := toFahrenheit(c)
	fmt.Println(f)
}
```

執行結果：

```text
86
```

`c*9/5 + 32` 的型別還是 `Celsius`：`Celsius` 可以和 `9`、`5`、`32` 這種直接寫出來的數字一起運算，結果也是 `Celsius`。最後用 `Fahrenheit(...)` 轉成華氏。

函式的參數寫 `Celsius`，如果有人不小心傳了 `Fahrenheit` 進去，一樣會編譯失敗。

### 自訂型別之後還能加方法

自訂型別最重要的用途，是可以幫它加上**方法**，讓 `Celsius` 自己就會做事。這是下一集的主題。

## 重點整理

- `type 新名字 既有型別` 定義新型別，既有型別叫做它的底層型別。
- 新型別和底層型別、以及其他底層型別相同的型別，都是不同的型別，不能直接混用。
- 需要時用 `型別(值)` 明確轉換。
- 用自訂型別表示「單位」或「意義」，讓編譯器幫忙擋錯誤。
