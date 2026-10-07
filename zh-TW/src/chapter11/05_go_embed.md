# `//go:embed`

## 本集目標

學會用 `//go:embed` 把檔案的內容在編譯時直接放進執行檔，存成 `string`、`[]byte` 或 `embed.FS`。

## 正文

### 執行檔帶著檔案走

程式常常需要一些「不是程式碼」的檔案：網頁範本、預設設定、說明文字、圖片。如果程式執行時才去讀這些檔案，就得確保它們跟執行檔放在一起，搬到別台電腦時很容易漏掉。

Go 的做法是：**編譯時就把檔案內容塞進執行檔裡**。這樣只要複製一個執行檔，檔案內容就跟著走了。做法是在變數上方加一行 `//go:embed` 指令。

### 先看一個能直接跑的例子

`//go:embed` 後面寫檔名，指的是和這個 `.go` 檔放在同一個資料夾（或子資料夾）的檔案。最好示範的檔案，就是 `main.go` 自己：

```go
package main

import (
	_ "embed"
	"fmt"
	"strings"
)

//go:embed main.go
var source string

func main() {
	lines := strings.Split(source, "\n")
	fmt.Println("第一行:", lines[0])
	fmt.Println("總共", strings.Count(source, "\n"), "行")
}
```

執行結果：

```text
第一行: package main
總共 16 行
```

- `//go:embed main.go` 寫在 `var source string` 的正上方，兩者中間不能有空行或其他程式碼。`//` 和 `go:embed` 之間也不能有空格，不然就只是一般註解。
- 編譯時，Go 讀取 `main.go` 的內容，當作 `source` 的初始值。執行時不會再去開檔案。
- 用 `//go:embed` 一定要引入 `embed` 套件。這裡只用到 `string`，沒有直接用 `embed` 的名字，所以用第 8 章的底線別名 `_ "embed"` 引入。
- 變數必須寫在函式外面（套件層級），不能放在函式裡。

### 嵌入其他檔案

實際上我們嵌入的是另外準備的檔案。假設資料夾長這樣：

```text
myapp/
├── go.mod
├── main.go
├── hello.txt
└── templates/
    ├── about.html
    └── index.html
```

`hello.txt` 的內容是「你好，歡迎使用！」，兩個 `.html` 各是一行標題。`main.go`：

```go,ignore
package main

import (
	"embed"
	"fmt"
)

//go:embed hello.txt
var greeting string

//go:embed templates
var templates embed.FS

func main() {
	fmt.Print(greeting)

	data, err := templates.ReadFile("templates/index.html")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Print(string(data))

	entries, err := templates.ReadDir("templates")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	for _, e := range entries {
		fmt.Println(e.Name())
	}
}
```

編譯之後，把執行檔複製到**另一個空資料夾**再執行：

```bash
go build -o app .
mkdir ../elsewhere
cp app ../elsewhere/
cd ../elsewhere
./app
```

執行結果：

```text
你好，歡迎使用！
<h1>首頁</h1>
about.html
index.html
```

旁邊明明沒有 `hello.txt` 和 `templates`，程式還是讀得到，因為內容已經在執行檔裡了。

### 三種變數型別

`//go:embed` 可以放在三種型別的變數上：

| 變數型別 | 適合 | 說明 |
| --- | --- | --- |
| `string` | 單一文字檔 | 整個檔案變成一個字串 |
| `[]byte` | 單一檔案（含圖片等二進位資料） | 整個檔案變成位元組切片 |
| `embed.FS` | 多個檔案或整個資料夾 | 一個唯讀的小型檔案系統 |

`embed.FS` 的 `ReadFile` 讀出某個檔案的 `[]byte`，`ReadDir` 列出資料夾內容。路徑一律用 `/` 分隔，從 `.go` 檔所在的資料夾算起，所以要寫 `templates/index.html`，不是 `index.html`。`embed.FS` 也能交給 `html/template`、`net/http` 等套件直接使用，第 14 章做網頁服務時會用到。

一行 `//go:embed` 可以寫好幾個檔名，也可以用萬用字元，例如 `//go:embed templates/*.html`。

### 找不到檔案就編譯失敗

如果寫錯檔名，例如 `//go:embed hello2.txt`，編譯時就會失敗。

編譯錯誤：

```text
main.go:9:12: pattern hello2.txt: no matching files found
```

這是好事：錯誤在編譯時就被抓到，不會等到使用者執行時才發現檔案不見。

另外要注意，只能嵌入**模組裡面**的檔案，不能用 `..` 往上層資料夾找；以 `.` 或 `_` 開頭的檔案，在嵌入整個資料夾時預設會被略過。

## 重點整理

- `//go:embed 檔名` 寫在套件層級變數的正上方，編譯時把檔案內容放進執行檔，執行時不需要原本的檔案。
- 變數型別可以是 `string`、`[]byte` 或 `embed.FS`；使用時要引入 `embed`，只用 `string`／`[]byte` 時寫成 `_ "embed"`。
- `embed.FS` 可以嵌入整個資料夾，用 `ReadFile`、`ReadDir` 讀取，路徑從 `.go` 檔所在資料夾算起、用 `/` 分隔。
- 檔案不存在會在編譯時就報錯；只能嵌入模組內的檔案。
