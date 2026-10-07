# 陣列基礎

## 本集目標

用陣列把「固定數量、同一種型別」的值放在一起，並用索引存取它們。

## 正文

假設要記住 5 位同學的成績，用變數的話得寫 `score1`、`score2`……`score5`，想算平均還得一個一個加。如果有 50 位同學呢？我們需要一個「能裝一排值」的東西，這就是**陣列**（array）。

### 宣告陣列

```go
package main

import "fmt"

func main() {
	var scores [5]int
	fmt.Println(scores)
}
```

執行結果：

```text
[0 0 0 0 0]
```

`[5]int` 讀作「5 個 `int` 的陣列」。陣列裡的每個值叫做**元素**，還沒放東西時，每個元素都是零值，所以印出來是五個 0。

也可以在宣告時直接放好值：

```go
package main

import "fmt"

func main() {
	scores := [5]int{90, 85, 77, 60, 98}
	fmt.Println(scores)
}
```

執行結果：

```text
[90 85 77 60 98]
```

### 用索引存取

每個元素都有一個編號，叫做**索引**（index），從 **0** 開始算。第一個元素是 `scores[0]`，第五個是 `scores[4]`：

```go
package main

import "fmt"

func main() {
	scores := [5]int{90, 85, 77, 60, 98}
	fmt.Println("第一位：", scores[0])
	fmt.Println("最後一位：", scores[4])

	scores[3] = 65
	fmt.Println(scores)
	fmt.Println("總共", len(scores), "位")
}
```

執行結果：

```text
第一位： 90
最後一位： 98
[90 85 77 65 98]
總共 5 位
```

- `scores[3] = 65` 把第四個元素改成 65。
- `len(scores)` 可以得到陣列的長度（元素個數）。`len` 是 Go 內建的函式，不用 `import`。

索引從 0 開始，所以長度 5 的陣列，最後一個索引是 4，也就是 `len(scores) - 1`。

### 超出範圍

用不存在的索引會怎樣？如果索引是寫死的數字，Go 在編譯時就會抓出來：

```go,compile_fail
package main

import "fmt"

func main() {
	scores := [5]int{90, 85, 77, 60, 98}
	fmt.Println(scores[5])
}
```

```text
invalid argument: index 5 out of bounds [0:5]
```

`[0:5]` 的意思是合法的索引從 0 開始、到 5 之前（不含 5）。如果索引是執行時才算出來的（例如使用者輸入），編譯器抓不到，程式執行到那裡會直接當掉（panic）。所以用索引前，要確定它小於 `len`。

### 長度是型別的一部分

陣列的長度一旦決定就不能改。而且 `[5]int` 和 `[3]int` 是**不同的型別**，不能互相賦值。這讓陣列用起來不太靈活：班上轉來一位新同學，`[5]int` 就裝不下了。

所以實際寫 Go 時，我們比較少直接用陣列，而是用第 15 集要學的**切片**。不過切片是建立在陣列上的，先認識陣列很重要。

## 重點整理

- `[5]int` 是長度 5、元素型別為 `int` 的陣列；沒給值的元素是零值。
- `[5]int{1, 2, 3, 4, 5}` 可以在宣告時給值。
- 用 `陣列[索引]` 讀寫元素，索引從 0 開始，最大是 `len - 1`。
- `len(陣列)` 取得長度；陣列長度固定，而且是型別的一部分。
