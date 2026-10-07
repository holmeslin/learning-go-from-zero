# 小介面設計

## 本集目標

了解 Go 偏好「只有一兩個方法的小介面」的原因，並看看標準庫的 `io.Writer` 怎麼讓同一個函式寫到不同地方。

## 正文

到目前為止我們看過的介面：`Shape`、`fmt.Stringer`、`Speaker`，幾乎都只有一個方法。這不是巧合，Go 社群有一句常被引用的話：「介面越大，抽象越弱。」

### 介面小，符合的型別就多

介面要求的方法越多，能實作它的型別就越少，用起來越綁手綁腳。反過來，只要求一個方法的介面，很多型別都能輕鬆符合。

只有一個方法的介面，慣例上用「方法名稱 + er」來命名：`String()` 的介面叫 `Stringer`，`Write()` 的介面叫 `Writer`，`Read()` 的叫 `Reader`。

### 標準庫的 `io.Writer`

`io` 套件裡的 `io.Writer` 是 Go 最有名的小介面之一：

```go,ignore
type Writer interface {
	Write(p []byte) (n int, err error)
}
```

意思是「可以寫入一串 byte 的東西」。第二個回傳值的型別 `error` 是第 5 章的主題，這裡不用管它，我們也不會自己實作 `Write`，只是用用看。

`fmt` 套件有一個 `fmt.Fprintln`，用法和 `fmt.Println` 一樣，只是第一個參數要給一個 `io.Writer`，告訴它要寫到哪裡：

```go
package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	fmt.Fprintln(os.Stdout, "直接印到螢幕")

	var sb strings.Builder
	fmt.Fprintln(&sb, "寫進 Builder")
	fmt.Fprintln(&sb, "第二行")
	fmt.Print(sb.String())
}
```

執行結果：

```text
直接印到螢幕
寫進 Builder
第二行
```

- `os.Stdout` 代表螢幕（標準輸出），讀輸入時用過的 `os.Stdin` 是它的好兄弟。`os.Stdout` 有 `Write` 方法，所以是 `io.Writer`。其實 `fmt.Println` 做的事，就是 `fmt.Fprintln(os.Stdout, ...)`。
- 第 3 章的 `strings.Builder` 也有 `Write` 方法，所以也是 `io.Writer`。它的 `Write` 是指標接收者，所以要傳 `&sb`（第 3 集的方法集合）。
- `fmt.Print` 和 `fmt.Println` 一樣，只是最後不會自動換行。這裡 `sb` 裡的字串本身已經有換行了。

`fmt.Fprintln` 不知道也不在乎自己寫到的是螢幕還是 Builder，它只要求「有 `Write` 方法」。之後學到的檔案、網路連線也都是 `io.Writer`，同一個 `fmt.Fprintln` 全部都能用。

### 自己寫函式時也一樣

寫函式時，參數只要求**真正用到的**方法就好：

```go
package main

import (
	"fmt"
	"io"
	"os"
	"strings"
)

func greet(w io.Writer, name string) {
	fmt.Fprintln(w, "你好，"+name)
}

func main() {
	greet(os.Stdout, "Andy")

	var sb strings.Builder
	greet(&sb, "Betty")
	fmt.Print("Builder 裡有：", sb.String())
}
```

執行結果：

```text
你好，Andy
Builder 裡有：你好，Betty
```

`greet` 只需要「能寫」，所以參數寫 `io.Writer`，而不是某個具體型別。這樣它既能印到螢幕，也能寫進 Builder。第 8 章寫測試時，這個技巧特別好用：把輸出寫進 Builder，再檢查內容對不對。

### 設計自己的介面

幾個實用的原則：

- 先寫具體的型別，等真的有兩種以上的型別需要被同樣對待時，再定義介面。
- 介面只放呼叫端真正需要的方法，一兩個就好。
- 需要更多功能時，用上一集的介面嵌入把小介面組合起來。

## 重點整理

- Go 偏好只有一兩個方法的小介面；方法越少，能實作的型別越多。
- 單一方法的介面慣例命名為「方法名 + er」，例如 `Stringer`、`Writer`。
- `io.Writer` 代表「能寫入的東西」；`os.Stdout`、`*strings.Builder` 都是 `io.Writer`。
- `fmt.Fprintln(w, ...)` 可以寫到任何 `io.Writer`；函式參數只要求真正用到的方法。
