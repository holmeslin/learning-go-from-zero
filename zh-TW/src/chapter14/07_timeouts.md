# 逾時設定

## 本集目標

知道為什麼 `http.ListenAndServe` 不適合直接上線，會用 `http.Server` 設定四種逾時，並用 `http.TimeoutHandler` 限制 handler 的執行時間。

## 正文

### 預設沒有任何逾時

第 1 集的 `http.ListenAndServe(":8080", mux)` 很方便，但它**沒有設定任何逾時**。想像有人連上來之後，每 10 秒才送一個字元過來：伺服器會一直等他把請求送完，這條連線就一直被占著。對方只要同時開幾千條這樣的慢連線，伺服器就沒有資源服務正常的使用者了。這種攻擊叫做 Slowloris。

上一集我們說 client 一定要設逾時，伺服器也一樣。

### `http.Server` 的四種逾時

`http.ListenAndServe` 其實是幫你建立一個 `http.Server` 再啟動它。自己建立就能設定逾時：

```go,norun
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "哈囉")
	})

	srv := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       2 * time.Minute,
	}
	if err := srv.ListenAndServe(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

一個請求的時間軸大致是：「讀標頭 → 讀內容 → handler 執行並寫回應 → 連線閒置，等下一個請求」。四個欄位分別管：

| 欄位 | 從什麼時候到什麼時候 | 防的是 |
| --- | --- | --- |
| `ReadHeaderTimeout` | 連線開始 → 讀完請求標頭 | 慢慢送標頭的 Slowloris |
| `ReadTimeout` | 連線開始 → 讀完整個請求（含內容） | 慢慢上傳內容 |
| `WriteTimeout` | 讀完標頭 → 寫完回應 | 回應寫太久、對方讀太慢 |
| `IdleTimeout` | 一個請求結束 → 下一個請求開始 | 開著連線卻什麼都不送 |

數字沒有標準答案，要看你的服務。上面是一般 API 還算合理的起點。至少一定要設 `ReadHeaderTimeout`，很多安全檢查工具看到沒設它的伺服器都會發出警告。

注意 `WriteTimeout` 包含了 handler 執行的時間。時間到了，伺服器會中斷連線，但**不會**停止你的 handler，handler 自己要留意 `r.Context()`。

### 限制 handler：`http.TimeoutHandler`

`WriteTimeout` 到期時，使用者只會看到連線被切斷，沒有任何說明。如果想在 handler 太慢時回一個明確的錯誤，可以用 `http.TimeoutHandler` 這個標準庫的 middleware：

```go
package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"time"
)

func show(h http.Handler, method, target string) {
	req := httptest.NewRequest(method, target, nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s", method, target, rec.Code, rec.Body.String())
}

func work(d time.Duration) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-time.After(d):
			fmt.Fprintln(w, "做完了")
		case <-r.Context().Done():
			// 被取消了，不用再做，直接結束
		}
	}
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("GET /fast", work(10*time.Millisecond))
	mux.Handle("GET /slow", work(5*time.Second))

	handler := http.TimeoutHandler(mux, 100*time.Millisecond, "處理逾時，請稍後再試\n")

	show(handler, "GET", "/fast")
	show(handler, "GET", "/slow")
}
```

執行結果：

```text
GET /fast → 200 做完了
GET /slow → 503 處理逾時，請稍後再試
```

- `http.TimeoutHandler(h, 時間, 訊息)` 包住 `h`：`h` 在時間內做完就照常回應；超過時間就回 `503 Service Unavailable` 和你給的訊息。
- 時間到時，它會取消 `r.Context()`，所以 handler 用 `select` 等 `r.Context().Done()` 就能馬上停下，不會在背景白做工。
- `TimeoutHandler` 的時間要比 `WriteTimeout` 短，否則連線會先被切斷，使用者還是看不到錯誤訊息。

## 重點整理

- `http.ListenAndServe` 沒有任何逾時，正式上線要自己建立 `http.Server`。
- `ReadHeaderTimeout`、`ReadTimeout`、`WriteTimeout`、`IdleTimeout` 分別限制讀標頭、讀請求、寫回應與閒置的時間，至少要設 `ReadHeaderTimeout`。
- `WriteTimeout` 到期只會中斷連線，不會停止 handler。
- `http.TimeoutHandler` 讓太慢的 handler 回 `503` 並取消 `r.Context()`；handler 要配合檢查 context。
