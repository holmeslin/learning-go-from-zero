# graceful shutdown

## 本集目標

讓伺服器收到結束訊號時，先停止接受新的請求、把處理到一半的請求做完，再關閉，而不是直接把所有連線切斷。

## 正文

### 直接關掉會怎樣

伺服器常常需要重新啟動：部署新版本、搬到另一台機器。如果直接按 Ctrl+C，Go 程式會立刻結束，正在處理的請求全部中斷：使用者付款付到一半，只看到連線錯誤。

**graceful shutdown**（優雅關機）的流程是：

1. 收到結束訊號（Ctrl+C 或 `SIGTERM`）。
2. 停止接受新的連線。
3. 等處理中的請求完成。
4. 全部完成（或等太久）後才結束程式。

第 2～4 步 `http.Server` 的 `Shutdown` 方法都幫我們做好了；第 1 步就是第 13 章第 7 集的 `signal.NotifyContext`。

### 完整程式

```go,norun
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	mux := http.NewServeMux()
	mux.HandleFunc("GET /slow", func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(3 * time.Second)
		fmt.Fprintln(w, "慢慢做完了")
	})
	srv := &http.Server{
		Addr:              ":8080",
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	errCh := make(chan error, 1)
	go func() {
		fmt.Println("伺服器啟動：http://localhost:8080")
		errCh <- srv.ListenAndServe()
	}()

	select {
	case err := <-errCh:
		return err
	case <-ctx.Done():
	}
	stop()
	fmt.Println("收到結束訊號，等待處理中的請求完成……")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("關閉伺服器：%w", err)
	}
	if err := <-errCh; !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	fmt.Println("伺服器已關閉")
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
```

### 一步一步看

**在 goroutine 裡啟動伺服器。** `srv.ListenAndServe()` 會一直執行，如果在 `run` 裡直接呼叫，就沒辦法同時等訊號。所以把它放進 goroutine，回傳的錯誤送進 `errCh`。channel 的容量是 1，就算沒人接收，goroutine 也能把錯誤放進去然後結束，不會洩漏（第 9 章）。

**同時等兩件事。** `select` 等的是：

- `errCh` 先有值：伺服器根本沒啟動成功（例如埠號被占用），直接回傳錯誤。
- `ctx.Done()` 先關閉：收到了 Ctrl+C 或 `SIGTERM`，開始關機。

**呼叫 `srv.Shutdown(shutdownCtx)`。** 它會先關掉監聽，所以新的連線會被拒絕；接著等所有處理中的請求完成才回傳。等多久由傳進去的 context 決定，這裡最多 10 秒，時間到了就回傳錯誤，不再等下去。注意這個 context 是用 `context.Background()` 新建的，不能用已經被取消的 `ctx`，否則 `Shutdown` 會馬上放棄。

**`ListenAndServe` 回傳 `http.ErrServerClosed`。** 呼叫 `Shutdown` 之後，`ListenAndServe` 會立刻回傳這個哨兵錯誤，表示「是你叫我關的」，不是真的出錯，所以用 `errors.Is` 把它排除。

收到訊號後先呼叫 `stop()`，和第 13 章一樣：如果關機卡住，再按一次 Ctrl+C 就能強制結束。

### 實際試試看

在一個終端機啟動伺服器，在另一個終端機送出一個需要 3 秒的請求，並在它還沒完成時，回到第一個終端機按下 Ctrl+C：

```bash
curl localhost:8080/slow
```

伺服器那邊：

執行結果：

```text
伺服器啟動：http://localhost:8080
收到結束訊號，等待處理中的請求完成……
伺服器已關閉
```

`curl` 那邊在 3 秒後照常收到回應：

執行結果：

```text
慢慢做完了
```

按下 Ctrl+C 之後，伺服器並沒有馬上結束，而是等 `/slow` 做完才印出「伺服器已關閉」。這段期間如果有新的 `curl` 連進來，會直接得到「連不上」的錯誤，因為伺服器已經不再接受新連線了。

### 長時間的 handler 要配合

`Shutdown` 只會**等**，不會打斷 handler。如果某個 handler 要跑好幾分鐘，`Shutdown` 等到 10 秒時就會放棄並回傳錯誤，程式結束時那個請求一樣會被切斷。所以長時間的工作要像第 7 集那樣檢查 `r.Context()`，或者交給專門的背景工作系統處理。

## 重點整理

- graceful shutdown：停止接受新連線、等處理中的請求完成、再結束程式。
- 用 `signal.NotifyContext` 等訊號，伺服器放在 goroutine 裡啟動，錯誤送進容量 1 的 channel。
- `srv.Shutdown(ctx)` 會等請求做完，傳入一個新的、有逾時的 context 限制最多等多久。
- 呼叫 `Shutdown` 後 `ListenAndServe` 回傳 `http.ErrServerClosed`，這不是錯誤，要用 `errors.Is` 排除。
