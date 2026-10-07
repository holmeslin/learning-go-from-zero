# `iter.Pull`

## 本集目標

用 `iter.Pull` 把迭代器改成「需要時才拿下一個值」的形式，並記得用 `defer stop()` 收尾。

## 正文

### 推和拉

到目前為止，迭代器都是「推」的：迭代器主動把值一個一個推進 `for` 迴圈。大部分時候這樣最方便。

但有些情況需要「拉」：由我們決定什麼時候拿下一個值。最典型的例子是同時走訪**兩個**迭代器，一次各拿一個來比較。`for range` 一次只能走訪一個迭代器，這時就需要 `iter.Pull`。

### 基本用法

```go
package main

import (
	"fmt"
	"iter"
	"slices"
)

func main() {
	seq := slices.Values([]string{"甲", "乙"})

	next, stop := iter.Pull(seq)
	defer stop()

	v, ok := next()
	fmt.Println(v, ok)
	v, ok = next()
	fmt.Println(v, ok)
	v, ok = next()
	fmt.Printf("%q %v\n", v, ok)
}
```

執行結果：

```text
甲 true
乙 true
"" false
```

`iter.Pull(seq)` 回傳兩個函式：

- `next()`：拿下一個值。回傳值和 `ok`，用法就像第 2 章的 comma-ok。沒有值可拿時，`ok` 是 `false`，值是零值。
- `stop()`：告訴迭代器「我不要了」，讓它收尾。

### 一定要 `defer stop()`

`iter.Pull` 在背後讓迭代器暫停在 `yield` 那一行，等你下一次呼叫 `next`。如果你沒拿完就離開，迭代器會一直停在那裡，佔著資源。呼叫 `stop()` 會讓那次 `yield` 回傳 `false`，迭代器就能 `return`，它裡面的 `defer` 也會執行。

所以拿到 `next, stop` 之後，下一行就寫 `defer stop()`，這樣不管函式從哪裡 `return` 都不會忘記。已經拿完的情況下呼叫 `stop()` 也沒關係，多呼叫幾次都安全。

### 例子：一對一配對

下面的 `zip` 同時從兩個迭代器各拿一個值，配成一對交出，其中一邊拿完就停：

```go
package main

import (
	"fmt"
	"iter"
	"slices"
)

func zip[A, B any](as iter.Seq[A], bs iter.Seq[B]) iter.Seq2[A, B] {
	return func(yield func(A, B) bool) {
		nextB, stop := iter.Pull(bs)
		defer stop()
		for a := range as {
			b, ok := nextB()
			if !ok {
				return
			}
			if !yield(a, b) {
				return
			}
		}
	}
}

func main() {
	names := []string{"小明", "小華", "小美"}
	seats := []int{12, 7}

	for name, seat := range zip(slices.Values(names), slices.Values(seats)) {
		fmt.Println(name, "坐", seat, "號")
	}
}
```

執行結果：

```text
小明 坐 12 號
小華 坐 7 號
```

`as` 照常用 `for range` 走訪（推），`bs` 則用 `iter.Pull` 改成需要時才拿（拉）。座位只有兩個，第三次 `nextB()` 回傳 `ok` 為 `false`，我們就 `return`；`defer stop()` 確保 `bs` 那邊也正確收尾。

`iter` 套件還有 `iter.Pull2`，用在 `iter.Seq2` 上，`next()` 一次回傳兩個值加上 `ok`，用法相同。

### 什麼時候用

`iter.Pull` 比 `for range` 麻煩，也稍微慢一點。能用 `for range` 解決的就用 `for range`；只有像「同時走訪兩個迭代器」這種 `for range` 做不到的事，才拿出 `iter.Pull`。

## 重點整理

- `iter.Pull(seq)` 回傳 `next` 和 `stop`，把「推」的迭代器改成「拉」的形式。
- `next()` 回傳值和 `ok`；沒有值時 `ok` 為 `false`。
- 拿到 `next, stop` 後立刻寫 `defer stop()`，讓迭代器能正確收尾。
- 只有 `for range` 做不到時（例如同時走訪兩個迭代器）才使用 `iter.Pull`；`iter.Seq2` 則用 `iter.Pull2`。
