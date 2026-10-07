# 為什麼需要 context

## 本集目標

知道 context 要解決什麼問題，認識 `Context` 介面的四個方法，以及當作起點的 `context.Background()` 和 `context.TODO()`。

## 正文

### 一層一層的工作

想像一個「訂單查詢」功能：收到請求後，先查會員資料，再查訂單，再去物流系統查出貨狀態。每一步都可能很慢，有些步驟還會開 goroutine 同時去查。

這時候會冒出幾個需求：

- 使用者等不及關掉網頁了，底下還在查的工作應該全部停下來，不要白做。
- 整個請求最多只能花 2 秒，每一層都要知道「最晚什麼時候要放棄」。
- 有些資訊（例如這次請求的編號）每一層記錄日誌時都想用。

第 9 章我們用一個 `done` channel 通知 goroutine 停止，概念上已經很接近了。但如果每個專案、每個套件都自己發明一套 `done` channel 的傳法，函式之間就很難接起來。`context` 套件把這件事標準化：大家都傳同一種東西，叫做 `context.Context`。

### `Context` 是一個介面

`context.Context` 是一個介面（第 4 章），裡面有四個方法：

```go,ignore
type Context interface {
	Deadline() (deadline time.Time, ok bool)
	Done() <-chan struct{}
	Err() error
	Value(key any) any
}
```

逐一看：

- `Done()`：回傳一個只能接收的 channel（第 9 章的單向 channel）。context 被取消時，這個 channel 會被關閉，所有在等它的人都會同時收到通知。
- `Err()`：還沒被取消時回傳 `nil`；取消之後回傳原因，例如 `context.Canceled`（被取消）或 `context.DeadlineExceeded`（超過時間）。
- `Deadline()`：如果有設定截止時間，回傳那個時間和 `true`。
- `Value(key)`：取出附在 context 上的資料，第 4 集會介紹。

我們幾乎不會自己實作這個介面，而是用 `context` 套件提供的函式來產生。

### 起點：`Background` 與 `TODO`

所有 context 都要從某個起點長出來。最常用的起點是 `context.Background()`，它是一個「空的」context：永遠不會被取消、沒有截止時間、也沒有任何資料。

```go
package main

import (
	"context"
	"fmt"
)

func main() {
	ctx := context.Background()
	fmt.Println(ctx)
	fmt.Println(ctx.Err())
	fmt.Println(ctx.Done() == nil)

	_, ok := ctx.Deadline()
	fmt.Println(ok)

	todo := context.TODO()
	fmt.Println(todo)
}
```

執行結果：

```text
context.Background
<nil>
true
false
context.TODO
```

- `ctx.Err()` 是 `nil`，因為它沒被取消過。
- `ctx.Done()` 是 `nil` channel。第 9 章說過，從 `nil` channel 接收會永遠等下去，剛好代表「永遠不會被取消」。
- `Deadline()` 的 `ok` 是 `false`：沒有截止時間。

`context.TODO()` 的行為和 `Background()` 一模一樣，差別只在**意思**：

- `Background()`：我很清楚這裡就是最上層，例如 `main` 函式或測試的開頭。
- `TODO()`：這裡應該要有人傳 context 進來，但我還沒改好，先放一個佔位。日後搜尋 `TODO` 就能找到該修的地方。

變數名稱習慣直接叫 `ctx`。

### 接下來

空的 context 本身沒什麼用。接下來幾集，我們會從它「衍生」出可以取消、會逾時、帶著資料的 context，再把它傳給需要的函式：

```go,ignore
func fetchOrder(ctx context.Context, id int) (Order, error)
```

## 重點整理

- context 用來把「取消訊號、截止時間、請求範圍的資料」沿著函式呼叫往下傳。
- `context.Context` 是有 `Deadline`、`Done`、`Err`、`Value` 四個方法的介面。
- `Done()` 回傳的 channel 會在取消時被關閉；`Err()` 在取消前是 `nil`，取消後說明原因。
- `context.Background()` 是最上層的起點；`context.TODO()` 行為相同，用來標示「之後要改成正確的 context」。
