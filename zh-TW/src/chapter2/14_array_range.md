# `for range` 走訪陣列

## 本集目標

用 `for range` 依序拿出陣列裡的每一個元素。

## 正文

要把陣列每個元素都處理一遍，可以用三段式 `for` 配合索引：

```go
package main

import "fmt"

func main() {
	scores := [4]int{90, 85, 77, 60}
	for i := 0; i < len(scores); i++ {
		fmt.Println(i, scores[i])
	}
}
```

執行結果：

```text
0 90
1 85
2 77
3 60
```

這樣可以，但要自己管 `i` 從哪開始、到哪結束，很容易寫錯成 `i <= len(scores)`。Go 提供了更方便的 `for range`。

### 同時拿到索引和值

第 1 章用過 `for i := range 5` 走訪整數，`range` 也可以用在陣列上：

```go
package main

import "fmt"

func main() {
	scores := [4]int{90, 85, 77, 60}
	for i, v := range scores {
		fmt.Println(i, v)
	}
}
```

執行結果：

```text
0 90
1 85
2 77
3 60
```

每一圈，`range` 會給我們**兩個值**：第一個是索引，第二個是那個位置的元素。這裡分別放進 `i` 和 `v`（名字可以自己取）。

### 只要值：用 `_`

很多時候我們不在乎索引，只要值，例如算總分。但如果寫了 `i` 卻沒用，會出現「宣告了卻沒用到」的錯誤。這時就輪到第 3 集的 `_` 出場：

```go
package main

import "fmt"

func main() {
	scores := [4]int{90, 85, 77, 60}
	total := 0
	for _, v := range scores {
		total += v
	}
	fmt.Println("總分", total)
	fmt.Printf("平均 %.2f\n", float64(total)/float64(len(scores)))
}
```

執行結果：

```text
總分 312
平均 78.00
```

### 只要索引

反過來，只要索引的話，第二個變數直接不寫就好：

```go
package main

import "fmt"

func main() {
	scores := [4]int{90, 85, 77, 60}
	for i := range scores {
		scores[i] += 5
	}
	fmt.Println(scores)
}
```

執行結果：

```text
[95 90 82 65]
```

注意這裡是用 `scores[i] += 5` 改陣列本身。如果寫成 `for _, v := range scores { v += 5 }`，改到的只是 `v` 這個複本，陣列不會變。`v` 每一圈拿到的都是元素的一份複本。

## 重點整理

- `for i, v := range 陣列`：每一圈拿到索引 `i` 和元素 `v`。
- 只要值時寫 `for _, v := range ...`；只要索引時寫 `for i := range ...`。
- `v` 是元素的複本，想修改陣列要用 `陣列[i] = ...`。
- `for range` 不用自己管邊界，比三段式 `for` 不容易寫錯。
