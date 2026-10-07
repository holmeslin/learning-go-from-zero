# `ServeMux` 路由

## 本集目標

用 Go 1.22 起的路由寫法（像 `"GET /items/{id}"`）把不同的方法和路徑分給不同的 handler，並用 `r.PathValue` 取出路徑裡的參數。

## 正文

### 自己的路由表

上一集的 `http.HandleFunc` 把 handler 登記在一個全域的預設路由表。實務上我們通常自己建立一個 **`http.ServeMux`**（路由器），比較清楚、也不會被其他套件偷偷加東西進去：

```go,ignore
mux := http.NewServeMux()
mux.HandleFunc("GET /items/{id}", getItem)
http.ListenAndServe(":8080", mux)
```

`ListenAndServe` 的第二個參數從 `nil` 換成 `mux`，就會用我們的路由表。

### 不開伺服器也能試：先照抄的 `show`

為了讓範例能直接執行、每次結果都一樣，這一章會用一個小工具函式 `show`，它用 `net/http/httptest` 套件**假造**一個請求交給路由器，再印出回應。請先照抄，第 9 集會正式介紹 `httptest`：

```go,ignore
func show(h http.Handler, method, target string) {
	req := httptest.NewRequest(method, target, nil)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s", method, target, rec.Code, rec.Body.String())
}
```

`rec.Code` 是狀態碼，`rec.Body.String()` 是回應內容。

### 方法、路徑與萬用字元

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
	if allow := rec.Header().Get("Allow"); allow != "" {
		fmt.Println("  Allow:", allow)
	}
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "首頁")
	})
	mux.HandleFunc("GET /items", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "所有商品")
	})
	mux.HandleFunc("POST /items", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "新增商品")
	})
	mux.HandleFunc("GET /items/{id}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "商品", r.PathValue("id"))
	})
	mux.HandleFunc("GET /items/new", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "新增商品的表單")
	})
	mux.HandleFunc("GET /files/{path...}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "檔案", r.PathValue("path"))
	})

	show(mux, "GET", "/")
	show(mux, "GET", "/items")
	show(mux, "POST", "/items")
	show(mux, "GET", "/items/42")
	show(mux, "GET", "/items/new")
	show(mux, "GET", "/files/docs/a.txt")
	show(mux, "DELETE", "/items/42")
	show(mux, "GET", "/nothing")
	show(mux, "GET", "/items/42/extra")
}
```

執行結果：

```text
GET / → 200 首頁
GET /items → 200 所有商品
POST /items → 200 新增商品
GET /items/42 → 200 商品 42
GET /items/new → 200 新增商品的表單
GET /files/docs/a.txt → 200 檔案 docs/a.txt
DELETE /items/42 → 405 Method Not Allowed
  Allow: GET, HEAD
GET /nothing → 404 404 page not found
GET /items/42/extra → 404 404 page not found
```

這裡的 `show` 多了兩行，用來印出 `Allow` 標頭，等一下會用到。路由的寫法是「`[方法 ]路徑`」：

- **方法**寫在最前面，後面加一個空白，例如 `"POST /items"` 只接受 `POST`。不寫方法就接受所有方法。`GET` 也會順便接受 `HEAD`。
- **`{id}`** 是萬用字元，符合路徑中的一整段。handler 裡用 `r.PathValue("id")` 取出實際的值，例如 `/items/42` 拿到字串 `"42"`。
- **`{path...}`** 加上三個點，會符合「剩下的全部」，包含斜線，所以拿到 `docs/a.txt`。
- **`/{$}`** 只符合剛好是 `/` 的路徑。如果只寫 `"GET /"`，它會符合**所有**沒被別人接走的路徑（上一集就是這樣）。

注意 `/items/42/extra` 得到 404：`{id}` 只符合一段，不會吃掉後面的斜線。

### 優先順序：越具體的越優先

`/items/new` 同時符合 `"GET /items/{id}"` 和 `"GET /items/new"`，結果交給了後者。規則是**越具體的路由越優先**：`/items/new` 只符合一個路徑，`/items/{id}` 符合很多，所以前者比較具體。這跟登記的先後順序無關。

如果兩個路由一樣具體、又會符合同樣的請求，例如 `"GET /items/{id}"` 和 `"GET /items/{name}"`，Go 沒辦法決定，登記第二個時就會直接 `panic`，告訴你這兩個路由衝突。這是好事：錯誤在程式一啟動時就會被發現。

### 404 與 405

- 路徑完全沒有對應的路由：`404 Not Found`。
- 路徑對得上、但方法不對（`DELETE /items/42`，而我們只登記了 `GET`）：`405 Method Not Allowed`，而且 `ServeMux` 會自動在 `Allow` 標頭列出允許的方法 `GET, HEAD`。

這些都是 `ServeMux` 自動處理的，我們不用自己寫。

## 重點整理

- 用 `http.NewServeMux()` 建立自己的路由表，傳給 `http.ListenAndServe` 的第二個參數。
- 路由寫成 `"方法 路徑"`，例如 `"GET /items/{id}"`；`r.PathValue("id")` 取出萬用字元的值。
- `{name...}` 符合剩下的全部路徑，`/{$}` 只符合剛好 `/`。
- 越具體的路由越優先；一樣具體又重疊的路由，登記時會 `panic`。
- 路徑不存在回 404；方法不對回 405 並附上 `Allow` 標頭。
