# `slices` 與 `maps` 套件

## 本集目標

認識標準函式庫 `slices` 和 `maps` 套件裡常用的泛型函式，不用再自己寫迴圈找元素、排序、比較。

## 正文

這一章我們自己寫了 `indexOf`、`largest` 等泛型函式。好消息是：這些常見的工作，標準函式庫已經寫好了，就放在 `slices` 和 `maps` 兩個套件裡。它們都是泛型函式，能處理多種型別，但各函式有自己的型別約束，不是任何切片和 map 都能套用每個函式。

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

- `slices.Clone(s)`：複製元素的值到新切片。上例的元素是整數，所以改 `b[0]` 不會改到 `a[0]`（第 2 章學過切片共用底層陣列的問題）。
- `slices.Equal(a, b)`：長度相同、每個元素用 `==` 比較都相等才是 `true`，所以元素型別必須滿足 `comparable`。上例的 `int` 可以，但 `[][]int` 的元素是 `[]int`，不能用這個函式比較。

`Clone` 做的是**淺複製**，不是一路複製內部資料的**深複製**。例如元素本身是切片時，複製的是內層切片的描述資料，兩邊仍共用內層的底層陣列；元素含有 map 或指標時，也可能共用它們指向的資料。

`Equal` 也不是通用的深比較工具。元素是指標時，比的是指標值，不會往下比較指向的內容。要比較切片這類不能用 `==` 比較的元素，可以用 `slices.EqualFunc`，自己提供比較兩個元素的函式。元素若是介面，還要留意第 10 集說過的限制：裡面裝了不可比較的動態值時，`==` 仍可能 panic。

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

- `maps.Clone(m)`：建立新 map，逐項複製 key 和 value 的值。它也是淺複製；若 value 是切片、map 或指標，仍可能共用底層資料。直接賦值 map 則連外層都是同一份資料。
- `maps.Equal(a, b)`：兩邊有相同的 key，而且每個 key 對應的 value 用 `==` 比較都相等，才是 `true`。key 和 value 的型別都必須滿足 `comparable`。上例的 `string`、`int` 可以，但 `map[string][]int` 的 value 是切片，不能用這個函式比較。
- `maps.DeleteFunc(m, f)`：刪掉所有讓 `f` 回傳 `true` 的項目。

`maps.Equal` 同樣不是通用的深比較。value 不能用 `==` 比較時，可以用 `maps.EqualFunc`，自己提供比較兩個 value 的函式；key 仍必須是 `comparable`。

`slices` 套件也有對應的 `slices.DeleteFunc`。這兩個套件還有很多其他函式，可以用 `go doc slices`、`go doc maps` 查看。其中有些會回傳「迭代器」，例如 `maps.Keys`，那要等第 7 章學了迭代器才會用。

## 重點整理

- `slices.Contains`、`slices.Index`、`slices.IndexFunc` 用來在切片裡搜尋。
- `slices.Sort`、`slices.Reverse` 直接修改切片；`slices.Max`、`slices.Min` 遇到空切片會 panic。
- `slices.Clone`、`maps.Clone` 都是淺複製，仍可能共用內層資料。
- `slices.Equal` 要求元素型別滿足 `comparable`；`maps.Equal` 要求 key 和 value 型別都滿足 `comparable`，兩者都不是通用深比較。
- `maps.DeleteFunc` 依條件刪除 map 項目；要自訂比較方式，可以用 `slices.EqualFunc` 或 `maps.EqualFunc`。
