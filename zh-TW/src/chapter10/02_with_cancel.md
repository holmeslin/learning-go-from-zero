# `WithCancel`

## 本集目標

學會用 `context.WithCancel` 做出可以取消的 context，讓 goroutine 收到取消訊號就停下來，並養成 `defer cancel()` 的習慣。

## 正文

### 做出可以取消的 context

`context.WithCancel` 收一個「父 context」，回傳兩個東西：一個新的「子 context」，以及一個取消函式：

```go,ignore
ctx, cancel := context.WithCancel(context.Background())
```

呼叫 `cancel()`，`ctx.Done()` 的 channel 就會被關閉，`ctx.Err()` 也會變成 `context.Canceled`。

### 讓 goroutine 聽從取消

下面的 `produce` 會不斷產生數字送出去，直到 context 被取消：

```go
package main

import (
	"context"
	"fmt"
)

func produce(ctx context.Context, out chan<- int, stopped chan<- error) {
	for i := 1; ; i++ {
		select {
		case <-ctx.Done():
			stopped <- ctx.Err()
			return
		case out <- i:
		}
	}
}

func main() {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	out := make(chan int)
	stopped := make(chan error)
	go produce(ctx, out, stopped)

	for range 3 {
		fmt.Println("收到", <-out)
	}
	cancel()
	fmt.Println("produce 停止了，原因:", <-stopped)
}
```

執行結果：

```text
收到 1
收到 2
收到 3
produce 停止了，原因: context canceled
```

一步一步看：

- `produce` 用 `select`（第 9 章）同時等兩件事：「context 被取消了」或「有人要收下一個數字」。
- `main` 收了 3 個數字後呼叫 `cancel()`。之後再也沒人收 `out`，`select` 唯一能走的就是 `<-ctx.Done()` 這條路。
- `produce` 把 `ctx.Err()` 送回來後就 `return`，goroutine 乾淨地結束，不會洩漏。

這就是使用 context 的基本模式：**長時間的工作要定期看一下 `ctx.Done()`**，被取消了就收手。

### 一定要 `defer cancel()`

注意 `main` 裡緊接著寫了 `defer cancel()`，而且後面又手動呼叫了一次 `cancel()`。這不衝突：

- `cancel` 可以呼叫很多次，第二次以後什麼都不做。
- 建立可取消的 context 時，Go 會在父 context 那邊登記這個子 context。不呼叫 `cancel`，這份登記就要等到父 context 被取消才會清掉，等於一點一點地洩漏資源。

所以慣例是：**拿到 `cancel` 的下一行就寫 `defer cancel()`**，就算之後會提早手動取消也一樣。忘記的話，`go vet` 會提醒你：

```go,ignore
ctx, _ := context.WithCancel(context.Background())
```

`go vet` 的訊息：

```text
the cancel function returned by context.WithCancel should be called, not discarded, to avoid a context leak
```

### 取消會往下傳，不會往上傳

從 context 衍生出來的 context，會形成一棵樹。取消某個 context，它底下所有的子孫都會一起被取消；但它的父 context 不受影響：

```go
package main

import (
	"context"
	"fmt"
)

func main() {
	parent, cancelParent := context.WithCancel(context.Background())
	defer cancelParent()
	child, cancelChild := context.WithCancel(parent)
	defer cancelChild()
	sibling, cancelSibling := context.WithCancel(parent)
	defer cancelSibling()

	cancelChild()
	fmt.Println("取消 child 之後")
	fmt.Println("parent:", parent.Err())
	fmt.Println("child:", child.Err())
	fmt.Println("sibling:", sibling.Err())

	cancelParent()
	fmt.Println("取消 parent 之後")
	fmt.Println("parent:", parent.Err())
	fmt.Println("sibling:", sibling.Err())
}
```

執行結果：

```text
取消 child 之後
parent: <nil>
child: context canceled
sibling: <nil>
取消 parent 之後
parent: context canceled
sibling: context canceled
```

取消 `child` 只影響它自己；取消 `parent`，還沒被取消的 `sibling` 也跟著被取消了。這正是我們想要的：最上層一喊停，底下所有工作都會收到通知。

## 重點整理

- `ctx, cancel := context.WithCancel(parent)` 產生可取消的子 context；呼叫 `cancel()` 會關閉 `ctx.Done()`，`ctx.Err()` 變成 `context.Canceled`。
- 長時間的工作用 `select` 監看 `<-ctx.Done()`，被取消就收手並結束 goroutine。
- 拿到 `cancel` 後立刻 `defer cancel()`；`cancel` 可以重複呼叫，忘記呼叫 `go vet` 會警告。
- 取消會傳給所有子孫 context，但不會影響父 context。
