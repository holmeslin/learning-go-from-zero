# 型別別名與泛型別名

## 本集目標

分清楚 `type A = B`（型別別名）和 `type A B`（自訂型別）的差別，並認識 Go 1.24 起可以帶型別參數的泛型別名。

## 正文

### 多一個等號，意思完全不同

第 3 章學過自訂型別：

```go,ignore
type Celsius float64
```

這會做出一個**全新的型別** `Celsius`，它的底層是 `float64`，但和 `float64` 是不同的型別，不能直接混著運算。

如果在中間加一個等號：

```go,ignore
type Temp = float64
```

這叫做**型別別名**（type alias）。它沒有做出新型別，只是幫 `float64` 多取一個名字。`Temp` 和 `float64` 是**同一個型別**，可以完全互換：

```go
package main

import "fmt"

type Temp = float64

func main() {
	var t Temp = 36.5
	var f float64 = 0.5
	fmt.Println(t + f)
	fmt.Printf("%T\n", t)
}
```

執行結果：

```text
37
float64
```

`t + f` 可以直接相加，`%T` 印出來的型別也是 `float64`，因為對 Go 來說根本沒有「`Temp` 型別」這回事，`Temp` 只是 `float64` 的另一個名字。

換成自訂型別就不行了：

```go,compile_fail
package main

import "fmt"

type Celsius float64

func main() {
	var c Celsius = 36.5
	var f float64 = 0.5
	fmt.Println(c + f)
}
```

編譯錯誤：

```text
invalid operation: c + f (mismatched types Celsius and float64)
```

整理一下：

| 寫法 | 名稱 | 是新型別嗎？ | 可以和原型別混用嗎？ |
| --- | --- | --- | --- |
| `type Celsius float64` | 自訂型別 | 是 | 不行，要轉換 |
| `type Temp = float64` | 型別別名 | 不是 | 可以 |

### 你早就用過別名了

其實你從第 1 章就在用別名，只是沒發現：

- `byte` 是 `uint8` 的別名。
- `rune` 是 `int32` 的別名。
- `any` 是 `interface{}` 的別名（第 4 章）。

所以 `[]byte` 和 `[]uint8` 是同一個型別，`%T` 印 `byte` 會顯示 `uint8`。

### 別名用在哪裡

自訂型別用來表達「這是不一樣的東西」，讓編譯器幫你擋下混用；別名則刻意**不**擋。它主要的用途是：

- **搬家時保持相容**。大型專案要把某個型別從 `a` 套件搬到 `b` 套件，可以在舊位置留一行 `type Thing = b.Thing`，舊的程式碼不用一次全部改完。這是別名被加進 Go 的主要原因。
- **把很長的型別取個短名字**，例如 `type Handlers = map[string]func(int) error`，名字短了，型別還是同一個。

一般寫程式時，想表達新概念就用自訂型別；別名比較少用到。

### 泛型別名

Go 1.24 起，別名也可以有型別參數，叫做**泛型別名**：

```go
package main

import "fmt"

type Set[T comparable] = map[T]struct{}

func main() {
	seen := Set[string]{}
	for _, w := range []string{"go", "is", "go", "fun"} {
		seen[w] = struct{}{}
	}
	fmt.Println(len(seen))

	var m map[string]struct{} = seen
	fmt.Printf("%T\n", m)
}
```

執行結果：

```text
3
map[string]struct {}
```

- `Set[T comparable]` 和第 6 章的泛型型別寫法一樣，差別只在中間多了 `=`。
- `Set[string]` 就是 `map[string]struct{}` 本身，所以可以直接指定給 `map[string]struct{}` 型別的變數，`%T` 印出來也是 map 的原本樣子。
- `struct{}` 是不佔記憶體的空 struct，拿來當 map 的值，表示「只在乎 key 有沒有出現」。

如果改成 `type Set[T comparable] map[T]struct{}`（沒有等號），就是第 6 章的泛型自訂型別，可以替它加方法，但不能直接和 `map[string]struct{}` 混用。

## 重點整理

- `type A = B` 是型別別名：`A` 和 `B` 是同一個型別，可以互換；`type A B` 則是做出新的自訂型別。
- `byte`、`rune`、`any` 都是內建的別名。
- 別名主要用在搬移型別時保持相容，或幫很長的型別取短名字；想表達新概念時用自訂型別。
- Go 1.24 起可以寫泛型別名，例如 `type Set[T comparable] = map[T]struct{}`。
