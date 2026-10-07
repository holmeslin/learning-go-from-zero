# 第一個 HTTP 伺服器

## 本集目標

用 `http.HandleFunc` 和 `http.ListenAndServe` 架起一個會回應瀏覽器的伺服器，並看懂 handler 收到的兩個參數。

## 正文

### 請求與回應

在瀏覽器打開一個網址時，瀏覽器會送出一個 **HTTP 請求**（request），內容大致是「我要用 `GET` 方法拿 `/hello` 這個路徑」。伺服器收到後送回一個 **HTTP 回應**（response），裡面有狀態碼（`200` 代表成功、`404` 代表找不到）和內容。

我們要寫的，就是收到請求後決定回應什麼的那段程式。

### 最小的伺服器

```go,norun
package main

import (
	"fmt"
	"net/http"
	"os"
)

func hello(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		name = "世界"
	}
	fmt.Fprintf(w, "哈囉，%s！\n", name)
	fmt.Fprintf(w, "你用 %s 方法請求了 %s\n", r.Method, r.URL.Path)
}

func main() {
	http.HandleFunc("/", hello)

	fmt.Println("伺服器啟動：http://localhost:8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

這支程式會一直執行、等待請求，所以書裡只編譯不自動執行。自己執行 `go run .` 後，終端機會停在：

執行結果：

```text
伺服器啟動：http://localhost:8080
```

這時打開瀏覽器連到 `http://localhost:8080`，就會看到回應。也可以開另一個終端機視窗，用 `curl` 這個指令送請求：

```bash
curl localhost:8080
curl "localhost:8080/abc?name=小美"
curl -X POST localhost:8080/x
```

執行結果：

```text
哈囉，世界！
你用 GET 方法請求了 /
哈囉，小美！
你用 GET 方法請求了 /abc
哈囉，世界！
你用 POST 方法請求了 /x
```

要停止伺服器，回到執行它的終端機按 Ctrl+C。

### 一步一步看

**`http.HandleFunc("/", hello)`** 告訴 Go：「路徑符合 `/` 的請求，交給 `hello` 處理」。`/` 是最寬鬆的寫法，會符合**所有**路徑，所以 `/abc`、`/x` 也都進來了。下一集會學更精確的路由。

**`hello` 是一個 handler**，它固定收兩個參數：

- `w http.ResponseWriter`：用來寫回應。它是一個 `io.Writer`（第 4 章、第 12 章），所以能直接用 `fmt.Fprintf(w, ...)` 把文字寫給對方。
- `r *http.Request`：這次請求的所有資訊。`r.Method` 是方法（`GET`、`POST`……）、`r.URL.Path` 是路徑、`r.URL.Query().Get("name")` 取出網址 `?` 後面的查詢參數。

**`http.ListenAndServe(":8080", nil)`** 開始在 8080 埠（port）等待連線。`:8080` 表示「這台電腦的 8080 埠」；第二個參數 `nil` 表示使用預設的路由表，也就是剛才 `http.HandleFunc` 登記的地方。

`ListenAndServe` 會一直執行下去，**正常情況下永遠不會回傳**。它回傳時一定是出錯了，例如 8080 埠已經被別的程式占用：

執行結果：

```text
伺服器啟動：http://localhost:8080
listen tcp :8080: bind: address already in use
```

所以我們把錯誤印到 stderr，再以結束碼 1 結束（第 13 章第 4 集）。

### 每個請求在自己的 goroutine

`net/http` 會為每個連線開一個 goroutine（第 9 章）來執行 handler，所以一百個人同時連進來，handler 就會同時執行一百份。好處是不用自己處理並行；但如果 handler 會修改共用的變數，就要用 `sync.Mutex` 等工具保護，第 4 集會遇到。

### 看看完整的回應

`curl -i` 會連回應的標頭（header）一起印出來：

```bash
curl -i localhost:8080/
```

執行結果：

```text
HTTP/1.1 200 OK
Date: Wed, 07 Oct 2026 07:36:01 GMT
Content-Length: 48
Content-Type: text/plain; charset=utf-8

哈囉，世界！
你用 GET 方法請求了 /
```

我們沒有設定任何東西，`net/http` 就自動補上了狀態碼 `200 OK`、日期、內容長度，還根據內容猜出 `Content-Type` 是純文字。

## 重點整理

- `http.HandleFunc(路徑, 函式)` 登記 handler，`http.ListenAndServe(":8080", nil)` 啟動伺服器並一直執行。
- handler 的參數是 `w http.ResponseWriter`（寫回應，是 `io.Writer`）和 `r *http.Request`（請求資訊）。
- `r.Method`、`r.URL.Path`、`r.URL.Query().Get(...)` 取得方法、路徑、查詢參數。
- `ListenAndServe` 只有出錯時才會回傳，要檢查並處理它的錯誤。
- 每個請求在自己的 goroutine 執行，共用資料要注意並行安全。
