# 具名回傳值

## 本集目標

認識「具名回傳值」：幫回傳值取名字，讓函式的意思更清楚。

## 正文

看到 `func divide(a, b int) (int, int)`，你可能會想：這兩個 `int` 哪個是商、哪個是餘數？要讀完函式內容才知道。Go 允許我們幫回傳值取名字。

### 幫回傳值取名字

```go
package main

import "fmt"

func divide(a, b int) (quotient, remainder int) {
	quotient = a / b
	remainder = a % b
	return quotient, remainder
}

func main() {
	q, r := divide(17, 5)
	fmt.Println(q, r)
}
```

執行結果：

```text
3 2
```

`(quotient, remainder int)` 做了兩件事：

1. 光看函式的第一行，就知道第一個回傳值是商、第二個是餘數。
2. 在函式一開始，自動宣告了 `quotient` 和 `remainder` 這兩個變數，值是零值（`int` 的零值是 0）。所以函式裡可以直接用 `=` 賦值，不用 `:=`。

### 光寫 `return`

使用具名回傳值時，`return` 後面可以什麼都不寫，Go 會自動把那幾個具名變數目前的值交回去：

```go
package main

import "fmt"

func minMax(a, b int) (small, big int) {
	if a < b {
		small = a
		big = b
	} else {
		small = b
		big = a
	}
	return
}

func main() {
	s, b := minMax(8, 3)
	fmt.Println(s, b)
}
```

執行結果：

```text
3 8
```

這種只寫 `return` 的寫法叫做 naked return（光禿禿的 return）。在很短的函式裡還好，但函式一長，讀的人很難一眼看出到底回傳了什麼。**建議還是寫清楚 `return small, big`**，把具名回傳值主要當成「說明文件」來用。

### 什麼時候用？

- 回傳值有好幾個、而且型別相同、容易搞混時，取名字很有幫助。
- 只回傳一個值、意思很明顯時（例如 `func add(a, b int) int`），就不需要取名字。

## 重點整理

- 回傳值可以取名字，例如 `(quotient, remainder int)`，讓人一看就懂每個回傳值的意義。
- 具名回傳值在函式開始時就以零值宣告好，函式裡直接用 `=` 賦值。
- 具名回傳值可以只寫 `return`，但為了好讀，建議仍明確寫出要回傳的值。
