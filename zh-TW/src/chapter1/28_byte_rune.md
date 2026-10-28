# `byte` 與 `rune`

## 本集目標

認識用來代表 Unicode 碼位的 `rune` 和代表「一個位元組」的 `byte`，以及單引號 `'a'` 的意思。

## 正文

字串可以放一整段文字。但有時候我們只想處理文字裡的一個編號，這時就會用到 `rune`。

### 電腦用數字記住文字

電腦其實只認得數字。Unicode 替文字裡的字母、漢字、符號等編號，例如 `A` 是 65、`a` 是 97、`好` 是 22909。這些編號叫做 **Unicode 碼位**。

一般英文字母和常見中文字通常各用一個碼位；但畫面上看起來的一個字元不一定只有一個碼位。有些重音字會用「字母 + 組合重音」，有些 emoji 也會用多個碼位組成。

在 Go 裡，用**單引號**包起來的一個碼位，就代表它的號碼：

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

注意單引號和雙引號不一樣：`"A"` 是字串，`'A'` 代表 `A` 的碼位。單引號裡只能放**一個碼位**，不是任意一個看起來完整的圖案；寫 `'AB'` 會編譯錯誤。

### `rune`：用來代表 Unicode 碼位

用來存這種號碼的型別叫做 `rune`。`'A'` 這種寫法，可以用來建立 `rune` 變數：

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

`rune` 其實就是 `int32` 的**別名**：兩個名字指的是同一個型別，可以混著用，不用轉換。寫成 `rune` 是為了讓讀程式的人知道「這個數字用來代表 Unicode 碼位」。

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

`byte` 是 `uint8` 的別名，範圍是 0 ～ 255。**8 個位元（bit）組成 1 個位元組（byte）**；每個位元可以是 0 或 1。位元組是處理檔案與文字資料常用的單位，`byte` 型別就是用來代表一個位元組。

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

所以處理一個 Unicode 碼位時可以用 `rune`，它放得下所有有效的碼位，但一個可見字元可能需要多個 `rune`。`byte` 主要用在處理檔案、網路這類底層資料。字串和 `byte`、`rune` 之間的關係，第 2 章會再詳細介紹。

## 重點整理

- Unicode 碼位是文字的編號；單引號 `'a'` 代表 `a` 的碼位，可以用來建立 `rune` 變數。
- `rune` 是 `int32` 的別名，用來代表 Unicode 碼位；用 `string(r)` 可以轉成字串印出來。組合字與 emoji 可能需要多個 `rune`。
- `byte` 是 `uint8` 的別名，範圍 0 ～ 255；1 個位元組是 8 個位元，放不下 `'好'` 這個碼位的數字。
- 單引號只能放一個碼位，雙引號是字串。
