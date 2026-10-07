# `byte` 與 `rune`

## 本集目標

認識代表「一個字元」的 `rune` 和代表「一個位元組」的 `byte`，以及單引號 `'a'` 的意思。

## 正文

字串是一整段文字。但有時候我們只想處理**一個字**，這時就會用到 `rune`。

### 電腦用數字記住每個字

電腦其實只認得數字。每個字都被編了一個號碼，例如 `A` 是 65、`a` 是 97、`好` 是 22909。這套全世界通用的編號叫做 **Unicode**。

在 Go 裡，用**單引號**包起來的一個字，就代表這個字的號碼：

```go
package main

import "fmt"

func main() {
	fmt.Println('A')
	fmt.Println('a')
	fmt.Println('好')
}
```

執行結果：

```text
65
97
22909
```

印出來的是數字，不是字！因為 `'A'` 的意思就是「`A` 的號碼」。

注意單引號和雙引號不一樣：`"A"` 是字串，`'A'` 是一個字的號碼。單引號裡只能放**一個**字，寫 `'AB'` 會編譯錯誤。

### `rune`：一個字的號碼

用來存這種號碼的型別叫做 `rune`。`'A'` 這種寫法，就是 `rune` 的值：

```go
package main

import "fmt"

func main() {
	letter := 'G'
	fmt.Println(letter)
	fmt.Println(string(letter))
}
```

執行結果：

```text
71
G
```

`letter := 'G'` 會讓 `letter` 的型別是 `rune`。想把它印成字而不是數字，用 `string(letter)` 把它轉成字串。

`rune` 其實就是 `int32` 的**別名**：兩個名字指的是同一個型別，可以混著用，不用轉換。寫成 `rune` 只是為了讓讀程式的人知道「這是一個字」。

```go
package main

import "fmt"

func main() {
	var r rune = 'a'
	var n int32 = r
	fmt.Println(n)
}
```

執行結果：

```text
97
```

### 字也能做加減

既然 `rune` 是數字，就可以拿來加減。英文字母的號碼是連續的，所以可以用迴圈印出一串字母：

```go
package main

import "fmt"

func main() {
	for r := 'a'; r <= 'e'; r++ {
		fmt.Println(string(r))
	}
}
```

執行結果：

```text
a
b
c
d
e
```

### `byte`：一個位元組

`byte` 是 `uint8` 的別名，範圍是 0 ～ 255。電腦儲存資料的最小單位叫做**位元組**（byte），`byte` 型別就是用來代表一個位元組。

```go
package main

import "fmt"

func main() {
	var b byte = 'A'
	fmt.Println(b)
}
```

執行結果：

```text
65
```

英文字母和數字的號碼都小於 256，放得進一個 `byte`。但中文字的號碼很大，放不進 `byte`：

```go,compile_fail
package main

import "fmt"

func main() {
	var b byte = '好'
	fmt.Println(b)
}
```

```text
./main.go:6:15: cannot use '好' (untyped rune constant 22909) as byte value in variable declaration (overflows)
```

所以處理「一個字」時要用 `rune`，它什麼字都放得下。`byte` 主要用在處理檔案、網路這類底層資料。字串和 `byte`、`rune` 之間的關係，第 2 章會再詳細介紹。

## 重點整理

- 每個字都有一個號碼（Unicode）；單引號 `'a'` 代表這個字的號碼，是 `rune` 型別的值。
- `rune` 是 `int32` 的別名，用來代表一個字；用 `string(r)` 可以轉成字串印出來。
- `byte` 是 `uint8` 的別名，代表一個位元組，範圍 0 ～ 255，放不下中文字。
- 單引號是一個字的號碼，雙引號是字串。
