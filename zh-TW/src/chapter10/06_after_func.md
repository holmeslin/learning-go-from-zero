# `AfterFunc`

## 本集目標

學會用 `context.AfterFunc` 登記「context 被取消後要做的事」，以及用它回傳的 `stop` 取消登記。

## 正文

### 取消之後自動收拾

前面幾集，我們都是自己寫 `select` 去等 `<-ctx.Done()`。有時候我們只是想說：「這個 context 被取消的時候，幫我做某件事」，例如關掉一條連線、通知某個系統。為了這件事專門開一個 goroutine 等 `Done()`，有點囉嗦。

`context.AfterFunc(ctx, f)` 就是在做這件事：ctx 被取消後，Go 會在**另一個新的 goroutine** 裡呼叫 `f`。

```go
package main

import (
	"context"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	finished := make(chan struct{})
	context.AfterFunc(ctx, func() {
		fmt.Println("收到取消，關閉連線")
		close(finished)
	})

	fmt.Println("工作中")
	cancel()
	<-finished
	fmt.Println("結束")
}
```

執行結果：

```text
工作中
收到取消，關閉連線
結束
```

- `AfterFunc` 只是「登記」，呼叫當下什麼都不會執行，所以「工作中」先印出來。
- `cancel()` 之後，`f` 在新的 goroutine 裡執行。
- 因為 `f` 跑在別的 goroutine，`main` 不等它的話可能就先結束了。這裡用一個 channel 等它做完，是第 9 章學過的手法。

如果登記的時候 ctx 早就被取消了，`f` 會立刻在新的 goroutine 裡執行。同一個 context 也可以登記好幾個 `AfterFunc`，它們各自獨立。

### `stop`：取消登記

`AfterFunc` 會回傳一個 `stop` 函式。工作順利做完、不再需要那個收拾動作時，呼叫 `stop()` 把登記撤掉：

```go
package main

import (
	"context"
	"fmt"
)

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	stop := context.AfterFunc(ctx, func() {
		fmt.Println("這行不會印出來")
	})

	fmt.Println("第一次 stop:", stop())
	cancel()
	fmt.Println("第二次 stop:", stop())
}
```

執行結果：

```text
第一次 stop: true
第二次 stop: false
```

`stop()` 回傳一個 `bool`：

- `true`：成功攔下來了，`f` 不會被執行。
- `false`：來不及或已經撤過了。可能 context 已經被取消、`f` 已經開始跑，也可能之前就呼叫過 `stop`。

這個例子第一次 `stop()` 就成功撤銷，所以之後就算 `cancel()`，`f` 也不會執行；第二次 `stop()` 沒有東西可撤，回傳 `false`。

### 什麼時候用

`AfterFunc` 適合「有些操作本身不認得 context」的情況。例如某個等待動作沒辦法放進 `select`，我們就登記一個 `AfterFunc`，在 context 被取消時去關掉它正在用的資源，讓那個等待自己結束。

一般「做一段工作、途中檢查要不要停」的情況，還是用前幾集的 `select` 加 `<-ctx.Done()` 比較直接。

## 重點整理

- `context.AfterFunc(ctx, f)` 登記一個函式，ctx 被取消後在新的 goroutine 裡執行 `f`；登記時已取消就立刻執行。
- `f` 跑在別的 goroutine，需要等它做完時要自己用 channel 等。
- 回傳的 `stop()` 可以撤銷登記；回傳 `true` 代表成功攔下，`false` 代表 `f` 已經開始執行或早就撤過了。
- 適合替不認得 context 的操作做「取消時收拾」；一般情況仍用 `select` 監看 `Done()`。
