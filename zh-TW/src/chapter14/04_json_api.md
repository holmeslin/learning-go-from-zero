# JSON API

## 本集目標

寫出一個收 JSON、回 JSON 的小型 API：解碼請求內容、檢查資料、用正確的狀態碼和 `Content-Type` 回應，出錯時用 `http.Error`。

## 正文

### API 是給程式看的網頁

前幾集回傳的是給人看的文字。**API** 回傳的則是給程式看的資料，最常見的格式是 JSON（第 12 章）。慣例是：

- 請求和回應的內容都是 JSON，回應要設定標頭 `Content-Type: application/json`。
- 用狀態碼表達結果：`200 OK` 成功、`201 Created` 新增成功、`400 Bad Request` 請求內容有錯、`404 Not Found` 找不到。

### 完整範例：商品 API

我們做一個存在記憶體裡的商品清單，提供三個路由：新增、列出全部、查單一商品。為了能送出請求內容，這次的小工具叫 `send`，多了一個 `body` 參數，並且印出 `Content-Type`：

```go
package main

import (
	"cmp"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"slices"
	"strconv"
	"strings"
	"sync"
)

func send(h http.Handler, method, target, body string) {
	req := httptest.NewRequest(method, target, strings.NewReader(body))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	fmt.Printf("%s %s → %d %s\n%s", method, target, rec.Code, rec.Header().Get("Content-Type"), rec.Body.String())
}

type Item struct {
	ID    int    `json:"id"`
	Name  string `json:"name"`
	Price int    `json:"price"`
}

type store struct {
	mu     sync.Mutex
	items  map[int]Item
	nextID int
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v)
}

func (s *store) create(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	var in struct {
		Name  string `json:"name"`
		Price int    `json:"price"`
	}
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "JSON 格式錯誤："+err.Error(), http.StatusBadRequest)
		return
	}
	if in.Name == "" || in.Price < 0 {
		http.Error(w, "name 不能空白，price 不能是負數", http.StatusBadRequest)
		return
	}

	s.mu.Lock()
	s.nextID++
	item := Item{ID: s.nextID, Name: in.Name, Price: in.Price}
	s.items[item.ID] = item
	s.mu.Unlock()

	writeJSON(w, http.StatusCreated, item)
}

func (s *store) list(w http.ResponseWriter, r *http.Request) {
	s.mu.Lock()
	items := make([]Item, 0, len(s.items))
	for _, item := range s.items {
		items = append(items, item)
	}
	s.mu.Unlock()

	slices.SortFunc(items, func(a, b Item) int { return cmp.Compare(a.ID, b.ID) })
	writeJSON(w, http.StatusOK, items)
}

func (s *store) get(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.Atoi(r.PathValue("id"))
	if err != nil {
		http.Error(w, "id 必須是整數", http.StatusBadRequest)
		return
	}
	s.mu.Lock()
	item, ok := s.items[id]
	s.mu.Unlock()
	if !ok {
		http.Error(w, "找不到這個商品", http.StatusNotFound)
		return
	}
	writeJSON(w, http.StatusOK, item)
}

func main() {
	s := &store{items: map[int]Item{}}
	mux := http.NewServeMux()
	mux.HandleFunc("POST /items", s.create)
	mux.HandleFunc("GET /items", s.list)
	mux.HandleFunc("GET /items/{id}", s.get)

	send(mux, "POST", "/items", `{"name":"珍珠奶茶","price":60}`)
	send(mux, "POST", "/items", `{"name":"雞排","price":85}`)
	send(mux, "GET", "/items", "")
	send(mux, "GET", "/items/2", "")
	send(mux, "GET", "/items/9", "")
	send(mux, "GET", "/items/abc", "")
	send(mux, "POST", "/items", `{"name":"","price":10}`)
	send(mux, "POST", "/items", `{"name":`)
}
```

執行結果：

```text
POST /items → 201 application/json
{"id":1,"name":"珍珠奶茶","price":60}
POST /items → 201 application/json
{"id":2,"name":"雞排","price":85}
GET /items → 200 application/json
[{"id":1,"name":"珍珠奶茶","price":60},{"id":2,"name":"雞排","price":85}]
GET /items/2 → 200 application/json
{"id":2,"name":"雞排","price":85}
GET /items/9 → 404 text/plain; charset=utf-8
找不到這個商品
GET /items/abc → 400 text/plain; charset=utf-8
id 必須是整數
POST /items → 400 text/plain; charset=utf-8
name 不能空白，price 不能是負數
POST /items → 400 text/plain; charset=utf-8
JSON 格式錯誤：unexpected EOF
```

### 讀取請求：解碼 JSON

`r.Body` 是請求的內容，型別是 `io.ReadCloser`（可以讀、也可以關閉的 `io.Reader`）。`json.NewDecoder(r.Body).Decode(&in)` 直接從它讀出 JSON、填進 `in`。這裡的 `in` 用匿名 struct（第 3 章），只放我們願意讓使用者給的欄位：使用者不能自己指定 `id`。

收到的資料一定要**檢查**。JSON 格式錯了、名稱空白、價格是負數，都回 `400`，並說明哪裡錯。不要相信從網路上來的任何東西。

最前面那行 `http.MaxBytesReader` 限制請求內容最多 1 MB（`1<<20` 就是 1048576）。沒有它的話，別人送來一個超大的請求，伺服器就會一直讀下去、吃光記憶體。

### 回應錯誤：`http.Error`

`http.Error(w, 訊息, 狀態碼)` 一次做完三件事：設定純文字的 `Content-Type`、寫出狀態碼、寫出訊息。寫完記得 `return`，否則程式會繼續往下執行。狀態碼建議用 `http.StatusBadRequest` 這類常數，比直接寫 `400` 好讀。

很多 API 的錯誤也會用 JSON 回傳，例如 `{"error":"找不到這個商品"}`，用上面的 `writeJSON` 就能做到。這裡為了簡單，先用 `http.Error`。

### 寫出回應：順序很重要

`writeJSON` 的三行順序不能換：

1. `w.Header().Set(...)` 設定標頭。
2. `w.WriteHeader(status)` 送出狀態碼。
3. 寫入內容（這裡用 `json.NewEncoder(w).Encode(v)`，它會在 JSON 後面加一個換行）。

一旦送出狀態碼，標頭就跟著送出去了，之後再改標頭也沒有用。如果你沒呼叫 `WriteHeader` 就直接寫內容，Go 會自動用 `200`。

### 並行安全與方法值

`store` 的方法會被很多請求同時呼叫，所以讀寫 `items` 和 `nextID` 前後都用 `s.mu` 鎖起來（第 9 章的 `sync.Mutex`）。注意我們在鎖住的範圍內只做最少的事，排序和寫回應都在解鎖之後。

`mux.HandleFunc("POST /items", s.create)` 傳的是**方法值**：`s.create` 已經綁好了 `s`，形狀剛好是 `func(w, r)`，所以可以直接當 handler。

## 重點整理

- 用 `json.NewDecoder(r.Body).Decode(&v)` 解碼請求，並用 `http.MaxBytesReader` 限制大小。
- 收到的資料一定要檢查，有錯就用 `http.Error(w, 訊息, 狀態碼)` 回應並 `return`。
- 回應 JSON 的順序：設定 `Content-Type` 標頭 → `WriteHeader(狀態碼)` → 寫入內容。
- 用 `http.StatusCreated` 等常數表達結果：200 成功、201 新增、400 請求錯誤、404 找不到。
- 共用資料用 `sync.Mutex` 保護；方法值可以直接當 handler。
