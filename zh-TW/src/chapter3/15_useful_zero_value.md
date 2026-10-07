# 讓零值有用

## 本集目標

理解 Go 的一個設計習慣：讓型別的零值不用初始化就能直接使用，並學會在自己的型別上做到這件事。

## 正文

這一章我們一直看到零值：struct 沒填的欄位是零值，`var c Counter` 得到的也是零值。在 Go 裡，好的型別設計會讓**零值本身就能用**，不需要額外的初始化步驟。

### 切片的零值就能用

其實第 2 章已經見過這種設計了：

```go
package main

import "fmt"

func main() {
	var names []string
	names = append(names, "Andy")
	names = append(names, "Betty")
	fmt.Println(names, len(names))
}
```

執行結果：

```text
[Andy Betty] 2
```

`names` 一開始是 `nil` 切片，但不用先 `make`，直接 `append` 就好。

### 標準庫的例子：`strings.Builder`

`strings.Builder` 是標準庫裡用來一段一段拼接字串的型別。宣告完就能直接用：

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	sb.WriteString("Hello")
	sb.WriteString(", ")
	sb.WriteString("Go")
	fmt.Println(sb.String())
}
```

執行結果：

```text
Hello, Go
```

不用呼叫什麼「建立 Builder」的函式，`var sb strings.Builder` 的零值就是一個空的 Builder。`WriteString` 把字串接到後面，`String` 取出目前拼好的結果。

標準庫裡還有很多型別是這樣設計的，例如之後學並行時會用到的 `sync.Mutex`，零值就是一把沒鎖上的鎖，直接就能用。

### 反例：零值不能用的 map

第 2 章學過，`nil` map 不能寫入。如果我們的型別裡有 map，零值就會出問題：

```go,exit=2
package main

import "fmt"

type WordCount struct {
	counts map[string]int
}

func (w *WordCount) Add(word string) {
	w.counts[word]++
}

func main() {
	var wc WordCount
	wc.Add("go")
	fmt.Println(wc.counts)
}
```

執行結果：

```text
panic: assignment to entry in nil map
```

後面還有幾行出錯位置的資訊，這裡省略。`var wc WordCount` 裡的 `counts` 是 `nil` map，`Add` 一寫入就 panic。使用者必須記得先寫 `wc.counts = make(map[string]int)`，很容易忘記。

### 讓自己的型別零值可用

解法是在方法裡檢查：map 還是 `nil` 的話，就先建立它：

```go
package main

import "fmt"

type WordCount struct {
	counts map[string]int
}

func (w *WordCount) Add(word string) {
	if w.counts == nil {
		w.counts = make(map[string]int)
	}
	w.counts[word]++
}

func (w *WordCount) Get(word string) int {
	return w.counts[word]
}

func main() {
	var wc WordCount
	fmt.Println(wc.Get("go"))
	wc.Add("go")
	wc.Add("go")
	wc.Add("hi")
	fmt.Println(wc.Get("go"), wc.Get("hi"))
}
```

執行結果：

```text
0
2 1
```

現在 `var wc WordCount` 就能直接用了。`Add` 第一次被呼叫時才建立 map；`Get` 則不用檢查，因為讀取 `nil` map 不會 panic，只會得到零值 `0`。

`Add` 要修改 `w.counts`，所以用指標接收者；`Get` 為了跟 `Add` 統一，也用指標接收者（第 10 集的慣例）。

設計自己的型別時，問自己一句：「別人寫 `var x 我的型別` 之後，能不能直接用？」能的話，你的型別就會很好用。

## 重點整理

- Go 的慣例是讓型別的零值不用初始化就能使用。
- `nil` 切片可以直接 `append`；`strings.Builder`、`sync.Mutex` 的零值都能直接用。
- 型別裡有 map 時，可以在方法裡先檢查 `nil` 再 `make`，讓零值可用。
- 讀取 `nil` map 得到零值，寫入 `nil` map 會 panic。
