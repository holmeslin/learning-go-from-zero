# `signal.NotifyContext`

## 本集目標

讓程式在使用者按下 Ctrl+C 時不是當場死掉，而是收到通知、把手上的工作收好再結束。

## 正文

### Ctrl+C 是一個訊號

在終端機按下 Ctrl+C，作業系統會送一個**訊號**（signal）給正在執行的程式，名叫 interrupt（中斷）。Go 程式預設收到它就**立刻結束**：`defer` 不會執行、寫到一半的檔案就停在一半。

對很快就跑完的小工具來說，這沒什麼問題。但如果程式要處理很久（下載大量檔案、批次轉檔），我們會希望它「先把這一個做完、存好進度再走」。這叫做**優雅結束**（graceful shutdown）。

### 把訊號變成 context

第 10 章學過，`context` 是用來通知「該停了」的工具。`os/signal` 套件的 `signal.NotifyContext` 把兩者接起來：收到指定的訊號時，取消它回傳的 context。

```go,norun
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	fmt.Println("開始處理，按 Ctrl+C 可以中斷")
	for i := 1; i <= 10; i++ {
		select {
		case <-ctx.Done():
			stop()
			fmt.Printf("已完成 %d 個項目，儲存進度……\n", i-1)
			time.Sleep(500 * time.Millisecond)
			fmt.Println("進度已儲存")
			return context.Cause(ctx)
		case <-time.After(time.Second):
			fmt.Printf("第 %d 個項目完成\n", i)
		}
	}
	fmt.Println("全部完成")
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "中斷：", err)
		os.Exit(1)
	}
}
```

這支程式會跑十秒左右，所以只編譯、不在書裡自動執行。我們自己執行，在第 3 個項目完成後按下 Ctrl+C：

```bash
go build -o job .
./job
```

執行結果：

```text
開始處理，按 Ctrl+C 可以中斷
第 1 個項目完成
第 2 個項目完成
第 3 個項目完成
已完成 3 個項目，儲存進度……
進度已儲存
中斷： interrupt signal received
```

（終端機通常還會在按下的位置顯示 `^C`，那是終端機自己印的，不是程式的輸出。）

### 一步一步看

- `signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)` 回傳一個 context 和一個 `stop` 函式。後面列出的就是要攔截的訊號：`os.Interrupt` 是 Ctrl+C；`syscall.SIGTERM` 是 `kill` 指令、Docker 等工具要求程式結束時送的訊號，兩個一起攔是常見寫法。
- 攔截之後，訊號**不再**讓程式直接結束，而是讓 `ctx.Done()` 被關閉。
- 迴圈裡用 `select` 同時等兩件事：下一個項目做完，或是 `ctx.Done()`。收到訊號就先存進度，再回傳錯誤。
- `context.Cause(ctx)` 告訴我們是哪個訊號造成的取消，所以錯誤訊息是 `interrupt signal received`。
- 因為工作寫在 `run` 裡，`defer stop()` 一定會執行；`main` 只負責印錯誤和設定結束碼（第 4 集的寫法）。

### 為什麼收到訊號後馬上呼叫 `stop()`

`stop()` 會取消攔截，讓訊號恢復預設行為。我們在收到第一次 Ctrl+C 後立刻呼叫它，所以如果收尾卡住了，使用者**再按一次** Ctrl+C 就能強制結束。這是很貼心的設計：第一次是「請你收拾一下」，第二次是「我不等了」。

如果不呼叫 `stop()`，之後的 Ctrl+C 都會被吞掉，使用者會覺得程式按不掉。

### 用 `kill` 送訊號

`syscall.SIGTERM` 可以用 `kill` 指令送出。在另一個終端機視窗執行 `kill <程式的 PID>`，程式會走同樣的收尾流程：

執行結果：

```text
開始處理，按 Ctrl+C 可以中斷
第 1 個項目完成
已完成 1 個項目，儲存進度……
進度已儲存
中斷： terminated signal received
```

第 14 章的網頁伺服器也會用一模一樣的寫法，在關機前把處理中的請求做完。

## 重點整理

- Ctrl+C 會送出 interrupt 訊號，Go 程式預設收到就立刻結束，`defer` 不會執行。
- `signal.NotifyContext(ctx, os.Interrupt, syscall.SIGTERM)` 把訊號轉成 context 的取消。
- 長時間的工作用 `select` 等 `ctx.Done()`，收到後先收尾再結束。
- 收到第一個訊號後呼叫 `stop()`，讓使用者再按一次 Ctrl+C 能強制結束。
