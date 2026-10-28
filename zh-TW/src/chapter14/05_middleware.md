# middleware

## 本集目標

會寫「包住 handler」的 middleware，用它替每個請求記錄日誌、攔下 `panic`，並知道包裝的順序會影響結果。

## 正文

### 每個請求都要做的事

有些事情每個 handler 都要做：記錄是誰請求了什麼、出錯時不要讓整個請求爆掉、檢查登入狀態……如果每個 handler 都自己寫一遍，既重複又容易漏掉。

**middleware**（中介層）的做法是：寫一個函式，**收一個 `Handler`，回傳一個新的 `Handler`**。新的 handler 先做自己的事，再呼叫原本的 handler，像洋蔥一樣一層包一層：

```go,ignore
func(next http.Handler) http.Handler
```

### 範例：日誌與 recover

```go
package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
)

func show(h http.Handler, method, target string) {
	req := httptest.NewRequest(method, target, nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s", method, target, rec.Code, rec.Body.String())
}

// statusRecorder 包住 ResponseWriter，記下第一次最終回應的狀態碼。
type statusRecorder struct {
	http.ResponseWriter
	status     int
	wroteFinal bool
}

func (s *statusRecorder) WriteHeader(code int) {
	if s.wroteFinal {
		return
	}
	if code >= 100 && code < 200 {
		s.ResponseWriter.WriteHeader(code)
		return
	}
	s.status = code
	s.wroteFinal = true
	s.ResponseWriter.WriteHeader(code)
}

func (s *statusRecorder) Write(p []byte) (int, error) {
	if !s.wroteFinal {
		s.WriteHeader(http.StatusOK)
	}
	return s.ResponseWriter.Write(p)
}

func logging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		fmt.Printf("[log] %s %s %d\n", r.Method, r.URL.Path, rec.status)
	})
}

func recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		defer func() {
			if v := recover(); v != nil {
				fmt.Println("[recover] 攔下 panic：", v)
				if !rec.wroteFinal {
					http.Error(rec, "伺服器內部錯誤", http.StatusInternalServerError)
				}
			}
		}()
		next.ServeHTTP(rec, r)
	})
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "哈囉")
	})
	mux.HandleFunc("GET /boom", func(w http.ResponseWriter, r *http.Request) {
		var m map[string]int
		m["x"] = 1
	})

	handler := logging(recoverer(mux))

	show(handler, "GET", "/hello")
	show(handler, "GET", "/nothing")
	show(handler, "GET", "/boom")
}
```

執行結果：

```text
[log] GET /hello 200
GET /hello → 200 哈囉
[log] GET /nothing 404
GET /nothing → 404 404 page not found
[recover] 攔下 panic： assignment to entry in nil map
[log] GET /boom 500
GET /boom → 500 伺服器內部錯誤
```

handler 結束或 `panic` 被攔下後，會印出 `[log]` 那一行，再由 `show` 印出回應。`/boom` 的 handler 對 `nil` map 賦值而 `panic`；它還沒寫出回應，所以 `recoverer` 能送出 `500`。

### 一步一步看

**`logging`** 回傳的是用 `http.HandlerFunc` 轉型的匿名函式（第 3 集），它是一個閉包（第 6 章），抓住了 `next`。它先呼叫 `next.ServeHTTP` 讓真正的 handler 做事，結束後再印出日誌。

要記錄狀態碼有點麻煩：handler 透過 `w` 寫出回應，`logging` 看不到。所以我們用 `statusRecorder` **包住** `w`：它嵌入了 `http.ResponseWriter`（第 3 章的嵌入），並改寫 `WriteHeader` 和 `Write`。

`WriteHeader` 只記錄第一次最終狀態（`2xx`～`5xx`），並把 `wroteFinal` 設為 `true`，表示已提交最終標頭。之後再呼叫也不會改變它：先送 `201` 再送 `500`，實際狀態與日誌都是 `201`。`1xx` 是資訊性標頭，例如 `103 Early Hints`；它會照常往外傳，但還不算最終狀態。

