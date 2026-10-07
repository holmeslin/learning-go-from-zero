# `else`

## 本集目標

用 `else` 寫出「條件不成立時」要做的事。

## 正文

`if` 讓我們在條件成立時做某件事。但很多時候我們想要的是二選一：成立就做 A，不成立就做 B。

### `if` ... `else`

```go
package main

import "fmt"

func main() {
	score := 45
	if score >= 60 {
		fmt.Println("及格")
	} else {
		fmt.Println("不及格")
	}
}
```

執行結果：

```text
不及格
```

`score` 是 45，`score >= 60` 是 `false`，所以跳過 `if` 的大括號，改成執行 `else` 的大括號。

把 `score` 改成 80 再跑一次，就會印出「及格」。不管條件是什麼，這兩段**一定會執行其中一段，而且只會執行一段**。

### `else` 的位置

`else` 必須寫在 `if` 的右大括號 `}` 同一行，寫成 `} else {`。如果把 `else` 換到下一行：

```go,compile_fail
package main

import "fmt"

func main() {
	score := 45
	if score >= 60 {
		fmt.Println("及格")
	}
	else {
		fmt.Println("不及格")
	}
}
```

Go 會拒絕編譯：

```text
./main.go:10:2: syntax error: unexpected keyword else, expected }
```

跟 `if` 的 `{` 要在同一行一樣，這也是 Go「只有一種寫法」的規矩。

### 判斷奇數偶數

結合第 5 集的 `%`，可以判斷一個數是奇數還是偶數：

```go
package main

import "fmt"

func main() {
	n := 7
	if n%2 == 0 {
		fmt.Println(n, "是偶數")
	} else {
		fmt.Println(n, "是奇數")
	}
}
```

執行結果：

```text
7 是奇數
```

除以 2 的餘數是 0 就是偶數，否則就是奇數。

## 重點整理

- `if` 條件成立執行 `if` 的大括號，不成立就執行 `else` 的大括號，兩段一定只會執行一段。
- `else` 要寫在右大括號同一行：`} else {`。
