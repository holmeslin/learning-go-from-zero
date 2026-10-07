# 文件註解與 `go doc`

## 本集目標

學會替套件和匯出的名稱寫文件註解，並用 `go doc` 在終端機查文件。

## 正文

### 文件註解是什麼

第 1 章學過，`//` 後面的文字是註解，Go 會忽略它。但有一種註解特別重要：**緊貼在宣告正上方、中間沒有空行**的註解，叫做**文件註解**（doc comment）。`go doc` 等工具會把它抓出來，當成這個東西的說明文件。

規矩有兩條：

- 每個匯出的名稱都應該有文件註解。
- 註解的第一句以**被說明的名稱開頭**，例如 `// Hello 回傳……`。套件的註解則以 `// Package 套件名` 開頭。

### 幫 `greet` 寫文件

`greet/greet.go`：

```go,ignore
// Package greet 負責產生打招呼和道別的句子。
//
// 這個套件提供兩個函式：
//   - [Hello] 打招呼
//   - [Bye] 道別
//
// 使用方式：
//
//	msg := greet.Hello("小明")
//	fmt.Println(msg)
//
// # 注意事項
//
// 所有句子結尾都使用全形驚嘆號。
package greet

import "fmt"

// Hello 回傳對 name 打招呼的句子，例如「你好，小明！」。
//
// 如果 name 是空字串，會改用「朋友」。
func Hello(name string) string {
	if name == "" {
		name = "朋友"
	}
	return "你好，" + name + "！"
}

// Bye 回傳道別的句子，格式和 [Hello] 類似，內部用 [fmt.Sprintf] 組字串。
func Bye(name string) string {
	return fmt.Sprintf("再見，%s！", name)
}
```

### 文件註解的格式

從 Go 1.19 開始，文件註解有一套簡單的格式：

- **段落**：用只有 `//` 的空行分隔。
- **清單**：以 `-` 開頭的行，`gofmt` 會自動調整成上面那樣的縮排。
- **程式碼**：比一般文字多縮排的行（`//` 後面加一個 Tab），會原樣顯示。
- **標題**：`# ` 開頭的一行，前後要有空行，通常用在套件註解這種較長的說明裡。
- **連結**：用中括號包住名稱，例如 `[Hello]` 指向同一個套件的 `Hello`，`[fmt.Sprintf]` 指向別的套件。在網頁版文件中會變成可以點的連結。

### 用 `go doc` 查文件

在 `myapp` 資料夾執行 `go doc greet`，看整個套件：

```text
package greet // import "myapp/greet"

Package greet 負責產生打招呼和道別的句子。

這個套件提供兩個函式：
  - Hello 打招呼
  - Bye 道別

使用方式：

    msg := greet.Hello("小明")
    fmt.Println(msg)

# 注意事項

所有句子結尾都使用全形驚嘆號。

func Bye(name string) string
func Hello(name string) string
```

套件說明下面列出了所有匯出的函式。小寫開頭的名稱不會出現，因為那不是給別人用的。

查單一個函式，用 `go doc greet.Hello`：

```text
package greet // import "myapp/greet"

func Hello(name string) string
    Hello 回傳對 name 打招呼的句子，例如「你好，小明！」。

    如果 name 是空字串，會改用「朋友」。
```

### 標準庫也查得到

標準庫的文件也都是這樣寫出來的。試試 `go doc fmt.Println`：

```text
package fmt // import "fmt"

func Println(a ...any) (n int, err error)
    Println formats using the default formats for its operands and writes to
    standard output. Spaces are always added between operands and a newline
    is appended. It returns the number of bytes written and any write error
    encountered.
```

原來 `fmt.Println` 有兩個回傳值，只是我們一直沒去接。遇到不熟的函式，`go doc 套件.名稱` 是最快的查法；想看完整的說明，可以加上 `-all`，例如 `go doc -all greet`。

## 重點整理

- 緊貼在宣告上方的註解是文件註解，第一句以被說明的名稱開頭；套件註解以 `Package 名稱` 開頭。
- 文件註解支援段落、`-` 清單、縮排的程式碼、`#` 標題和 `[名稱]` 連結。
- `go doc 套件` 看套件說明，`go doc 套件.名稱` 看單一名稱，`-all` 看全部。
- 每個匯出的名稱都應該寫文件註解。
