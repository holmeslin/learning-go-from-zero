# HTTP client

## 本集目標

換到另一邊，用 Go 送出 HTTP 請求：建立有逾時的 `http.Client`、用 `http.NewRequestWithContext` 帶上 context、檢查狀態碼，並且記得關閉 `resp.Body`。

## 正文

### 先準備一台伺服器

要練習送請求，總得有個對象。下面的範例用 `httptest.NewServer` 在程式裡**真的**開一台伺服器（只有這支程式自己連得到），`srv.URL` 是它的網址，例如 `http://127.0.0.1:56123`，埠號每次不同。這也是先照抄的寫法，第 9 集會正式介紹。

### 送出請求、讀取 JSON

```go
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"time"
)

type Weather struct {
	City string `json:"city"`
	Temp int    `json:"temp"`
}

func fetchWeather(ctx context.Context, client *http.Client, baseURL, city string) (Weather, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, baseURL+"/weather/"+city, nil)
	if err != nil {
		return Weather{}, err
	}
	req.Header.Set("Accept", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return Weather{}, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return Weather{}, fmt.Errorf("伺服器回應 %s", resp.Status)
	}
	var w Weather
	if err := json.NewDecoder(resp.Body).Decode(&w); err != nil {
		return Weather{}, err
	}
	return w, nil
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /weather/taipei", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"city":"台北","temp":31}`)
	})
	srv := httptest.NewServer(mux)
	defer srv.Close()

	client := &http.Client{Timeout: 10 * time.Second}
	ctx := context.Background()
	for _, city := range []string{"taipei", "tokyo"} {
		w, err := fetchWeather(ctx, client, srv.URL, city)
		if err != nil {
			fmt.Println(city, "失敗：", err)
			continue
		}
		fmt.Printf("%s 現在 %d 度\n", w.City, w.Temp)
	}
}
```

執行結果：

```text
台北 現在 31 度
tokyo 失敗： 伺服器回應 404 Not Found
```

### 一步一步看

**`http.Client{Timeout: 10 * time.Second}`**：`Client` 是送請求的物件，`Timeout` 是整個請求（連線、送出、等回應、讀完內容）最多能花多久。**一定要設定它**。`http.Get` 這類方便函式用的是 `http.DefaultClient`，它**沒有**逾時：對方伺服器如果卡住不回，你的程式就會永遠等下去。`Client` 可以重複使用，也能同時被多個 goroutine 使用，建立一個就好。

**`http.NewRequestWithContext(ctx, 方法, 網址, 內容)`**：建立請求並綁上 context（第 10 章）。context 被取消時，請求會立刻中止。如果你的程式本身是伺服器，就把 handler 收到的 `r.Context()` 傳進來，使用者斷線時，你替他發出的請求也會跟著停下。`req.Header.Set` 可以加上標頭。最後用 `client.Do(req)` 送出。

**`defer resp.Body.Close()`**：只要 `err == nil`，就**一定要**關閉 `resp.Body`。不關的話，底層的網路連線不會被回收，程式跑久了會用光連線或記憶體。習慣是拿到 `resp` 之後馬上寫這行。

**檢查 `resp.StatusCode`**：伺服器回 `404` 或 `500` 時，`client.Do` **不會**回傳錯誤，因為就 HTTP 來說，請求確實成功送達、也收到回應了。所以要自己檢查狀態碼。`resp.Status` 是像 `"404 Not Found"` 這樣的文字。

### 逾時真的會發生

把伺服器故意弄慢，看看兩種逾時的效果：

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"time"
)

func main() {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-time.After(5 * time.Second):
			fmt.Fprintln(w, "終於好了")
		case <-r.Context().Done():
		}
	}))
	defer srv.Close()

	client := &http.Client{Timeout: 100 * time.Millisecond}
	_, err := client.Get(srv.URL)
	fmt.Println("Client.Timeout：", errors.Is(err, context.DeadlineExceeded))

	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, srv.URL, nil)
	if err != nil {
		fmt.Println(err)
		return
	}
	_, err = client.Do(req)
	fmt.Println("context 逾時：", errors.Is(err, context.DeadlineExceeded))
}
```

執行結果：

```text
Client.Timeout： true
context 逾時： true
```

兩種寫法都讓請求在時間到時放棄，錯誤都可以用 `errors.Is(err, context.DeadlineExceeded)` 判斷。印出 `err` 本身會看到像 `Get "http://127.0.0.1:56123": context deadline exceeded (Client.Timeout exceeded while awaiting headers)` 這樣的訊息，裡面的埠號每次不同，所以範例只印判斷結果。

`Client.Timeout` 是這個 client 所有請求的上限；context 則可以針對單一次請求設定，兩者同時存在時，先到的那個生效。

伺服器的 handler 裡用 `select` 等 `r.Context().Done()`：客戶端放棄後，伺服器這邊的 context 也會被取消，handler 就不用白白等滿 5 秒。

### 送出 JSON

要送 `POST` 請求，把內容放在第四個參數，並設定 `Content-Type`：

```go,ignore
body, err := json.Marshal(item)
// 處理 err
req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
// 處理 err
req.Header.Set("Content-Type", "application/json")
resp, err := client.Do(req)
```

之後的處理（檢查錯誤、`defer resp.Body.Close()`、檢查狀態碼）跟 `GET` 完全一樣。

## 重點整理

- 自己建立 `&http.Client{Timeout: ...}`，**一定要設逾時**；不要在正式程式裡用沒有逾時的 `http.Get`。
- 用 `http.NewRequestWithContext` 建立請求，讓 context 能中止它，再用 `client.Do(req)` 送出。
- 拿到 `resp` 後立刻 `defer resp.Body.Close()`。
- `404`、`500` 不會變成 `err`，要自己檢查 `resp.StatusCode`。
- 逾時的錯誤可以用 `errors.Is(err, context.DeadlineExceeded)` 判斷。
