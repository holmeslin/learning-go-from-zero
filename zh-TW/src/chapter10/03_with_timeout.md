# `WithTimeout` 與 `WithDeadline`

## 本集目標

學會用 `context.WithTimeout` 和 `context.WithDeadline` 替工作設定時間上限，並用 `errors.Is` 判斷是不是逾時。

## 正文

### 時間到了自動取消

上一集的 context 要我們手動呼叫 `cancel()`。很多時候我們要的其實是「最多等 2 秒，時間到就放棄」，這時用 `context.WithTimeout`：

```go,ignore
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
```

時間一到，context 會自己取消，`ctx.Err()` 變成 `context.DeadlineExceeded`。它一樣會回傳 `cancel`，一樣要 `defer cancel()`：工作提早做完時，呼叫 `cancel` 可以馬上釋放計時器等資源。

### 讓慢動作可以被打斷

下面的 `slowQuery` 假裝是一個要花 200 毫秒的查詢。重點是它不用 `time.Sleep` 乾等，而是用 `select` 同時等「工作完成」和「context 取消」，哪個先來就走哪條路：

```go
package main

import (
	"context"
	"errors"
	"fmt"
	"time"
)

func slowQuery(ctx context.Context) (string, error) {
	select {
	case <-time.After(200 * time.Millisecond):
		return "查到 3 筆訂單", nil
	case <-ctx.Done():
		return "", ctx.Err()
	}
}

func try(timeout time.Duration) {
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	result, err := slowQuery(ctx)
	if errors.Is(err, context.DeadlineExceeded) {
		fmt.Println("等太久，放棄了:", err)
		return
	}
	if err != nil {
		fmt.Println("其他錯誤:", err)
		return
	}
	fmt.Println(result)
}

func main() {
	try(1 * time.Second)
	try(50 * time.Millisecond)
}
```

執行結果：

```text
查到 3 筆訂單
等太久，放棄了: context deadline exceeded
```

- 第一次給 1 秒，查詢 200 毫秒就做完了，正常拿到結果。
- 第二次只給 50 毫秒，時間到時查詢還沒好，`ctx.Done()` 先被關閉，`slowQuery` 回傳 `ctx.Err()`。
- 判斷是不是逾時，用第 5 章的 `errors.Is(err, context.DeadlineExceeded)`。就算錯誤被 `%w` 包了好幾層，也能正確認出來。

`time.Sleep` 一旦開始睡就叫不醒，所以需要能被取消的等待時，要像這樣改用 `select`。

### `WithDeadline`：指定「幾點幾分」

`WithTimeout` 說的是「從現在起多久」，`WithDeadline` 說的是「到某個時間點為止」。其實 `WithTimeout(parent, d)` 就等於 `WithDeadline(parent, time.Now().Add(d))`。

`time.Now()` 取得現在的時間，`.Add(d)` 算出往後 `d` 的時間點；`time` 套件第 12 章會正式介紹。

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	deadline := time.Now().Add(30 * time.Millisecond)
	ctx, cancel := context.WithDeadline(context.Background(), deadline)
	defer cancel()

	d, ok := ctx.Deadline()
	fmt.Println(ok, d.Equal(deadline))

	<-ctx.Done()
	fmt.Println(ctx.Err())
}
```

執行結果：

```text
true true
context deadline exceeded
```

`ctx.Deadline()` 拿回我們設定的時間點。接著 `<-ctx.Done()` 一直等到時間到、channel 被關閉，才印出原因。

### 子 context 不能比父 context 活得久

截止時間也會沿著 context 樹往下傳。如果父 context 30 毫秒後就到期，子 context 就算設定 1 秒，也會跟著在 30 毫秒時被取消：

```go
package main

import (
	"context"
	"fmt"
	"time"
)

func main() {
	parent, cancelParent := context.WithTimeout(context.Background(), 30*time.Millisecond)
	defer cancelParent()
	child, cancelChild := context.WithTimeout(parent, 1*time.Second)
	defer cancelChild()

	pd, _ := parent.Deadline()
	cd, _ := child.Deadline()
	fmt.Println("截止時間相同:", pd.Equal(cd))

	<-child.Done()
	fmt.Println("child:", child.Err())
}
```

執行結果：

```text
截止時間相同: true
child: context deadline exceeded
```

這很合理：整個請求只剩 30 毫秒，底下的步驟不可能多拿到時間。子 context 只能把期限**縮短**，不能延長。

## 重點整理

- `context.WithTimeout(parent, d)` 在 `d` 之後自動取消；`context.WithDeadline(parent, t)` 在時間點 `t` 自動取消。
- 兩者都回傳 `cancel`，一樣要 `defer cancel()`，工作提早完成時可以馬上釋放資源。
- 逾時後 `ctx.Err()` 是 `context.DeadlineExceeded`，用 `errors.Is` 判斷。
- 需要可取消的等待，用 `select` 同時等工作和 `<-ctx.Done()`，不要用 `time.Sleep`。
- 子 context 的截止時間不會晚於父 context。
