# 寫作風格指南

撰寫或修改 `zh-TW/src/` 內容前請先讀完。名詞定義見根目錄 `GLOSSARY.md`。

## 讀者與語氣

- 讀者**完全零基礎**，沒寫過程式也要看得懂。
- 繁體中文原生撰寫（台灣用語：程式、函式、變數、物件、預設、檔案、介面、迴圈、陣列、記憶體），不是翻譯腔。
- 口語、友善、短句，用「我們」「你」。不要說「這很簡單」「顯然」「不過如此」。
- 不寫成維基百科或規格書。先講直覺，再上程式碼。
- 中英文之間加半形空格；程式碼、識別字、指令用反引號。
- 不參考、不改寫、不翻譯其他教學的文字（特別是 learning-rust-from-zero，其文字為 CC BY-NC-ND）。

## 每一集的格式

檔名 `##_slug.md`（附錄 `a_slug.md`），標題與 `SUMMARY.md` 的標題一致：

```markdown
# <與 SUMMARY 相同的標題>

## 本集目標

一兩句話：讀完這集你會什麼。

## 正文

用 `###` 小標分段。每段一個重點，短範例 + 白話解說。

## 重點整理

- 3～5 條，條列本集真正教了什麼（AI 助教靠這段判斷進度）。
```

- 一集只教**一個**小概念。篇幅大約 40～150 行 markdown；第 1 章偏短。
- 每章的 `README.md` 只有 `# <章名>` 加一兩段導言，說明這章要學什麼、為什麼重要，不列目錄。

## 進度邊界（最重要）

- 範例與說明**只能使用 `SUMMARY.md` 中排在本集之前已教過的概念**，加上下方「固定句型」。
- 不得不提到後面的內容時，用一句話帶過並標明「第 X 章會正式介紹」，不展開。
- 不要「順便」介紹本集主題以外的語法。

## 固定句型

以下寫法在正式解釋之前就可以照抄使用，結構保持不變，只改變數名稱與文字：

| 首次出現 | 固定句型 | 正式解釋 |
| --- | --- | --- |
| 第 1 章第 2 集 | `go mod init <名稱>`、`go run .`；程式骨架 `package main` + `import "fmt"` + `func main() { ... }` | `package`／`import` 第 8 章；函式第 2 章 |
| 第 1 章第 2 集 | `fmt.Println(...)` | 函式呼叫第 2 章；套件第 8 章 |
| 第 1 章第 15 集 | 讀一行輸入：見下方 | 方法第 3 章；介面第 4 章 |
| 第 1 章第 16 集 | 文字轉整數：見下方 | 多回傳值第 2 章；`error` 第 5 章 |
| 第 14 章第 2 集 | `show` 小工具：`httptest.NewRequest` + `httptest.NewRecorder` 假造請求、印出回應；`httptest.NewServer(...)`、`defer srv.Close()`、`srv.URL` 在程式內開測試伺服器 | 第 14 章第 9 集 |

讀一行輸入（每支程式建立一次 `scanner`，之後每次要讀一行就重複後兩行）：

```go,ignore
scanner := bufio.NewScanner(os.Stdin)
scanner.Scan()
line := scanner.Text()
```

文字轉整數：

```go,ignore
n, err := strconv.Atoi(line)
if err != nil {
	fmt.Println("請輸入整數")
	return
}
```

`import` 有多個套件時一律用括號形式，並依字母排序（就是 `gofmt` 的結果）：

```go,ignore
import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)
```

## 程式碼區塊

- 一律 `gofmt` 格式（Tab 縮排）。
- ```` ```go ```` 區塊必須是**完整可編譯的 `package main`**，會被 `tools/checkcode` 執行：`go vet` 必須通過，執行必須以結束碼 0 結束。
- 需要特殊處理時，在 info string 加標註，值裡面不能有空白：

| 標註 | 用在 |
| --- | --- |
| `go,stdin=Andy` / `go,stdin=3\n5` | 讀輸入的範例（`\n` 代表換行） |
| `go,compile_fail` | 故意展示編譯錯誤 |
| `go,exit=2` | 故意 `panic` 或死結（Go 的 panic 結束碼是 2） |
| `go,norun` | 會一直執行或需要外部環境，只編譯 |
| `go,ignore` | 不完整的片段、多檔案範例、`go.mod` 以外的檔案內容 |

- 輸出區塊前一行固定寫「執行結果：」（輸出不固定時寫「執行結果（某一次）：」），編譯錯誤寫「編譯錯誤：」。
- 範例的 `go.mod` 由 `tools/checkcode/deps/go.mod` 提供（`go 1.27`，並鎖定 `modernc.org/sqlite`）；除了第 15 章的 SQLite driver，不得 import 第三方套件。
- 程式輸出用 ```` ```text ```` 區塊呈現，**必須與實際執行結果完全一致**（自己跑過再貼）。輸出順序不固定的（map 走訪、goroutine），要在文中說明。
- 終端機指令用 ```` ```bash ````，`go.mod` 內容用 ```` ```gomod ````（這兩種不會被驗證）。
- 展示編譯錯誤時，錯誤訊息用 ```` ```text ```` 貼出 Go 1.27 實際的訊息，可省略檔案路徑前綴。
- 不要用 `go,ignore` 逃避驗證：能寫成完整程式就寫成完整程式。

## 正確性

- 以 Go 1.27 為準。Go 1.22 起迴圈變數每次迭代各一份；1.23 起有 range over func；1.26 起 `new(expr)`、`errors.AsType`；1.27 起泛型方法、struct literal 可用巢狀欄位選擇器、`encoding/json/v2`、`uuid` 套件。
- 不要寫過時的網路說法（例如 Go 1.22 前的迴圈變數陷阱、`time.After` 在迴圈中洩漏）。
- 不確定時用 `go doc <套件>.<名稱>` 或實際寫程式驗證，不要憑印象。
- 完成後執行 `go run ./tools/checkcode zh-TW/src/<章節目錄>`，全部通過才算完成。
