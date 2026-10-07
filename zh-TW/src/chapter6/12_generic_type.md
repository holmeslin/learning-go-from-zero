# 泛型型別

## 本集目標

宣告有型別參數的 struct（泛型型別），並為它寫方法。

## 正文

泛型不只能用在函式上，型別也可以有型別參數。最常見的例子是「容器」：裝東西的資料結構，裝的是什麼型別都一樣運作。

### 宣告泛型型別

做一個「堆疊」（stack）：像疊盤子，最後放上去的先拿出來。

```go
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func main() {
	var nums Stack[int]
	nums.items = append(nums.items, 1, 2)
	fmt.Println(nums.items)

	words := Stack[string]{items: []string{"go"}}
	fmt.Println(words.items)
}
```

執行結果：

```text
[1 2]
[go]
```

`type Stack[T any] struct { ... }` 宣告了一個有型別參數 `T` 的 struct。

和泛型函式不同的是，使用泛型型別時，**一定要**寫出型別參數，例如 `Stack[int]`、`Stack[string]`。只寫 `Stack` 是不完整的，Go 不知道裡面要裝什麼。`Stack[int]` 和 `Stack[string]` 是兩個不同的型別。

### 幫泛型型別寫方法

```go
package main

import "fmt"

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s *Stack[T]) Pop() (T, bool) {
	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	last := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return last, true
}

func (s Stack[T]) Len() int {
	return len(s.items)
}

func main() {
	var s Stack[string]
	s.Push("盤子 A")
	s.Push("盤子 B")
	s.Push("盤子 C")
	fmt.Println("數量：", s.Len())

	for s.Len() > 0 {
		v, _ := s.Pop()
		fmt.Println(v)
	}

	_, ok := s.Pop()
	fmt.Println("空了還能拿嗎？", ok)
}
```

執行結果：

```text
數量： 3
盤子 C
盤子 B
盤子 A
空了還能拿嗎？ false
```

幾個重點：

- 接收者要寫成 `Stack[T]` 或 `*Stack[T]`，把型別參數帶上。這裡的 `T` 就是 `Stack` 宣告時的那個 `T`，方法裡可以直接用。
- `Push` 和 `Pop` 會修改內容，所以用指標接收者（第 3 章）。
- `Pop` 遇到空堆疊時，要回傳一個 `T` 的值，但我們不知道 `T` 是什麼。`var zero T` 宣告一個 `T` 型別的變數，它的值就是 `T` 的零值，正好拿來回傳。

`var s Stack[string]` 不用初始化就能用，因為 `nil` 切片也能 `append`，這是第 3 章「讓零值有用」的例子。

### 多個型別參數

泛型型別也能有多個型別參數，約束也和函式一樣寫法：

```go
package main

import "fmt"

type Pair[K comparable, V any] struct {
	Key   K
	Value V
}

func (p Pair[K, V]) String() string {
	return fmt.Sprintf("%v=%v", p.Key, p.Value)
}

func main() {
	p1 := Pair[string, int]{Key: "年齡", Value: 18}
	p2 := Pair[int, bool]{Key: 7, Value: true}
	fmt.Println(p1)
	fmt.Println(p2)
}
```

執行結果：

```text
年齡=18
7=true
```

方法的接收者寫 `Pair[K, V]`，型別參數要全部列出，而且順序要和宣告時一樣。

## 重點整理

- 型別也能有型別參數，例如 `type Stack[T any] struct { ... }`。
- 使用泛型型別時要寫出型別參數，例如 `Stack[int]`；不同型別參數是不同的型別。
- 方法的接收者寫成 `Stack[T]` 或 `*Stack[T]`，方法裡可以使用 `T`。
- `var zero T` 可以拿到型別參數的零值。
