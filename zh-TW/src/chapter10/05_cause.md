# `Cause`

## 本集目標

學會用 `context.WithCancelCause` 和 `context.WithTimeoutCause` 在取消時附上「真正的原因」，再用 `context.Cause` 取出來。

## 正文

### `Err()` 說得不夠清楚

到目前為止，被取消的 context 只會告訴我們兩種原因：`context.Canceled` 或 `context.DeadlineExceeded`。可是「為什麼被取消」常常很重要：是使用者按了取消？是某個同時進行的步驟失敗了？還是額度用完了？`Err()` 沒辦法回答這些。

### `WithCancelCause`

`context.WithCancelCause` 和 `WithCancel` 很像，但回傳的取消函式要收一個 `error`，用來說明原因：

```go
package main

import (
	"context"
	"errors"
	"fmt"
)

var ErrQuota = errors.New("超過今日查詢額度")

func main() {
	ctx, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)

	fmt.Println("取消前:", context.Cause(ctx))

	cancel(ErrQuota)
	fmt.Println("Err:", ctx.Err())
	fmt.Println("Cause:", context.Cause(ctx))
	fmt.Println(errors.Is(context.Cause(ctx), ErrQuota))
}
```

執行結果：

```text
取消前: <nil>
Err: context canceled
Cause: 超過今日查詢額度
true
```

- `cancel(ErrQuota)` 取消 context，並記下原因。
- `ctx.Err()` 還是 `context.Canceled`，維持原本的行為，舊的程式碼不會壞掉。
- `context.Cause(ctx)` 才會拿到我們給的 `ErrQuota`，可以搭配第 5 章的哨兵錯誤和 `errors.Is` 判斷。
- 還沒取消時，`Cause` 回傳 `nil`。
- `defer cancel(nil)`：傳 `nil` 表示「沒有特別原因」，這時 `Cause` 會回傳 `context.Canceled`。因為前面已經取消過了，這次呼叫什麼都不會改變。

只有**第一次**取消會被記下來。之後再呼叫 `cancel(別的錯誤)`，原因也不會被蓋掉。

### 子 context 也查得到原因

`Cause` 會沿著 context 樹往上找。父 context 帶著原因被取消，子 context 查到的也是同一個原因：

```go
package main

import (
	"context"
	"errors"
	"fmt"
)

func main() {
	parent, cancel := context.WithCancelCause(context.Background())
	defer cancel(nil)
	child, cancelChild := context.WithCancel(parent)
	defer cancelChild()

	cancel(errors.New("訂單已被刪除"))
	fmt.Println(child.Err())
	fmt.Println(context.Cause(child))
}
```

執行結果：

```text
context canceled
訂單已被刪除
```

如果 context 是用一般的 `WithCancel` 或 `WithTimeout` 取消的，沒有特別的原因，`Cause` 就回傳和 `Err()` 一樣的值。所以想查原因時，一律用 `context.Cause` 就對了。

### `WithTimeoutCause`

逾時也能指定原因。`context.WithTimeoutCause` 多收一個 `error`，時間到時就用它當原因：

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var ErrShippingSlow = errors.New("物流系統回應太慢")

func main() {
	ctx, cancel := context.WithTimeoutCause(context.Background(), 30*time.Millisecond, ErrShippingSlow)
	defer cancel()

	<-ctx.Done()
	fmt.Println("Err:", ctx.Err())
	fmt.Println("Cause:", context.Cause(ctx))
}
```

執行結果：

```text
Err: context deadline exceeded
Cause: 物流系統回應太慢
```

注意 `WithTimeoutCause` 回傳的是普通的 `cancel`（不收參數）。原因只在「時間到」時才會被設定；如果是我們自己先呼叫 `cancel()`，`Cause` 就只是 `context.Canceled`。

另外還有 `context.WithDeadlineCause`，用法和 `WithDeadline` 對應，一樣多收一個原因。

## 重點整理

- `ctx, cancel := context.WithCancelCause(parent)` 的 `cancel` 收一個 `error` 當作取消原因。
- `context.Cause(ctx)` 取得取消原因；`ctx.Err()` 仍然只回傳 `context.Canceled` 或 `context.DeadlineExceeded`。
- 只有第一次取消的原因會被記下；子 context 查得到父 context 的原因；沒指定原因時 `Cause` 等於 `Err()`。
- `WithTimeoutCause` 和 `WithDeadlineCause` 讓逾時帶著自訂原因。
