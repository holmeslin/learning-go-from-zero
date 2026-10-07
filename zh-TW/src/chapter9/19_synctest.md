# `testing/synctest`

## 本集目標

學會用 Go 1.25 正式加入的 `testing/synctest` 測試和時間、goroutine 有關的程式，讓需要等好幾秒的測試瞬間跑完，而且結果穩定。

## 正文

### 並行程式很難測

假設我們要測試第 12 集那種「最多等多久」的函式。直接寫測試會遇到兩個麻煩：

- **慢**：要確認「等 10 秒會逾時」，測試就真的得等 10 秒。
- **不穩**：要確認「3 秒後收到值」，只能用 `time.Sleep` 去猜時間。電腦一忙，測試就可能偶爾失敗。

`testing/synctest` 套件解決的就是這兩個問題。

### 要測試的程式

建立一個 `waiter` 模組（`go mod init waiter`），寫一個 `Receive` 函式：從 channel 收一個值，最多等 `d` 這麼久。

`waiter.go`：

```go,ignore
package waiter

import "time"

// Receive 從 ch 接收一個值，最多等 d 這麼久。
// 收到時回傳該值和 true；逾時回傳 0 和 false。
func Receive(ch <-chan int, d time.Duration) (int, bool) {
	select {
	case v := <-ch:
		return v, true
	case <-time.After(d):
		return 0, false
	}
}
```

`time.Duration` 是 `time` 套件表示「一段時間」的型別，`10*time.Second` 這種寫法的型別就是它（第 12 章介紹）。

### 泡泡裡的假時鐘

`synctest.Test` 會建立一個**泡泡**（bubble），在泡泡裡執行你給的函式。泡泡裡有兩個特別的規則：

1. **時間是假的**。泡泡裡的時鐘從 2000 年 1 月 1 日午夜開始，而且不會自己走。
2. 當泡泡裡**所有** goroutine 都卡住、只能靠泡泡裡的其他 goroutine 叫醒時，假時鐘就**直接跳到**下一個會有事情發生的時間點。

所以在泡泡裡 `time.Sleep(10 * time.Second)` 不用真的等 10 秒：大家都在等時間，時鐘就直接往前跳 10 秒。

`waiter_test.go`：

```go,ignore
package waiter

import (
	"testing"
	"testing/synctest"
	"time"
)

func TestReceiveTimeout(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ch := make(chan int)
		start := time.Now()
		_, ok := Receive(ch, 10*time.Second)
		if ok {
			t.Fatalf("應該要逾時")
		}
		if waited := time.Since(start); waited != 10*time.Second {
			t.Errorf("等了 %v，想要 10s", waited)
		}
	})
}

func TestReceiveValue(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		ch := make(chan int)
		go func() {
			time.Sleep(3 * time.Second)
			ch <- 42
		}()
		v, ok := Receive(ch, 10*time.Second)
		if !ok || v != 42 {
			t.Errorf("Receive() = %d, %t，想要 42, true", v, ok)
		}
	})
}
```

- `synctest.Test(t, func(t *testing.T) { ... })`：第一個參數是測試的 `t`，第二個是要在泡泡裡執行的函式。
- `time.Now()` 取得現在的時間，`time.Since(start)` 算出從 `start` 到現在過了多久（第 12 章介紹）。
- 第一個測試：沒有人傳送，`Receive` 卡在 `select`，泡泡裡沒有其他事可做，時鐘直接跳到 10 秒後，`time.After` 響了。我們甚至可以檢查「剛好等了 10 秒」，因為假時鐘不會有誤差。
- 第二個測試：時鐘先跳到 3 秒，背景 goroutine 送出 42，`Receive` 收到值，根本不會等到 10 秒。

執行看看：

```bash
go test -v
```

```text
=== RUN   TestReceiveTimeout
--- PASS: TestReceiveTimeout (0.00s)
=== RUN   TestReceiveValue
--- PASS: TestReceiveValue (0.00s)
PASS
ok  	waiter	0.380s
```

兩個測試都是 `0.00s`，最後的總時間你的數字會不同，但絕對不會是 13 秒。

### `synctest.Wait`：等大家都停下來

有時候我們想確認「某個時間點之前，背景工作**還沒**做完」。`synctest.Wait()` 會等到泡泡裡**其他所有** goroutine 都卡住為止，這時再檢查狀態，結果就是確定的。在 `waiter_test.go` 加上這個測試（`import` 也要加上 `"sync/atomic"`）：

```go,ignore
func TestWait(t *testing.T) {
	synctest.Test(t, func(t *testing.T) {
		var done atomic.Bool
		go func() {
			time.Sleep(time.Second)
			done.Store(true)
		}()

		synctest.Wait()
		if done.Load() {
			t.Fatalf("還沒過 1 秒，不應該完成")
		}

		synctest.Sleep(time.Second)
		if !done.Load() {
			t.Fatalf("過了 1 秒，應該要完成")
		}
	})
}
```

- 第一次 `synctest.Wait()` 回傳時，背景 goroutine 一定已經走到 `time.Sleep` 並卡住了，還沒執行 `done.Store(true)`，所以 `done` 一定是 `false`。
- `synctest.Sleep(time.Second)` 是 Go 1.27 新增的函式，等於先 `time.Sleep(time.Second)` 再 `synctest.Wait()`：讓時鐘走 1 秒，再等其他 goroutine 都停下來。這時背景 goroutine 一定已經做完了。
- `done` 用第 6 集的 `atomic.Bool`，因為兩個 goroutine 都會碰它。如果用普通的 `bool`，`go test -race` 會回報 data race。

### 使用上的注意事項

- `synctest.Test` 會等泡泡裡所有 goroutine 都結束才回傳。如果泡泡裡的 goroutine 互相卡死、時鐘也沒辦法往前跳，測試會失敗，而不是永遠卡住。
- 「卡住」只算在泡泡裡建立的 channel 上等待、`time.Sleep`、`WaitGroup.Wait` 等情況。等網路、等 `Mutex` 不算，因為可能是泡泡外的事情叫醒它。
- 泡泡裡建立的 channel 和計時器屬於這個泡泡，不能拿到泡泡外面用。

## 重點整理

- `synctest.Test(t, func(t *testing.T) { ... })` 在泡泡裡執行測試；泡泡裡用的是假時鐘。
- 泡泡裡所有 goroutine 都卡住時，假時鐘會直接跳到下一個時間點，所以等很久的測試也能瞬間完成，而且時間精準。
- `synctest.Wait()` 等其他 goroutine 都卡住，之後檢查的狀態是確定的；Go 1.27 的 `synctest.Sleep(d)` 等於 `time.Sleep(d)` 加 `synctest.Wait()`。
- 只有在泡泡內的 channel、`time.Sleep`、`WaitGroup.Wait` 等上面等待才算卡住；網路和 `Mutex` 不算。
