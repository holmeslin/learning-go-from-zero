# `iota`

## 本集目標

用 `iota` 幫一串常數自動編號 0、1、2……

## 正文

有時候我們需要一組「代號」，例如一週的每一天、紅綠燈的三種顏色。每個代號是什麼數字不重要，只要彼此不同就好。一個一個手動寫 0、1、2 很累，也容易寫錯，Go 提供了 `iota` 來幫忙。

### 自動編號

```go
package main

import "fmt"

const (
	Red = iota
	Yellow
	Green
)

func main() {
	fmt.Println(Red, Yellow, Green)
}
```

執行結果：

```text
0 1 2
```

`iota` 只能用在 `const` 裡。在一組 `const ( ... )` 中，`iota` 從第一行的 0 開始，每往下一行就加 1。

你可能注意到 `Yellow` 和 `Green` 後面什麼都沒寫。在 `const ( ... )` 裡，如果某一行沒寫 `= ...`，就會沿用上一行的寫法，也就是 `= iota`。所以這三行其實等於：

```go,ignore
Red = iota    // iota 是 0
Yellow = iota // iota 是 1
Green = iota  // iota 是 2
```

### 從 1 開始

如果想從 1 開始編號，可以在 `iota` 上加 1：

```go
package main

import "fmt"

const (
	Monday = iota + 1
	Tuesday
	Wednesday
)

func main() {
	fmt.Println(Monday, Tuesday, Wednesday)
}
```

執行結果：

```text
1 2 3
```

後面兩行一樣沿用 `= iota + 1`，所以分別是 1+1、2+1。

### 跳過某個號碼

不想要 0 這個號碼的話，也可以把第一行留給 `_`，讓它「佔個位子」就丟掉：

```go
package main

import "fmt"

const (
	_ = iota
	Small
	Medium
	Large
)

func main() {
	fmt.Println(Small, Medium, Large)
}
```

執行結果：

```text
1 2 3
```

`_` 是一個特別的名字，下一集會正式介紹。

### 每組 `const` 各自從 0 開始

`iota` 只在同一組 `const ( ... )` 裡累加，換一組就重新從 0 算：

```go
package main

import "fmt"

const (
	A = iota
	B
)

const (
	C = iota
	D
)

func main() {
	fmt.Println(A, B, C, D)
}
```

執行結果：

```text
0 1 0 1
```

## 重點整理

- `iota` 只能用在 `const` 裡，在一組 `const ( ... )` 中從 0 開始，每行加 1。
- `const ( ... )` 裡沒寫 `=` 的那一行，會沿用上一行的寫法。
- `iota + 1` 可以讓編號從 1 開始；第一行寫 `_ = iota` 可以跳過 0。
- 每一組新的 `const ( ... )`，`iota` 都重新從 0 開始。
