# `strings` 套件常用函式

## 本集目標

認識標準函式庫 `strings` 套件裡幾個最常用的字串處理函式。

## 正文

處理文字是寫程式最常做的事之一：檢查有沒有某個關鍵字、把一行文字拆開、去掉多餘的空白……這些 Go 都已經幫我們寫好了，放在 `strings` 套件裡。用法跟 `fmt` 一樣，先 `import "strings"`，再用 `strings.函式名稱(...)` 呼叫。

### 檢查與尋找

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	s := "Go 是一個好玩的語言"
	fmt.Println(strings.Contains(s, "好玩"))
	fmt.Println(strings.Contains(s, "無聊"))
	fmt.Println(strings.HasPrefix(s, "Go"))
	fmt.Println(strings.HasSuffix(s, "語言"))
	fmt.Println(strings.Count("banana", "a"))
}
```

執行結果：

```text
true
false
true
true
3
```

- `Contains(s, sub)`：`s` 裡面有沒有 `sub`。
- `HasPrefix` / `HasSuffix`：是不是以某段文字開頭／結尾。
- `Count`：某段文字出現幾次。

### 轉換與清理

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	fmt.Println(strings.ToUpper("hello go"))
	fmt.Println(strings.ToLower("HELLO"))
	fmt.Printf("%q\n", strings.TrimSpace("   有空白   "))
	fmt.Println(strings.Repeat("=", 10))
	fmt.Println(strings.ReplaceAll("我喜歡貓，貓很可愛", "貓", "狗"))
}
```

執行結果：

```text
HELLO GO
hello
"有空白"
==========
我喜歡狗，狗很可愛
```

- `ToUpper` / `ToLower`：轉大寫／小寫。
- `TrimSpace`：去掉頭尾的空白和換行。處理使用者輸入時非常好用，用 `%q` 印出來可以清楚看到空白不見了。
- `Repeat(s, n)`：把 `s` 重複 `n` 次。
- `ReplaceAll(s, old, new)`：把所有的 `old` 換成 `new`。

記得字串是不可修改的：這些函式都**不會改**原本的字串，而是回傳一個新的字串。

### 拆開與合併

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	parts := strings.Split("蘋果,香蕉,芭樂", ",")
	fmt.Println(parts, len(parts))

	words := strings.Fields("  Go   is  fun ")
	fmt.Println(words, len(words))

	fmt.Println(strings.Join(words, "-"))
}
```

執行結果：

```text
[蘋果 香蕉 芭樂] 3
[Go is fun] 3
Go-is-fun
```

- `Split(s, sep)`：用 `sep` 把字串切開，回傳一個 `[]string` 切片。
- `Fields(s)`：用空白切開，連續好幾個空白會當成一個，頭尾的空白也會忽略。
- `Join(切片, sep)`：反過來，把 `[]string` 用 `sep` 接成一個字串。

### 組合起來：加總一行數字

把讀取輸入、`Split`、`TrimSpace`、`strconv.Atoi` 組合起來，就能做出一個只會加法的小計算機：

```go,stdin=3+8+12
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	line := scanner.Text()

	total := 0
	for _, part := range strings.Split(line, "+") {
		n, err := strconv.Atoi(strings.TrimSpace(part))
		if err != nil {
			fmt.Println("請輸入整數")
			return
		}
		total += n
	}
	fmt.Println("總和", total)
}
```

輸入 `3+8+12` 的執行結果：

```text
總和 23
```

`Split` 用 `+` 把輸入切成 `"3"`、`"8"`、`"12"`，再一個一個轉成整數加起來。多加 `TrimSpace`，是為了讓使用者輸入 `3 + 8 + 12` 這種有空白的寫法也能正確轉換。

`strings` 套件還有很多函式，想知道有哪些，可以在終端機執行 `go doc strings` 看看。

## 重點整理

- 使用前要 `import "strings"`，用 `strings.函式名稱(...)` 呼叫。
- 檢查：`Contains`、`HasPrefix`、`HasSuffix`、`Count`。
- 轉換：`ToUpper`、`ToLower`、`TrimSpace`、`Repeat`、`ReplaceAll`，都回傳新字串，不改原字串。
- 拆合：`Split` 用指定分隔字切開、`Fields` 用空白切開、`Join` 把 `[]string` 接回字串。
