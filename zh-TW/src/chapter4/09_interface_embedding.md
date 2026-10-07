# 介面嵌入

## 本集目標

用介面嵌入，把幾個小介面組合成一個大介面。

## 正文

第 3 章學過，struct 可以嵌入別的型別。介面也可以嵌入介面，效果是把方法清單「合併」起來。

### 把兩個介面合成一個

```go
package main

import "fmt"

type Speaker interface {
	Speak() string
}

type Walker interface {
	Walk() string
}

type Pet interface {
	Speaker
	Walker
}

type Dog struct {
	Name string
}

func (d Dog) Speak() string {
	return d.Name + "：汪汪"
}

func (d Dog) Walk() string {
	return d.Name + " 跑來跑去"
}

func play(p Pet) {
	fmt.Println(p.Speak())
	fmt.Println(p.Walk())
}

func main() {
	play(Dog{Name: "Lucky"})
}
```

執行結果：

```text
Lucky：汪汪
Lucky 跑來跑去
```

`Pet` 裡只寫了 `Speaker` 和 `Walker` 兩個介面的名字。這等於把它們的方法全部搬進來，所以 `Pet` 的方法清單是 `Speak()` 和 `Walk()`。上面的寫法和下面這樣寫完全一樣：

```go,ignore
type Pet interface {
	Speak() string
	Walk() string
}
```

`Dog` 兩個方法都有，所以實作了 `Pet`，同時也實作了 `Speaker` 和 `Walker`。

### 嵌入介面再加方法

嵌入之外，還可以再列自己的方法：

```go
package main

import "fmt"

type Speaker interface {
	Speak() string
}

type Singer interface {
	Speaker
	Sing() string
}

type Bird struct{}

func (b Bird) Speak() string {
	return "啾"
}

func (b Bird) Sing() string {
	return "啾啾啾～"
}

func main() {
	var s Singer = Bird{}
	fmt.Println(s.Speak(), s.Sing())

	var sp Speaker = s
	fmt.Println(sp.Speak())
}
```

執行結果：

```text
啾 啾啾啾～
啾
```

`Singer` 要求 `Speak()` 和 `Sing()` 兩個方法。`Bird{}` 是沒有任何欄位的 struct，它只是用來掛方法。

注意最後兩行：`Singer` 型別的變數可以直接放進 `Speaker` 變數。因為任何實作了 `Singer` 的東西，一定也有 `Speak()`，所以 Go 不需要型別斷言就允許這樣做。反過來，`Speaker` 要變成 `Singer` 就不行了，得用型別斷言檢查。

### 標準庫裡的例子

標準庫大量使用這種組合方式。例如 `io` 套件裡有 `io.Reader`（讀）和 `io.Writer`（寫）兩個小介面，`io.ReadWriter` 就是把它們嵌入在一起的介面。先有小介面，需要時再組合成大的，這是 Go 很常見的設計方式，下一集會再多談一點。

## 重點整理

- 介面可以嵌入其他介面，方法清單會合併在一起。
- 嵌入之外也能再列自己的方法。
- 實作了大介面的值，可以直接放進它所嵌入的小介面變數。
- 標準庫的 `io.ReadWriter` 就是由 `io.Reader` 和 `io.Writer` 組合而成。
