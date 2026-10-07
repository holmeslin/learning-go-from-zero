# `any`

## 本集目標

認識空介面 `interface{}` 和它的別名 `any`：任何型別的值都能放進去，但拿出來用之前得先知道它是什麼型別。

## 正文

介面列出的方法越少，能符合它的型別就越多。那如果一個方法都不列呢？

### 空介面

`interface{}` 是一個沒有任何方法的介面，叫做**空介面**。因為沒有要求任何方法，所以**每一個型別**都符合它：

```go
package main

import "fmt"

type Point struct {
	X int
	Y int
}

func main() {
	var x interface{}
	x = 42
	fmt.Printf("%T %v\n", x, x)
	x = "hello"
	fmt.Printf("%T %v\n", x, x)
	x = Point{X: 1, Y: 2}
	fmt.Printf("%T %v\n", x, x)
}
```

執行結果：

```text
int 42
string hello
main.Point {1 2}
```

整數、字串、自己定義的 struct，全都能放進同一個變數。上一集學的「動態型別」在這裡看得很清楚。

### `any` 就是 `interface{}`

`interface{}` 寫起來有點長，所以 Go 內建了一個別名 `any`。它在標準庫裡是這樣定義的：

```go,ignore
type any = interface{}
```

注意中間多了一個 `=`。第 3 章的 `type Celsius float64` 會建立一個**新的**型別；加上 `=` 則不會，它只是幫既有的型別取另一個名字，叫做**型別別名**。所以 `any` 和 `interface{}` 是同一個型別，寫哪一個都一樣，現在的 Go 程式大多寫 `any`。

```go
package main

import "fmt"

func main() {
	items := []any{1, "two", 3.0, true}
	for _, item := range items {
		fmt.Printf("%T %v\n", item, item)
	}
}
```

執行結果：

```text
int 1
string two
float64 3
bool true
```

`[]any` 是「什麼都能放」的切片。其實你一直在用 `any`：`fmt.Println` 的參數型別就是 `any`（而且可以一次傳好幾個，第 6 章會介紹），所以它才能印出各種型別。

### 放得進去，但拿出來不能直接用

`any` 什麼都能裝，代價是：你不能直接對它做任何特定型別的操作。

```go,compile_fail
package main

import "fmt"

func main() {
	var x any = 10
	fmt.Println(x + 1)
}
```

編譯錯誤：

```text
invalid operation: x + 1 (mismatched types any and untyped int)
```

我們知道 `x` 裡裝的是 `10`，但編譯器只知道 `x` 是 `any`，它不能保證裡面一定是數字，所以拒絕做加法。空介面沒有任何方法，能對它做的事情非常少：印出來、跟別的值比較、再放進另一個 `any`。

想用裡面的值，就得先把它「取出來」並確認型別。下一集的**型別斷言**就是做這件事的。

### 能不用就不用

`any` 很方便，但它等於放棄了編譯器的型別檢查。如果一個函式的參數寫 `any`，呼叫的人傳什麼都能編譯，錯誤要等到執行時才會發現。

所以：能用具體型別或有方法的介面，就不要用 `any`。真正需要「什麼型別都可以」的情況（像 `fmt.Println`）其實不多。

## 重點整理

- 空介面 `interface{}` 沒有任何方法，所以任何型別都實作了它。
- `any` 是 `interface{}` 的型別別名（`type any = interface{}`），兩者完全相同。
- `type A = B` 是別名，不會建立新型別；`type A B` 才會建立新型別。
- `any` 裡的值不能直接當成原本的型別使用，要先用型別斷言取出；能不用 `any` 就不要用。
