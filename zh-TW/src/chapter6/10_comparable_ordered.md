# `comparable` 與 `cmp.Ordered`

## 本集目標

認識兩個最常用的現成約束：能用 `==` 比較的 `comparable`，和能用 `<` 比大小的 `cmp.Ordered`。

## 正文

上一集我們自己用 `|` 列出型別清單。但有兩種需求太常見了，Go 直接幫我們準備好現成的約束。

### `comparable`：可以用 `==`

寫一個「找出某個值在切片裡的位置」的函式，需要用 `==` 比較。用 `any` 當約束是不行的：

```go,compile_fail
package main

import "fmt"

func indexOf[T any](s []T, target T) int {
	for i, v := range s {
		if v == target {
			return i
		}
	}
	return -1
}

func main() {
	fmt.Println(indexOf([]int{3, 5, 7}, 5))
}
```

編譯錯誤：

```text
invalid operation: v == target (incomparable types in type set)
```

因為不是所有型別都能用 `==`，例如切片、map、函式就不行。

內建的 `comparable` 約束代表「所有能用 `==` 和 `!=` 比較的型別」：

```go
package main

import "fmt"

func indexOf[T comparable](s []T, target T) int {
	for i, v := range s {
		if v == target {
			return i
		}
	}
	return -1
}

type Point struct {
	X, Y int
}

func main() {
	fmt.Println(indexOf([]int{3, 5, 7}, 5))
	fmt.Println(indexOf([]string{"紅", "綠", "藍"}, "藍"))
	fmt.Println(indexOf([]Point{{1, 2}, {3, 4}}, Point{3, 4}))
	fmt.Println(indexOf([]string{"紅"}, "黑"))
}
```

執行結果：

```text
1
2
1
-1
```

數字、字串、指標都是 comparable；欄位全部可以比較的 struct 也是（第 3 章的 struct 比較）。

map 的 key 必須能用 `==` 比較，所以泛型函式裡要用 `T` 當 map 的 key 時，也要用 `comparable`：

```go
package main

import "fmt"

func countEach[T comparable](s []T) map[T]int {
	counts := make(map[T]int)
	for _, v := range s {
		counts[v]++
	}
	return counts
}

func main() {
	fmt.Println(countEach([]string{"貓", "狗", "貓", "貓"}))
	fmt.Println(countEach([]int{1, 2, 2}))
}
```

執行結果：

```text
map[狗:1 貓:3]
map[1:1 2:2]
```

`fmt.Println` 印 map 時會把 key 排序後再印，所以每次輸出都一樣。

### `cmp.Ordered`：可以比大小

`comparable` 只保證能判斷「相不相等」，不保證能比大小：

```go,compile_fail
package main

import "fmt"

func largest[T comparable](s []T) T {
	m := s[0]
	for _, v := range s {
		if v > m {
			m = v
		}
	}
	return m
}

func main() {
	fmt.Println(largest([]int{3, 9, 4}))
}
```

編譯錯誤：

```text
invalid operation: v > m (type parameter T cannot use operator >)
```

要用 `<`、`>` 比大小，就用 `cmp` 套件的 `cmp.Ordered`。它包含所有整數、浮點數和字串型別：

```go
package main

import (
	"cmp"
	"fmt"
)

func largest[T cmp.Ordered](s []T) T {
	m := s[0]
	for _, v := range s {
		if v > m {
			m = v
		}
	}
	return m
}

func main() {
	fmt.Println(largest([]int{3, 9, 4}))
	fmt.Println(largest([]float64{2.5, -1, 0.75}))
	fmt.Println(largest([]string{"banana", "apple", "cherry"}))
}
```

執行結果：

```text
9
2.5
cherry
```

第 7 集用過的 `cmp.Compare` 也是一個泛型函式，它的約束就是 `cmp.Ordered`，所以數字和字串都能比。

注意這個 `largest` 遇到空切片時，`s[0]` 會 panic。實際使用時要先檢查長度，或改成回傳 `error`。

### 怎麼選？

| 函式裡需要 | 約束 |
| --- | --- |
| 什麼運算都不用，只是搬來搬去 | `any` |
| `==`、`!=`，或當 map 的 key | `comparable` |
| `<`、`>`、`<=`、`>=` | `cmp.Ordered` |

挑最寬鬆、但夠用的那個，函式就能支援最多種型別。

## 重點整理

- `comparable` 是內建約束，代表能用 `==`、`!=` 比較的型別；要當 map key 也要用它。
- 切片、map、函式不是 comparable。
- `cmp.Ordered` 代表能用 `<`、`>` 比大小的型別：整數、浮點數、字串。
- 依函式裡需要的運算，選擇 `any`、`comparable` 或 `cmp.Ordered`。
