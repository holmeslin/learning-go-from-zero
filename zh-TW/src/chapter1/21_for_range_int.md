# `for range` 整數

## 本集目標

用 `for i := range n` 更簡潔地重複 n 次。

## 正文

上一集說過，重複 5 次的常見寫法是：

```go,ignore
for i := 0; i < 5; i++ {
	...
}
```

這實在太常用了，所以 Go（1.22 版以後）提供了更短的寫法。

### `for i := range 5`

```go
package main

import "fmt"

func main() {
	for i := range 5 {
		fmt.Println(i)
	}
}
```

執行結果：

```text
0
1
2
3
4
```

`for i := range 5` 會讓 `i` 依序是 0、1、2、3、4，總共跑 5 次。效果跟 `for i := 0; i < 5; i++` 完全一樣，但不用自己寫條件和 `i++`，比較不容易寫錯。

`range` 後面也可以放變數：

```go
package main

import "fmt"

func main() {
	n := 3
	for i := range n {
		fmt.Println("第", i+1, "位")
	}
}
```

執行結果：

```text
第 1 位
第 2 位
第 3 位
```

`i` 從 0 開始，想顯示從 1 開始的編號時，印出 `i+1` 就好。

### 用不到 `i` 的時候

如果只是想重複做幾次，根本用不到 `i`，可以連 `i :=` 都省略：

```go
package main

import "fmt"

func main() {
	for range 3 {
		fmt.Println("加油！")
	}
}
```

執行結果：

```text
加油！
加油！
加油！
```

記得第 13 集說的，建立了變數卻沒用到會無法編譯。用不到 `i` 時就寫 `for range 3`。

### 該用哪一種？

- 從 0 開始數，一次加 1：用 `for i := range n`。
- 從別的數字開始、倒著數、一次加好幾個：用三段式 `for`。
- 不知道要跑幾次，只知道什麼時候該停：用 `for 條件` 或 `for` + `break`。

`range` 還能用來走訪很多其他東西，第 2 章會陸續介紹。

## 重點整理

- `for i := range n` 讓 `i` 從 0 跑到 n-1，共 n 次（Go 1.22 起）。
- 用不到 `i` 時寫 `for range n`。
- 從 0 開始、每次加 1 的迴圈用 `range` 最簡潔；其他情況用三段式或條件迴圈。
