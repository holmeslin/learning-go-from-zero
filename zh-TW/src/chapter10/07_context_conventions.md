# context 傳遞慣例

## 本集目標

學會 context 在函式之間傳遞的幾條慣例：放在第一個參數、不要存進 struct、不要傳 `nil`，以及用 `context.WithoutCancel` 讓收尾工作不被取消。

## 正文

### 第一個參數，名字叫 `ctx`

需要 context 的函式，一律把它放在**第一個**參數，名字叫 `ctx`：

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func findUser(ctx context.Context, id int) (string, error) {
	if err := ctx.Err(); err != nil {
		return "", err
	}
	return fmt.Sprintf("會員%d", id), nil
}

func findOrders(ctx context.Context, user string) ([]string, error) {
	select {
	case <-time.After(100 * time.Millisecond):
		return []string{user + "的訂單 A", user + "的訂單 B"}, nil
	case <-ctx.Done():
		return nil, ctx.Err()
	}
}

func handleRequest(ctx context.Context, id int) {
	ctx, cancel := context.WithTimeout(ctx, 1*time.Second)
	defer cancel()

	user, err := findUser(ctx, id)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	orders, err := findOrders(ctx, user)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(orders)
}

func main() {
	handleRequest(context.Background(), 7)
}
```

執行結果：

```text
[會員7的訂單 A 會員7的訂單 B]
```

注意幾件事：

- context 從 `main` 開始，一層一層當參數往下傳，每個函式都把**收到的** `ctx` 交給它呼叫的函式。
- `handleRequest` 用收到的 `ctx` 當父 context，衍生出一個加了時限的版本，再傳下去。上層一取消，這裡也會跟著取消。
- `findUser` 開頭用 `ctx.Err()` 檢查一下：已經被取消了就不用白做。

之後學到的標準函式庫，例如第 14 章的 HTTP、第 15 章的資料庫，都照這個慣例設計。

### 不要存進 struct

不要把 context 存成 struct 的欄位：

```go,ignore
// 不好的寫法
type OrderService struct {
	ctx context.Context
}

func (s *OrderService) Find(id int) (Order, error)
```

context 代表的是「某一次請求」的生命週期，而 struct 通常會活得比一次請求還久。存起來之後，下一次請求可能用到上一次早已取消的 context，而且從 `Find` 的簽名完全看不出它受哪個 context 控制。

正確的做法是在每個方法的參數上傳：

```go,ignore
type OrderService struct{}

func (s *OrderService) Find(ctx context.Context, id int) (Order, error)
```

### 不要傳 `nil`

不知道該傳什麼 context 時，不要傳 `nil`。用 `nil` 當父 context 會直接 panic：

```go,exit=2
package main

import (
	"context"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(nil)
	defer cancel()
	fmt.Println(ctx.Err())
}
```

執行結果（省略了後面幾行）：

```text
panic: cannot create context from nil parent

goroutine 1 [running]:
context.withCancel(...)
```

就算函式裡暫時沒有用到 ctx，也可能哪天改了就會呼叫 `ctx.Done()`，對 `nil` 介面呼叫方法一樣會 panic。這時請傳 `context.TODO()`，標示「這裡之後要接上正確的 context」。

### `WithoutCancel`：收尾工作不要被取消

有時候請求已經結束、context 被取消了，但還有一些工作必須做完，例如寫入稽核紀錄。如果直接用請求的 ctx，這些工作會跟著被取消。

`context.WithoutCancel(parent)` 會產生一個「不會因為 parent 取消而取消」的 context，但 parent 上的資料仍然拿得到：

```go
package main

import (
	"context"
	"fmt"
)

type ctxKey int

const userKey ctxKey = 0

func main() {
	base := context.WithValue(context.Background(), userKey, "andy")
	reqCtx, cancel := context.WithCancel(base)

	auditCtx := context.WithoutCancel(reqCtx)
	cancel()

	fmt.Println("reqCtx:", reqCtx.Err())
	fmt.Println("auditCtx:", auditCtx.Err())
	fmt.Println("使用者:", auditCtx.Value(userKey))
}
```

執行結果：

```text
reqCtx: context canceled
auditCtx: <nil>
使用者: andy
```

`auditCtx` 沒有截止時間、也不會被取消。需要的話，可以再用 `WithTimeout` 從它衍生出一個有時限的版本，避免收尾工作永遠做不完。

### 誰建立，誰取消

最後一條：`cancel` 由**建立** context 的那一方負責呼叫。收到 ctx 的函式只負責「聽從」取消，不負責「發出」取消。這也是為什麼 `Context` 介面裡沒有 `Cancel` 方法。

## 重點整理

- 需要 context 的函式，把 `ctx context.Context` 放在第一個參數，並把收到的 ctx 往下傳。
- 不要把 context 存在 struct 欄位裡，改成每個方法都從參數接收。
- 不要傳 `nil` context，用 `nil` 衍生 context 會 panic；不知道傳什麼就用 `context.TODO()`。
- `context.WithoutCancel(parent)` 不受 parent 取消影響，但保留 parent 的資料，適合請求結束後的收尾工作。
- 建立 context 的一方負責呼叫 `cancel`，接收的一方只負責聽從取消。
