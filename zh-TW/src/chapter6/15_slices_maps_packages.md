# `slices` 與 `maps` 套件

## 本集目標

認識標準函式庫 `slices` 和 `maps` 套件裡常用的泛型函式，不用再自己寫迴圈找元素、排序、比較。

## 正文

這一章我們自己寫了 `indexOf`、`largest` 等泛型函式。好消息是：這些常見的工作，標準函式庫已經寫好了，就放在 `slices` 和 `maps` 兩個套件裡。它們都是泛型函式，所以任何型別的切片和 map 都能用。

### 搜尋：`Contains` 與 `Index`

```go
package main

import (
	"fmt"
	"slices"
)

func main() {
	fruits := []string{"蘋果", "香蕉", "芒果"}

	fmt.Println(slices.Contains(fruits, "香蕉"))
	fmt.Println(slices.Contains(fruits, "西瓜"))

	fmt.Println(slices.Index(fruits, "芒果"))
	fmt.Println(slices.Index(fruits, "西瓜"))

	i := slices.IndexFunc(fruits, func(s string) bool {
		return len([]rune(s)) == 2 && s != "蘋果"
	})
	fmt.Println(i)
}
```

執行結果：

```text
true
false
2
-1
1
```

- `slices.Contains(s, v)`：切片裡有沒有 `v`。
- `slices.Index(s, v)`：`v` 第一次出現的位置，找不到回傳 -1。
- `slices.IndexFunc(s, f)`：第一個讓 `f` 回傳 `true` 的元素位置。

`Contains` 和 `Index` 需要用 `==` 比較，所以元素型別要是 `comparable`。

### 排序、最大最小、反轉

```go
package main

import (
	"fmt"
	"slices"
)

func main() {
	scores := []int{72, 95, 60, 88}

	fmt.Println(slices.Max(scores), slices.Min(scores))

	slices.Sort(scores)
	fmt.Println(scores)

	slices.Reverse(scores)
	fmt.Println(scores)

	words := []string{"pear", "apple", "fig"}
	slices.Sort(words)
	fmt.Println(words)
}
```

執行結果：

```text
95 60
[60 72 88 95]
[95 88 72 60]
[apple fig pear]
```

- `slices.Sort(s)`：由小到大排序，元素型別要是 `cmp.Ordered`。要自訂規則就用第 7 集的 `slices.SortFunc`。
- `slices.Max(s)`、`slices.Min(s)`：最大值和最小值。切片是空的會 panic，使用前要確定裡面有東西。
- `slices.Reverse(s)`：把順序反過來。

`Sort` 和 `Reverse` 都是直接修改原本的切片。

### 比較與複製

```go
package main

import (
	"fmt"
	"slices"
)

func main() {
	a := []int{1, 2, 3}
	b := slices.Clone(a)
	b[0] = 100

	fmt.Println(a, b)
	fmt.Println(slices.Equal(a, b))

	b[0] = 1
	fmt.Println(slices.Equal(a, b))
}
```

執行結果：

```text
[1 2 3] [100 2 3]
false
true
```

- `slices.Clone(s)`：複製出一個新切片，有自己的底層陣列，改它不會影響原本的（第 2 章學過切片共用底層陣列的問題）。
- `slices.Equal(a, b)`：長度相同、每個元素都相等才是 `true`。切片不能用 `==` 比較，所以要用它。

### `maps` 套件

```go
package main

import (
	"fmt"
	"maps"
)

func main() {
	stock := map[string]int{"蘋果": 3, "香蕉": 5}

	backup := maps.Clone(stock)
	stock["蘋果"] = 0

	fmt.Println(stock)
	fmt.Println(backup)
	fmt.Println(maps.Equal(stock, backup))

	stock["蘋果"] = 3
	fmt.Println(maps.Equal(stock, backup))

	maps.DeleteFunc(stock, func(k string, v int) bool {
		return v < 4
	})
	fmt.Println(stock)
}
```

執行結果：

```text
map[蘋果:0 香蕉:5]
map[蘋果:3 香蕉:5]
false
true
map[香蕉:5]
```

- `maps.Clone(m)`：複製一份 map。map 和切片一樣，直接賦值只是多一個名字指向同一份資料。
- `maps.Equal(a, b)`：key 和 value 完全一樣才是 `true`。map 也不能用 `==` 比較。
- `maps.DeleteFunc(m, f)`：刪掉所有讓 `f` 回傳 `true` 的項目。

`slices` 套件也有對應的 `slices.DeleteFunc`。這兩個套件還有很多其他函式，可以用 `go doc slices`、`go doc maps` 查看。其中有些會回傳「迭代器」，例如 `maps.Keys`，那要等第 7 章學了迭代器才會用。

## 重點整理

- `slices.Contains`、`slices.Index`、`slices.IndexFunc` 用來在切片裡搜尋。
- `slices.Sort`、`slices.Reverse` 直接修改切片；`slices.Max`、`slices.Min` 遇到空切片會 panic。
- `slices.Clone` 複製切片，`slices.Equal` 比較兩個切片的內容。
- `maps.Clone` 複製 map，`maps.Equal` 比較兩個 map，`maps.DeleteFunc` 依條件刪除。
