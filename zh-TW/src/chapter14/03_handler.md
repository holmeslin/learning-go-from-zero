# `Handler` 與 `HandlerFunc`

## 本集目標

認識 `net/http` 的核心介面 `http.Handler`，知道 `HandleFunc` 和 `Handle` 的差別，以及 `http.HandlerFunc` 怎麼把普通函式變成 `Handler`。

## 正文

### 只有一個方法的介面

`net/http` 裡最重要的型別是這個介面：

```go,ignore
type Handler interface {
	ServeHTTP(ResponseWriter, *Request)
}
```

任何型別只要有 `ServeHTTP(w, r)` 這個方法，就是一個 `Handler`（第 4 章的隱式實作）。`ServeMux` 本身也是 `Handler`，所以上一集的 `show` 才能呼叫 `mux.ServeHTTP`。

### 自己的型別當 handler

用 `mux.Handle` 登記一個 `Handler` 值：

```go
package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
)

func show(h http.Handler, method, target string) {
	req := httptest.NewRequest(method, target, nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s", method, target, rec.Code, rec.Body.String())
}

type greeter struct {
	greeting string
}

func (g greeter) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%s，%s\n", g.greeting, r.PathValue("name"))
}

type visitCounter struct {
	n atomic.Int64
}

func (c *visitCounter) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "你是第 %d 位訪客\n", c.n.Add(1))
}

func main() {
	mux := http.NewServeMux()
	mux.Handle("GET /zh/{name}", greeter{greeting: "哈囉"})
	mux.Handle("GET /en/{name}", greeter{greeting: "Hello"})
	mux.Handle("GET /visits", &visitCounter{})

	show(mux, "GET", "/zh/小明")
	show(mux, "GET", "/en/Andy")
	show(mux, "GET", "/visits")
	show(mux, "GET", "/visits")
}
```

執行結果：

```text
GET /zh/小明 → 200 哈囉，小明
GET /en/Andy → 200 Hello，Andy
GET /visits → 200 你是第 1 位訪客
GET /visits → 200 你是第 2 位訪客
```

- `greeter` 帶著一個欄位 `greeting`，同一個型別可以用不同的設定登記兩次。這是 struct handler 的好處：handler 需要的東西（設定、資料庫連線）放在欄位裡。
- `visitCounter` 要修改計數，所以用指標接收者，登記時傳 `&visitCounter{}`。

還記得上一集說過每個請求在自己的 goroutine 執行嗎？很多請求可能**同時**呼叫 `ServeHTTP`，所以計數器用第 9 章的 `atomic.Int64`，而不是普通的 `int`，否則會發生 data race。

### `HandlerFunc`：讓函式變成 `Handler`

前幾集用的 `mux.HandleFunc` 收的是函式，不是 `Handler`。它是怎麼辦到的？秘密是 `net/http` 裡這個型別：

```go,ignore
type HandlerFunc func(ResponseWriter, *Request)

func (f HandlerFunc) ServeHTTP(w ResponseWriter, r *Request) {
	f(w, r)
}
```

`HandlerFunc` 是一個**函式型別**（第 3 章的自訂型別、第 6 章的函式是值），它的 `ServeHTTP` 方法只做一件事：呼叫自己。所以任何長得像 `func(w, r)` 的函式，轉型成 `http.HandlerFunc` 之後就有了 `ServeHTTP`，也就是一個 `Handler`。`mux.HandleFunc(p, f)` 其實就等於 `mux.Handle(p, http.HandlerFunc(f))`。

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

func ping(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "pong")
}

func main() {
	var h http.Handler = http.HandlerFunc(ping)
	show(h, "GET", "/ping")
}
```

執行結果：

```text
GET /ping → 200 pong
```

`ping` 只是普通函式，沒有任何方法；轉型之後就能放進 `http.Handler` 變數，直接交給 `show`。

### 什麼時候用哪個

- 處理邏輯簡單、不需要額外資料：寫函式，用 `HandleFunc`。
- handler 需要設定或共用資源：寫成 struct，用 `Handle`；或者把資源放在 struct 裡，把**方法值**（附錄一）傳給 `HandleFunc`，例如 `mux.HandleFunc("GET /items", app.listItems)`，下一集就會這樣寫。

`Handler` 介面是整個 `net/http` 的共同語言：`ServeMux` 是 `Handler`、你的程式是 `Handler`，第 5 集的 middleware 則是「收一個 `Handler`、回傳一個 `Handler`」。

## 重點整理

- `http.Handler` 是只有 `ServeHTTP(w, r)` 一個方法的介面；`ServeMux` 也是 `Handler`。
- `mux.Handle` 登記 `Handler` 值，struct handler 可以把設定放在欄位裡。
- `http.HandlerFunc` 是函式型別，它的 `ServeHTTP` 呼叫自己，讓普通函式變成 `Handler`；`HandleFunc` 就是靠它。
- handler 會被多個 goroutine 同時呼叫，修改共用狀態要用 `atomic` 或 `sync.Mutex`。
