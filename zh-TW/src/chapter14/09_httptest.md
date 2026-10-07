# `httptest`

## 本集目標

正式認識這一章一直在用的 `net/http/httptest`：用 `NewRecorder` 不經網路直接測 handler，用 `NewServer` 開一台測試用的真伺服器來測 client，並把它們寫成 `go test` 測試。

## 正文

### 為什麼需要 `httptest`

測試 Web 程式時，我們不想真的開在 8080 埠：可能被占用、要記得關掉、測試之間還會互相干擾。`httptest` 提供兩種替身：

| 工具 | 做什麼 | 適合測 |
| --- | --- | --- |
| `httptest.NewRecorder` + `httptest.NewRequest` | 假造請求，直接呼叫 `ServeHTTP`，把回應記在記憶體裡 | handler、middleware、路由 |
| `httptest.NewServer` | 在本機隨機的埠開一台真的伺服器 | HTTP client 程式 |

### `NewRecorder`：不經網路測 handler

回頭看第 2 集起就在用的 `show`：

```go,ignore
func show(h http.Handler, method, target string) {
	req := httptest.NewRequest(method, target, nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s", method, target, rec.Code, rec.Body.String())
}
```

- `httptest.NewRequest(方法, 網址, 內容)` 建立一個「好像從網路上收到的」`*http.Request`。內容不需要時傳 `nil`，需要時傳 `strings.NewReader(...)`（第 4 集）。它專門給測試用，參數有錯會直接 `panic`，所以不回傳 `error`。
- `httptest.NewRecorder()` 回傳一個 `*httptest.ResponseRecorder`。它實作了 `http.ResponseWriter`，handler 寫給它的東西都被記下來：`rec.Code` 是狀態碼、`rec.Header()` 是標頭、`rec.Body` 是內容（一個 `*bytes.Buffer`）。
- `h.ServeHTTP(rec, req)` 就是直接呼叫 handler。沒有網路、沒有 goroutine，所以結果是確定的。

### `NewServer`：真的伺服器

第 6 集測 client 時，需要一台真的會回應的伺服器，就用 `httptest.NewServer`：

```go
package main

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
)

func main() {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "你請求了 %s\n", r.URL.Path)
	}))
	defer srv.Close()

	resp, err := srv.Client().Get(srv.URL + "/ping")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Print(resp.StatusCode, " ", string(body))
}
```

執行結果：

```text
200 你請求了 /ping
```

- `httptest.NewServer(handler)` 在 `127.0.0.1` 找一個沒人用的埠，立刻啟動伺服器。`srv.URL` 是它的網址，每次的埠號不同，所以不要把網址寫死。
- `defer srv.Close()` 關閉伺服器，它會等處理中的請求結束。
- `srv.Client()` 回傳一個設定好、適合連這台伺服器的 `*http.Client`。測試裡的請求很快，這裡用它很方便；但你自己的 client 程式還是要像第 6 集那樣設 `Timeout`。

### 寫成真正的測試

把 handler 放在自己的套件，再用第 8 章的 `go test` 和表格驅動測試來測。`greet.go`：

```go,ignore
package greet

import (
	"fmt"
	"net/http"
)

// Hello 依查詢參數 name 打招呼；沒有 name 時回 400。
func Hello(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	if name == "" {
		http.Error(w, "缺少 name", http.StatusBadRequest)
		return
	}
	fmt.Fprintf(w, "哈囉，%s\n", name)
}
```

`greet_test.go`：

```go,ignore
package greet

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHello(t *testing.T) {
	tests := []struct {
		name     string
		target   string
		wantCode int
		wantBody string
	}{
		{"有名字", "/hello?name=小明", http.StatusOK, "哈囉，小明\n"},
		{"沒有名字", "/hello", http.StatusBadRequest, "缺少 name\n"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, tt.target, nil)
			rec := httptest.NewRecorder()
			Hello(rec, req)

			if rec.Code != tt.wantCode {
				t.Errorf("狀態碼 = %d，想要 %d", rec.Code, tt.wantCode)
			}
			if got := rec.Body.String(); got != tt.wantBody {
				t.Errorf("內容 = %q，想要 %q", got, tt.wantBody)
			}
		})
	}
}

func TestHelloOverHTTP(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(Hello))
	defer srv.Close()

	resp, err := srv.Client().Get(srv.URL + "/hello?name=Andy")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		t.Fatal(err)
	}
	if string(body) != "哈囉，Andy\n" {
		t.Errorf("內容 = %q", body)
	}
}
```

```bash
go test -v .
```

執行結果（某一次）：

```text
=== RUN   TestHello
=== RUN   TestHello/有名字
=== RUN   TestHello/沒有名字
--- PASS: TestHello (0.00s)
    --- PASS: TestHello/有名字 (0.00s)
    --- PASS: TestHello/沒有名字 (0.00s)
=== RUN   TestHelloOverHTTP
--- PASS: TestHelloOverHTTP (0.00s)
PASS
ok  	greet	2.089s
```

- `TestHello` 用 `NewRecorder` 直接呼叫 `Hello`，一個請求一個子測試（`t.Run`），速度快、結果穩定。大部分的 handler 測試都應該這樣寫。
- `TestHelloOverHTTP` 用 `NewServer` 走一次真正的 HTTP，連網址解析、標頭編碼都測到。適合測 client 程式，或確認整條路真的通。

middleware 也能用一樣的方式測：把 middleware 包在一個簡單的 handler 外面，交給 `ServeHTTP`，再檢查 `rec`。

## 重點整理

- `httptest.NewRequest` 假造請求、`httptest.NewRecorder` 記錄回應，直接呼叫 `ServeHTTP` 就能測 handler，不經過網路。
- `rec.Code`、`rec.Header()`、`rec.Body` 分別是狀態碼、標頭和內容。
- `httptest.NewServer(handler)` 在本機隨機埠開真的伺服器，網址是 `srv.URL`，記得 `defer srv.Close()`。
- 把它們放進 `_test.go`，配合表格驅動測試與 `t.Run`，就能用 `go test` 測整個 Web 服務。
