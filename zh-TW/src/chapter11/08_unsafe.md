# `unsafe`

## 本集目標

認識 `unsafe` 套件：用 `Sizeof`、`Alignof`、`Offsetof` 觀察值在記憶體裡的大小和排列，看懂 `unsafe.String`、`unsafe.StringData`、`unsafe.Slice` 在做什麼，並記住它為什麼危險、為什麼要少用。

## 正文

### 名字就是警告

Go 的型別系統一直在保護我們：字串不能被修改、切片不會讀到範圍外、不同型別不能混用。`unsafe` 套件就是一扇**繞過這些保護**的後門。名字直接叫「不安全」，就是要每個用它的人都停下來想一想。

這一集的前半部分是安全的「觀察」，後半部分才是真正危險的操作。

### `Sizeof`：一個值佔多少記憶體

`unsafe.Sizeof(x)` 回傳 `x` 這個型別佔多少個位元組（byte）。以下是在 64 位元電腦上的結果，現在的電腦幾乎都是 64 位元：

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	fmt.Println("bool:", unsafe.Sizeof(true))
	fmt.Println("int32:", unsafe.Sizeof(int32(0)))
	fmt.Println("int:", unsafe.Sizeof(0))
	fmt.Println("string:", unsafe.Sizeof("你好，世界"))
	fmt.Println("[]int:", unsafe.Sizeof([]int{1, 2, 3, 4, 5}))
}
```

執行結果：

```text
bool: 1
int32: 4
int: 8
string: 16
[]int: 24
```

注意最後兩行：不管字串多長、切片有幾個元素，大小都一樣。附錄一 h 說過，切片只是一個 header，裡面放指向底層陣列的指標、長度和容量，三個欄位各 8 位元組，共 24；字串則是指標加長度，共 16。真正的資料在別的地方，`Sizeof` 不會算進去。

### `Alignof`、`Offsetof`：欄位的排列

CPU 讀取記憶體時，喜歡從「對齊」的位置開始讀，例如 8 位元組的 `int64` 要放在 8 的倍數的位置。`unsafe.Alignof` 告訴你一個值要對齊到幾的倍數，`unsafe.Offsetof` 告訴你某個 struct 欄位距離 struct 開頭有幾個位元組。

為了對齊，編譯器會在欄位之間塞入空白（padding），所以欄位的**順序**會影響 struct 的大小：

```go
package main

import (
	"fmt"
	"unsafe"
)

type Loose struct {
	a bool
	b int64
	c bool
}

type Tight struct {
	b int64
	a bool
	c bool
}

func main() {
	var l Loose
	fmt.Println("int64 對齊:", unsafe.Alignof(l.b))
	fmt.Println("Loose 欄位位置:", unsafe.Offsetof(l.a), unsafe.Offsetof(l.b), unsafe.Offsetof(l.c))
	fmt.Println("Loose 大小:", unsafe.Sizeof(l))

	var t Tight
	fmt.Println("Tight 欄位位置:", unsafe.Offsetof(t.b), unsafe.Offsetof(t.a), unsafe.Offsetof(t.c))
	fmt.Println("Tight 大小:", unsafe.Sizeof(t))
}
```

執行結果：

```text
int64 對齊: 8
Loose 欄位位置: 0 8 16
Loose 大小: 24
Tight 欄位位置: 0 8 9
Tight 大小: 16
```

`Loose` 的 `a` 只佔 1 位元組，但 `b` 必須從 8 開始，中間空了 7 個位元組；`c` 後面也要補空白，讓整個 struct 的大小是 8 的倍數。`Tight` 把大欄位放前面，兩個 `bool` 擠在一起，就省下了 8 個位元組。

這三個函式只是**讀取**資訊，不會造成危險，而且結果在編譯時就決定了。一般程式不需要在意欄位順序，除非你要建立上百萬個這種 struct，才值得考慮。

### 危險區：不複製的轉換

`string(b)` 把 `[]byte` 轉成字串時，Go 會**複製**一份資料，因為字串不能被修改，而切片可以。資料很大時，有人會想省下這次複製，`unsafe` 提供了這樣的函式：

- `unsafe.SliceData(b)`：取得切片底層陣列第一個元素的指標。
- `unsafe.String(ptr, n)`：從指標 `ptr` 開始的 `n` 個位元組，直接當成一個字串，不複製。
- `unsafe.StringData(s)`：取得字串底層資料的指標。
- `unsafe.Slice(ptr, n)`：從指標 `ptr` 開始的 `n` 個元素，直接當成一個切片。

看看不複製會發生什麼事：

```go
package main

import (
	"fmt"
	"unsafe"
)

func main() {
	b := []byte("hello")

	copied := string(b)
	shared := unsafe.String(unsafe.SliceData(b), len(b))
	fmt.Println(copied, shared)

	b[0] = 'J'
	fmt.Println(copied, shared)
}
```

執行結果：

```text
hello hello
hello Jello
```

`shared` 和 `b` 共用同一塊記憶體，所以改了 `b`，這個「不能被修改」的字串就跟著變了。Go 的其他部分都假設字串永遠不會變，例如拿字串當 map 的 key，字串偷偷變了，map 就可能再也找不到那筆資料。這種錯誤不會有任何錯誤訊息，非常難查。

反過來，用 `unsafe.Slice(unsafe.StringData(s), len(s))` 可以把字串直接看成 `[]byte`，但這個切片**絕對不能寫入**。字串的資料可能放在唯讀的記憶體裡，寫入會讓程式直接當掉。

### 什麼時候可以用

答案和 `reflect` 一樣，而且更嚴格：**幾乎不要用**。

- 用了 `unsafe` 的程式，可能在不同的 CPU、不同的 Go 版本上行為不同，Go 的相容性保證也不包含它。
- 錯誤通常不是 panic，而是資料悄悄被破壞。
- 先用一般程式碼寫，用第 8 章的 benchmark 量過、確認複製真的是瓶頸，再考慮它。即使要用，也要把它包在一個小函式裡，加上註解說明為什麼安全。

你會在標準函式庫和一些追求極致效能的套件裡看到它；能讀懂就好。

## 重點整理

- `unsafe` 套件會繞過 Go 的型別安全，名字本身就是警告。
- `unsafe.Sizeof`、`Alignof`、`Offsetof` 只讀取大小、對齊與欄位位置；欄位順序會因為 padding 影響 struct 大小。
- `unsafe.String`、`unsafe.StringData`、`unsafe.Slice`、`unsafe.SliceData` 可以在字串和切片之間轉換而不複製，但會破壞「字串不可變」的保證。
- 除非量測過、確定必要，否則不要使用 `unsafe`。
