# `for range` 走訪字串

## 本集目標

用 `for range` 一個字一個字地走訪字串，並看懂它給的索引。

## 正文

### 用索引走訪：一個 byte 一個 byte

上一集知道字串是一串 byte。如果用三段式 `for` 配合 `s[i]` 走訪，拿到的就是一個個 byte：

```go
package main

import "fmt"

func main() {
	s := "Hi你"
	for i := 0; i < len(s); i++ {
		fmt.Println(i, s[i])
	}
}
```

執行結果：

```text
0 72
1 105
2 228
3 189
4 160
```

「你」被拆成了 228、189、160 三個 byte，這通常不是我們想要的。

### 用 `for range`：一個字一個字

對字串使用 `for range`，Go 會自動依照 UTF-8 解讀，每一圈給你**一個完整的字**（`rune`）：

```go
package main

import "fmt"

func main() {
	s := "Hi你好"
	for i, r := range s {
		fmt.Printf("%d %q\n", i, r)
	}
}
```

執行結果：

```text
0 'H'
1 'i'
2 '你'
5 '好'
```

- `r` 的型別是 `rune`，每一圈都是一個完整的字。用 `%q` 印 `rune`，會顯示成單引號包住的字。
- `i` 是這個字在字串裡**從第幾個 byte 開始**。「你」從 byte 2 開始，佔了 3 個 byte，所以下一個字「好」的索引直接跳到 5。

索引不連續是正常的，它是 byte 位置，不是第幾個字。

### 數字數、找字

只要字，不要索引的話，一樣用 `_`：

```go
package main

import "fmt"

func main() {
	s := "我愛 Go 語言"
	count := 0
	spaces := 0
	for _, r := range s {
		count++
		if r == ' ' {
			spaces++
		}
	}
	fmt.Println("字數", count, "空白", spaces)
	fmt.Println("byte 數", len(s))
}
```

執行結果：

```text
字數 8 空白 2
byte 數 16
```

`r == ' '` 拿 `rune` 和單引號的字元比較，這在第 1 章學 `rune` 時就看過了。

### 把字倒過來

結合 `rune` 和字串相加，可以把一句話倒過來：

```go
package main

import "fmt"

func main() {
	s := "你好 Go"
	reversed := ""
	for _, r := range s {
		reversed = string(r) + reversed
	}
	fmt.Println(reversed)
}
```

執行結果：

```text
oG 好你
```

每拿到一個字，就把它接在 `reversed` 的**前面**，最後整句話就反過來了。如果用 byte 來做，中文字的 3 個 byte 會被拆開倒放，結果就是亂碼。

## 重點整理

- 用 `s[i]` 走訪字串拿到的是 byte，中文字會被拆開。
- `for i, r := range s` 每一圈拿到一個完整的字 `r`（型別 `rune`）。
- `i` 是該字開始的 byte 位置，遇到多 byte 的字時索引會跳號。
- 處理含有中文的文字時，用 `for range` 以字為單位走訪。
