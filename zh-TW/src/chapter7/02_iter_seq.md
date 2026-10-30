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

### 能不能重複走訪，要看實作

迭代器是一個函式值，可以存進變數。本例的 `countdown` 每次走訪都會重新倒數，所以可以重複使用：

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

本例的倒數迴圈寫在回傳的匿名函式裡，建立 `seq` 時還沒開始倒數。每次 `range` 呼叫它，都會重新建立 `i`，從 `from` 開始交出值。這是 `countdown` 的實作方式，不是 `iter.Seq` 保證的行為；其他建構迭代器的函式也可能先檢查參數或準備資料。

有些迭代器只能把整個序列走完一次，稱為 **single-use iterator**。下面把 `i` 放在回傳的匿名函式外面，讓每次走訪共用同一個進度：

```go
package main

import (
	"fmt"
	"iter"
)

// once 回傳只能把序列走完一次的迭代器。
func once(n int) iter.Seq[int] {
	i := 1
	return func(yield func(int) bool) {
		for i <= n {
			v := i
			i++
			if !yield(v) {
				return
			}
		}
	}
}

func main() {
	seq := once(3)
	for v := range seq {
		fmt.Print(v, " ")
	}
	fmt.Println("完畢")
	count := 0
	for range seq {
		count++
	}
	fmt.Println("第二次交出值的個數：", count)
}
```

執行結果：

```text
1 2 3 完畢
第二次交出值的個數： 0
```

這也是合法的 `iter.Seq[int]`，但走完後再走訪，就不會交出任何值。若中途停止，本例會在下次走訪時接著交出剩下的值，而不是從頭開始。使用別人提供的迭代器時，要看它的文件怎麼說。

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
- 本集的 `countdown` 每次都從頭開始；其他 `iter.Seq` 能否重複走訪，要看實作與文件，single-use iterator 走完後不再交出值。
- 迭代器可以搭配泛型，寫出適用各種型別的版本。
