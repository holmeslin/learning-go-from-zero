# `iter.Seq2`

## 本集目標

用 `iter.Seq2[K, V]` 寫出一次交出兩個值的迭代器，搭配 `for k, v := range`。

## 正文

### 一次交出兩個值

走訪切片時，我們習慣寫 `for i, v := range s`，一次拿到索引和值；走訪 map 則是一次拿到鍵和值。自己寫的迭代器也能做到，只要讓 `yield` 收兩個參數：

```go,ignore
type Seq2[K, V any] func(yield func(K, V) bool)
```

這也是 `iter` 套件定義好的型別。K 和 V 只是名字，不一定要是「鍵」和「值」，任何兩個成對的東西都可以。

### 例子：幫每一行加上行號

```go
package main

import (
	"fmt"
	"iter"
)

func numbered(lines []string) iter.Seq2[int, string] {
	return func(yield func(int, string) bool) {
		for i, line := range lines {
			if !yield(i+1, line) {
				return
			}
		}
	}
}

func main() {
	todo := []string{"買牛奶", "寫作業", "倒垃圾"}
	for no, item := range numbered(todo) {
		fmt.Printf("%d. %s\n", no, item)
	}
}
```

執行結果：

```text
1. 買牛奶
2. 寫作業
3. 倒垃圾
```

`numbered` 每次呼叫 `yield(i+1, line)`，`for` 左邊的 `no` 和 `item` 就分別拿到這兩個值。行號從 1 開始，所以交出的是 `i+1`。

### 只要其中一個值

跟走訪切片一樣，不需要的值可以用 `_` 丟掉，或者只寫第一個：

```go
package main

import (
	"fmt"
	"iter"
)

func numbered(lines []string) iter.Seq2[int, string] {
	return func(yield func(int, string) bool) {
		for i, line := range lines {
			if !yield(i+1, line) {
				return
			}
		}
	}
}

func main() {
	todo := []string{"買牛奶", "寫作業"}
	for _, item := range numbered(todo) {
		fmt.Println(item)
	}
	for no := range numbered(todo) {
		fmt.Println(no)
	}
}
```

執行結果：

```text
買牛奶
寫作業
1
2
```

### 兩個值的型別可以不同

`iter.Seq2[int, string]` 的兩個值型別就不一樣。下面這個迭代器交出名字和對應的分數是否及格：

```go
package main

import (
	"fmt"
	"iter"
)

type Student struct {
	Name  string
	Score int
}

func passed(students []Student) iter.Seq2[string, bool] {
	return func(yield func(string, bool) bool) {
		for _, s := range students {
			if !yield(s.Name, s.Score >= 60) {
				return
			}
		}
	}
}

func main() {
	class := []Student{{"小明", 85}, {"小華", 52}}
	for name, ok := range passed(class) {
		fmt.Println(name, ok)
	}
}
```

執行結果：

```text
小明 true
小華 false
```

## 重點整理

- `iter.Seq2[K, V]` 就是 `func(yield func(K, V) bool)`，每次交出一對值。
- 用 `for k, v := range seq` 接收；不要的值可以用 `_`，也可以只寫第一個。
- 兩個值的型別可以不同，也不一定是「鍵和值」的關係。