handler 也可能直接用 `fmt.Fprintln(w, ...)` 寫本文。這會呼叫 `Write`，若還沒提交最終標頭，就隱含使用 `200`；所以 `Write` 也要記錄這件事。即使之後再呼叫 `WriteHeader(500)`，狀態仍是 `200`。如果 handler 正常結束時完全沒寫回應，伺服器也會使用 `200`，所以 `status` 的預設值設為 `http.StatusOK`。這個範例只處理一般 HTTP 回應，不處理串流或協定切換。

實務上日誌會用第 12 章的 `slog`，並記錄花了多少時間（用 `time.Since`）。這裡用 `fmt.Printf` 是為了讓輸出每次都一樣。

**`recoverer`** 用 `defer` 加 `recover`（第 5 章）攔下 handler 裡的 `panic`，並記錄錯誤。它也用自己的 `statusRecorder` 包住 `w`，所以不依賴外層一定有 `logging`。只有 `wroteFinal` 還是 `false` 時，才能用 `http.Error` 送出 `500`；只送過資訊性標頭也還能送出 `500`。

如果 handler 已寫出部分本文才 `panic`，例如先寫出 `partial`，回應就已經以 `200` 開始，不能撤回。這時只記錄 `panic`，保留原本的狀態與本文，不再追加「伺服器內部錯誤」假裝能取代原回應。這也不保證原本文是完整的。其實就算沒有 `recoverer`，`net/http` 也會攔下 handler 的 `panic`、記錄錯誤並中斷那條連線或 HTTP/2 串流，伺服器不會整個掛掉；但這不等於會送出 `500`。

### 包裝順序

`logging(recoverer(mux))` 的意思是：請求先進 `logging`，再進 `recoverer`，最後才到 `mux`；回應則反過來一層一層出去。所以 `recoverer` 在尚未提交回應時寫出的 `500`，也能被外層的 `logging` 記錄到。

如果反過來寫成 `recoverer(logging(mux))`，`panic` 會直接穿過 `logging`（它的 `fmt.Printf` 來不及執行），日誌就少了這一筆。一般原則是：日誌放最外層，`recover` 緊接在它裡面。

middleware 也可以只包住某些路由，例如 `mux.Handle("GET /admin/", requireLogin(adminHandler))`，只有後台需要檢查登入。

### 標準庫的 middleware：`CrossOriginProtection`

Go 1.25 起，標準庫內建一個防範 CSRF（跨站請求偽造）攻擊的 middleware：`http.NewCrossOriginProtection().Handler(mux)`。它會拒絕「從別的網站發出」的 `POST` 等會修改資料的請求，`GET` 則一律放行。瀏覽器會在請求加上 `Sec-Fetch-Site` 標頭說明來源，我們手動設定它來模擬：

```go
package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("POST /transfer", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "轉帳完成")
	})
	handler := http.NewCrossOriginProtection().Handler(mux)

	for _, site := range []string{"same-origin", "cross-site"} {
		req := httptest.NewRequest("POST", "/transfer", nil)
		req.Header.Set("Sec-Fetch-Site", site)
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, req)
		fmt.Printf("%s → %d %s", site, rec.Code, rec.Body.String())
	}
}
```

執行結果：

```text
same-origin → 200 轉帳完成
cross-site → 403 cross-origin request detected from Sec-Fetch-Site header
```

同一個網站送來的請求通過，別的網站送來的被擋成 `403 Forbidden`。它的形狀跟我們自己寫的 middleware 一模一樣：收一個 `Handler`，回傳一個 `Handler`。

## 重點整理

- middleware 的形狀是 `func(next http.Handler) http.Handler`，先做自己的事，再呼叫 `next.ServeHTTP`。
- 用 `http.HandlerFunc` 包一個閉包當回傳值；覆寫 `WriteHeader` 和 `Write`，記錄第一次最終狀態及寫本文時隱含的 `200`，不把資訊性標頭當成最終狀態。
- `recover` middleware 攔下並記錄 `panic`；只有尚未提交最終標頭時才送出 `500`，否則保留原回應，不追加錯誤本文。
- 包裝順序就是請求經過的順序：`logging(recoverer(mux))`，日誌在最外層。
- Go 1.25 起的 `http.NewCrossOriginProtection()` 是內建的 CSRF 防護 middleware。
