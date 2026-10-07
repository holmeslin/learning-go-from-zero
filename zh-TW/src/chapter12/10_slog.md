# `log/slog`

## 本集目標

用 `log/slog` 輸出結構化日誌：認識日誌層級、用「鍵＝值」屬性記錄資訊，並在 `TextHandler` 與 `JSONHandler` 之間切換。

## 正文

### 為什麼不用 `fmt.Println` 就好

程式上線之後，沒有人盯著螢幕看。我們需要**日誌**（log）：記錄程式做了什麼、什麼時候出了錯。好的日誌要有時間、要分輕重，而且最好讓程式也讀得懂，才能用工具搜尋「所有 `user_id=42` 的錯誤」。

`log/slog`（structured log，結構化日誌）就是做這件事的標準庫套件。

### 最簡單的用法

```go
package main

import "log/slog"

func main() {
	slog.Info("伺服器啟動", "port", 8080)
	slog.Warn("磁碟空間不足", "free_mb", 512)
	slog.Error("連線失敗", "host", "db.local", "retry", 3)
}
```

執行結果（某一次）：

```text
2026/10/07 15:36:10 INFO 伺服器啟動 port=8080
2026/10/07 15:36:10 WARN 磁碟空間不足 free_mb=512
2026/10/07 15:36:10 ERROR 連線失敗 host=db.local retry=3
```

- 第一個參數是訊息，後面的參數兩兩一組，是「鍵、值、鍵、值……」，叫做**屬性**（attribute）。
- 每行開頭自動加上時間，所以每次執行都不同。
- 預設的輸出位置是**標準錯誤**（`os.Stderr`），不是 `os.Stdout`。日誌和程式的正常輸出分開，是很常見的慣例。

### 日誌層級

`slog` 有四個層級，由輕到重：

| 函式 | 層級 | 用在 |
| --- | --- | --- |
| `slog.Debug` | `DEBUG` | 開發時的除錯細節 |
| `slog.Info` | `INFO` | 一般的事件紀錄 |
| `slog.Warn` | `WARN` | 不正常但還能繼續 |
| `slog.Error` | `ERROR` | 出錯了 |

預設只會輸出 `INFO` 以上，`Debug` 的內容會被丟掉。這樣開發時可以盡量寫 `Debug`，上線時不會洗版。

### 自己建立 Logger：`TextHandler`

`slog.New(handler)` 建立一個 `*slog.Logger`。handler 決定日誌**長什麼樣子、寫到哪裡**。`slog.NewTextHandler(w, 選項)` 輸出 `key=value` 格式，`w` 是任何 `io.Writer`。

接下來的範例為了讓輸出可以重現，用 `HandlerOptions` 的 `ReplaceAttr` 把時間欄位拿掉。實際使用時，時間當然要保留：

```go
package main

import (
	"log/slog"
	"os"
)

func main() {
	opts := &slog.HandlerOptions{
		Level: slog.LevelDebug,
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey && len(groups) == 0 {
				return slog.Attr{}
			}
			return a
		},
	}
	logger := slog.New(slog.NewTextHandler(os.Stdout, opts))

	logger.Debug("讀取設定", "path", "config.json")
	logger.Info("使用者登入", "user", "andy", "admin", false)
	logger.Warn("回應很慢", "ms", 1250, "path", "/api/orders")
}
```

執行結果：

```text
level=DEBUG msg=讀取設定 path=config.json
level=INFO msg=使用者登入 user=andy admin=false
level=WARN msg=回應很慢 ms=1250 path=/api/orders
```

- `Level: slog.LevelDebug` 把最低層級調成 `DEBUG`，所以這次 `Debug` 也印出來了。
- `ReplaceAttr` 是一個函式（第 6 章的函式當值），每個屬性輸出前都會經過它。回傳空的 `slog.Attr{}` 就表示「這個屬性不要輸出」。`slog.TimeKey` 是時間欄位的鍵名 `"time"`。
- 訊息或值裡有空白時，`TextHandler` 會自動加上引號，下面 `With` 的範例會看到。

### 換成 JSON：`JSONHandler`

要交給日誌收集系統分析時，JSON 格式比較好處理。只要把 `NewTextHandler` 換成 `NewJSONHandler`，其他程式碼都不用改：

```go
package main

import (
	"errors"
	"log/slog"
	"os"
)

func main() {
	opts := &slog.HandlerOptions{
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey && len(groups) == 0 {
				return slog.Attr{}
			}
			return a
		},
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, opts))

	err := errors.New("餘額不足")
	logger.Error("付款失敗",
		slog.Int("order_id", 1001),
		slog.String("method", "card"),
		slog.Any("err", err),
	)
}
```

執行結果：

```text
{"level":"ERROR","msg":"付款失敗","order_id":1001,"method":"card","err":"餘額不足"}
```

`slog.Int`、`slog.String`、`slog.Any` 等函式明確地建立一個屬性。和「鍵、值」交錯的寫法效果相同，但不會發生鍵值數量對不上的錯誤（`go vet` 也會幫你檢查交錯寫法有沒有漏寫）。

### 共用屬性：`With` 與 `Group`

同一個請求裡的每一行日誌，通常都想帶著同樣的資訊，例如請求編號。`logger.With(...)` 回傳一個新的 Logger，之後每一行都會自動加上這些屬性：

```go
package main

import (
	"log/slog"
	"os"
)

func main() {
	opts := &slog.HandlerOptions{
		ReplaceAttr: func(groups []string, a slog.Attr) slog.Attr {
			if a.Key == slog.TimeKey && len(groups) == 0 {
				return slog.Attr{}
			}
			return a
		},
	}
	logger := slog.New(slog.NewTextHandler(os.Stdout, opts))

	reqLog := logger.With("request_id", "a1b2")
	reqLog.Info("收到請求", slog.Group("user", "id", 42, "name", "Andy"))
	reqLog.Info("處理完成", "status", 200)
	logger.Info("沒有 request_id 的 Logger")
}
```

執行結果：

```text
level=INFO msg=收到請求 request_id=a1b2 user.id=42 user.name=Andy
level=INFO msg=處理完成 request_id=a1b2 status=200
level=INFO msg="沒有 request_id 的 Logger"
```

`slog.Group` 把幾個屬性歸成一組，`TextHandler` 用 `user.id` 這種點號表示，`JSONHandler` 則會輸出成巢狀物件。

### 設成預設 Logger

`slog.SetDefault(logger)` 可以把自己建的 Logger 設為預設，之後直接呼叫 `slog.Info` 就會用它。通常在 `main` 一開始設定一次。第 10 章的 `context` 也能搭配：`logger.InfoContext(ctx, ...)` 讓 handler 有機會從 context 取出資訊。

## 重點整理

- `slog.Info(訊息, 鍵, 值, ...)` 輸出結構化日誌；預設寫到標準錯誤，並自動加上時間。
- 四個層級 `Debug`、`Info`、`Warn`、`Error`，預設只輸出 `Info` 以上，可用 `HandlerOptions.Level` 調整。
- `slog.New(slog.NewTextHandler(w, opts))` 輸出 `key=value`，換成 `NewJSONHandler` 就輸出 JSON。
- `HandlerOptions.ReplaceAttr` 可以修改或移除屬性（例如移除時間）；`logger.With` 加上共用屬性，`slog.Group` 把屬性分組。
