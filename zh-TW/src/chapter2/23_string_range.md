# `for range` 走訪字串

## 本集目標

用 `for range` 以 Unicode 碼位（`rune`）為單位走訪字串，並看懂它給的索引。

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

### 用 `for range`：一個 rune 一個 rune

對字串使用 `for range`，Go 會自動依照 UTF-8 解讀，每一圈給你**一個 Unicode 碼位**（`rune`），不一定是一個完整的可見字元：

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

- `r` 的型別是 `rune`，代表這一圈解讀出的碼位。用 `%q` 印 `rune`，會顯示成單引號包住的字元，必要時會用跳脫寫法。
- `i` 是這個碼位在字串裡**從第幾個 byte 開始**。「你」從 byte 2 開始，佔了 3 個 byte，所以下一個碼位「好」的索引直接跳到 5。

索引不連續是正常的，它是 byte 位置，不是第幾個 rune。遇到無效的 UTF-8 編碼時，這一圈會得到替代字元 `�`（U+FFFD），接著往下一個 byte 繼續解讀；原字串不會因此被修改。

### 數 rune、找指定碼位

只要 rune，不要索引的話，一樣用 `_`。這個範例輸出的「字數」指的是 rune 數，空白也算一個 rune：

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

### 按 rune 把文字倒過來

結合 `rune` 和字串相加，可以把一段文字的碼位順序倒過來：

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

每拿到一個 rune，就把它接在 `reversed` 的**前面**，最後碼位順序就反過來了。如果用 byte 來做，中文字的 3 個 byte 會被拆開倒放，破壞 UTF-8 編碼。

這個方法按 rune 反轉，不保證保留完整的可見字元。例如 `"é"` 的組合重音會跑到 `e` 前面，旗幟 emoji 的兩個碼位也會交換順序。這裡只練習碼位反轉，不處理組合字形。

## 重點整理

- 用 `s[i]` 走訪字串拿到的是 byte，中文字會被拆開。
- `for i, r := range s` 按 UTF-8 解碼，每一圈拿到一個碼位 `r`（型別 `rune`）；無效編碼會以替代字元表示，前進一個 byte。
- `i` 是該碼位開始的 byte 位置，遇到多 byte 的碼位時索引會跳號。
- rune 計數與反轉都是以碼位為單位，不保證把組合字或 emoji 當成一個完整的可見字元。
