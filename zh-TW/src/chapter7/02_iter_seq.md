# `iter.Seq`

## 本集目標

用標準庫的 `iter.Seq[V]` 幫迭代器的型別取個好讀的名字，並寫出「回傳迭代器的函式」。

## 正文

### 型別太長了

上一集的 `squares` 只能交出 1 到 5 的平方。如果想讓呼叫的人決定要到多少，就得多一個參數 `n`。但迭代器的形狀是固定的，只能有 `yield` 一個參數，`n` 要放哪裡？

答案是：寫一個函式，**回傳**一個迭代器。

```go,ignore
func squaresUpTo(n int) func(yield func(int) bool) {
	...
}
```

可以動，但 `func(yield func(int) bool)` 這一長串實在不好讀。

### `iter.Seq`

標準庫的 `iter` 套件幫這個形狀取了名字：

```go,ignore
type Seq[V any] func(yield func(V) bool)
```

這是第 6 章學過的泛型型別。`iter.Seq[int]` 就是「會交出 `int` 的迭代器」，和 `func(yield func(int) bool)` 完全一樣，只是好讀多了。Seq 是 sequence（序列）的縮寫。

用它改寫：

```go
package main

import (
	"fmt"
	"iter"
)

func squaresUpTo(n int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := 1; i <= n; i++ {
			if !yield(i * i) {
				return
			}
		}
	}
}

func main() {
	for v := range squaresUpTo(4) {
		fmt.Println(v)
	}
}
```

執行結果：

```text
1
4
9
16
```

`squaresUpTo` 回傳一個匿名函式，這個匿名函式記住了外面的 `n`，這就是第 6 章的閉包。注意 `range` 後面這次有小括號：我們先**呼叫** `squaresUpTo(4)` 拿到迭代器，再把迭代器交給 `range`。

### 迭代器可以重複使用

迭代器只是一個函式值，可以存進變數，也可以走訪很多次：

```go
package main

import (
	"fmt"
	"iter"
)

func countdown(from int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := from; i >= 1; i-- {
			if !yield(i) {
				return
			}
		}
	}
}

func main() {
	seq := countdown(3)
	for n := range seq {
		fmt.Print(n, " ")
	}
	fmt.Println("發射！")
	for n := range seq {
		fmt.Print(n, " ")
	}
	fmt.Println("再發射一次！")
}
```

執行結果：

```text
3 2 1 發射！
3 2 1 再發射一次！
```

建立 `seq` 的時候什麼都還沒算。每次 `range` 呼叫它，才從頭開始一個一個交出值。

### 迭代器也可以是泛型

`iter.Seq` 本身是泛型，所以我們也能寫出適用各種型別的迭代器。下面的 `repeat` 把同一個值交出 `n` 次：

```go
package main

import (
	"fmt"
	"iter"
)

func repeat[V any](v V, n int) iter.Seq[V] {
	return func(yield func(V) bool) {
		for range n {
			if !yield(v) {
				return
			}
		}
	}
}

func main() {
	for s := range repeat("哈", 3) {
		fmt.Print(s)
	}
	fmt.Println()
}
```

執行結果：

```text
哈哈哈
```

## 重點整理

- `iter.Seq[V]` 就是 `func(yield func(V) bool)`，是「交出 `V` 的迭代器」的型別名字。
- 需要參數的迭代器，寫成「回傳 `iter.Seq[V]` 的函式」，裡面用閉包記住參數。
- 建立迭代器時不會執行，每次 `range` 才從頭開始交出值，所以可以重複走訪。
- 迭代器可以搭配泛型，寫出適用各種型別的版本。
