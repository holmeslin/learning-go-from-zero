# 字串與 UTF-8

## 本集目標

知道字串其實是一串不能修改的 byte，並理解為什麼中文字的 `len` 跟你想的不一樣。

## 正文

學完切片，我們回頭重新認識一個老朋友：字串。

### `len` 算的是 byte

```go
package main

import "fmt"

func main() {
	fmt.Println(len("Go"))
	fmt.Println(len("你好"))
}
```

執行結果：

```text
2
6
```

「你好」明明是兩個字，`len` 卻說是 6？因為 `len` 算的不是「字數」，而是 **byte 數**。

第 1 章介紹 `byte` 和 `rune` 時說過：文字用 Unicode 碼位表示。原始碼中直接寫下的 `"Go"`、`"你好"` 這類文字會以 **UTF-8** 編碼儲存；UTF-8 把每個碼位存成 1 到 4 個 byte：

- 英文字母、數字、常見英文符號：1 個 byte。
- 中文字：通常是 3 個 byte。

所以 Go 的字串，說穿了就是**一串 byte**。「Go」是 2 個 byte，「你好」是 3 + 3 = 6 個 byte。但字串可以包含任意 byte，不保證內容一定是有效的 UTF-8；例如從檔案讀來或切開的資料，也能放進字串。

### 用索引拿到的是 byte

既然字串是一串 byte，`s[i]` 拿到的就是第 `i` 個 **byte**，而不是第 `i` 個字：

```go
package main

import "fmt"

func main() {
	s := "Go你好"
	fmt.Println(s[0], s[1], s[2])
	fmt.Printf("%T\n", s[0])
}
```

執行結果：

```text
71 111 228
uint8
```

`s[0]` 是 `'G'` 的編碼 71，`s[1]` 是 `'o'` 的 111。`s[2]` 是「你」這個字三個 byte 中的第一個 228，單獨拿出來沒什麼意義。`%T` 顯示它的型別是 `uint8`，也就是 `byte`（`byte` 只是 `uint8` 的另一個名字）。

切片運算式也可以用在字串上，一樣是以 byte 為單位：`s[2:5]` 剛好是「你」的那 3 個 byte，結果是字串 `"你"`。如果切在一個碼位的 UTF-8 編碼中間，結果仍是合法的 Go 字串，但可能不是有效的 UTF-8，顯示時可能出現亂碼。

### 字串不能修改

字串一旦建立，裡面的 byte 就不能改：

```go,compile_fail
package main

import "fmt"

func main() {
	s := "hello"
	s[0] = 'H'
	fmt.Println(s)
}
```

```text
cannot assign to s[0] (neither addressable nor a map index expression)
```

想要不同的內容，就做出一個新字串，例如用 `+` 接起來：`s = "H" + s[1:]`。這不是改了原本的字串，而是讓 `s` 換成一個新的字串。

### 想算 rune 數：轉成 `[]rune`

如果需要以 Unicode 碼位為單位處理 UTF-8 文字，可以把字串轉成 `[]rune`，也就是一個 `rune` 的切片，每個元素代表一個碼位：

```go
package main

import "fmt"

func main() {
	s := "Go你好"
	runes := []rune(s)
	fmt.Println(len(runes))
	fmt.Println(string(runes[2]))

	runes[2] = '妳'
	fmt.Println(string(runes))
}
```

執行結果：

```text
4
你
Go妳好
```

- `len([]rune(s))` 算的是 rune 數，這裡是 4。
- `runes[2]` 是第三個碼位，代表「你」；用 `string(...)` 轉回字串才印得出字，不然會印出它的編碼數字。
- `[]rune` 是切片，可以修改。改完再用 `string(runes)` 轉回字串。

rune 數不一定等於畫面上的可見字元數。例如 `"é"` 是字母 `e` 加上組合重音，看起來像一個重音字，卻有 2 個 rune；旗幟 emoji `"🇹🇼"` 也有 2 個 rune。這裡不處理把多個碼位合成一個可見字元的計數。

同樣地，`[]byte(s)` 可以把字串轉成 byte 切片，`string(bytes)` 再轉回來。

## 重點整理

- Go 的字串是一串不可修改的 byte，可以放任意 byte，不保證是有效的 UTF-8；本集的中文文字以 UTF-8 編碼，一個常見中文字通常佔 3 個 byte。
- `len(s)` 算的是 byte 數，`s[i]` 拿到的是一個 `byte`，不是一個字。
- 字串不能用 `s[i] = ...` 修改，要改內容就產生新字串。
- `[]rune(s)` 按 UTF-8 解碼成 rune 切片，`len([]rune(s))` 算的是 rune 數，不是可見字元數；`string(...)` 可以轉回字串。
