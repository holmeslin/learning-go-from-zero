# goroutine 洩漏

## 本集目標

知道什麼是 goroutine 洩漏、它是怎麼發生的，並學會讓每個 goroutine 都有辦法結束。

## 正文

### 永遠回不了家的 goroutine

開一個 goroutine 很便宜，但它不會自己消失：只有函式回傳時，goroutine 才算結束。如果一個 goroutine 卡在 channel 上，而且**永遠不會有人**來傳送或接收，它就會一直佔著記憶體，直到整支程式結束。這叫做 **goroutine 洩漏**（goroutine leak）。

上一集說過，只要還有其他 goroutine 在跑，Go 就不會回報死結。所以洩漏不會讓程式當掉，只會讓卡住的 goroutine 越積越多。對於一跑就是好幾個月的伺服器來說，這是很嚴重的問題。

### 一個會洩漏的函式

假設我們同時問三台伺服器，誰先回答就用誰的答案：

```go
package main

import (
	"fmt"
	"runtime"
	"time"
)

func fastest(servers []string) string {
	ch := make(chan string)
	for i, s := range servers {
		go func() {
			time.Sleep(time.Duration(i+1) * 10 * time.Millisecond)
			ch <- s
		}()
	}
	return <-ch
}

func main() {
	fmt.Println(fastest([]string{"伺服器 A", "伺服器 B", "伺服器 C"}))
	time.Sleep(100 * time.Millisecond)
	fmt.Println("goroutine 數量：", runtime.NumGoroutine())
}
```

執行結果：

```text
伺服器 A
goroutine 數量： 3
```

`runtime.NumGoroutine()` 會回傳目前有幾個 goroutine（`runtime` 套件這裡只用這一個函式）。`time.Duration(i+1)` 是把整數轉成時間長度的型別，讓三台伺服器分別花 10、20、30 毫秒回答。

`fastest` 只接收了一次就回傳了。另外兩個 goroutine 稍後要傳送時，已經沒有人會接收，它們就永遠卡在 `ch <- s`。等了 100 毫秒之後，除了 `main` 自己，還有 2 個 goroutine 卡著，所以數量是 3。每呼叫一次 `fastest`，就會多洩漏 2 個。

### 改法一：給足暫存空間

既然知道會有幾個值，就讓 channel 放得下全部：

```go,ignore
ch := make(chan string, len(servers))
```

這樣其他 goroutine 就算沒人接收，也能把結果放進暫存區後順利結束。改了這一行之後再執行，數量就會變成 1。第 12 集逾時的範例給 1 格暫存區，也是同樣的道理。

### 改法二：通知它停下來

有些 goroutine 會一直送資料，沒有固定的數量，暫存區再大也不夠。這時要另外準備一條「下班通知」的 channel，讓呼叫的人可以叫它停：

```go
package main

import (
	"fmt"
	"runtime"
)

func numbers(done <-chan struct{}) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; ; i++ {
			select {
			case out <- i:
			case <-done:
				return
			}
		}
	}()
	return out
}

func main() {
	done := make(chan struct{})
	nums := numbers(done)
	for range 3 {
		fmt.Println(<-nums)
	}
	close(done)

	for range nums {
	}
	fmt.Println("goroutine 數量：", runtime.NumGoroutine())
}
```

執行結果：

```text
1
2
3
goroutine 數量： 1
```

- `struct{}` 是沒有任何欄位的 struct（第 3 章的匿名 struct），不佔空間。`chan struct{}` 表示「這條 channel 不傳資料，只用來通知」。
- 背景的 goroutine 用 `select` 一邊送數字，一邊注意 `done`。
- `main` 拿夠了就 `close(done)`。第 10 集說過，從關閉的 channel 接收會馬上成功，所以 `<-done` 這個 `case` 立刻可以進行，goroutine 就 `return` 了。而且關閉 channel 會同時通知**所有**正在等它的 goroutine，不管有幾個。
- `for range nums {}` 把剩下的值收完，直到 goroutine 結束時 `defer close(out)` 關閉 `nums` 為止。這樣印數量時，背景 goroutine 一定已經結束了。

這種「用一條 channel 通知停止」的做法非常普遍，標準庫把它包裝成了 `context`，第 10 章會正式介紹。

### 怎麼預防

每次寫 `go` 的時候，問自己一個問題：**這個 goroutine 什麼時候、靠什麼結束？** 回答不出來，就有洩漏的風險。常見的答案有：

- 它要傳送的 channel 有足夠的暫存空間，或一定有人接收。
- 它在 `for range` 的 channel 一定會被關閉。
- 它會注意一條停止通知的 channel（之後改用 `context`）。

Go 1.27 起，`runtime/pprof` 套件正式提供一種叫 `goroutineleak` 的分析資料，可以找出這種永遠不可能被喚醒的 goroutine；`pprof` 留到附錄二再介紹。

## 重點整理

- goroutine 永遠卡住、不會結束，就是 goroutine 洩漏；程式不會當掉，但卡住的 goroutine 會越積越多。
- 先回傳、不再接收的寫法，容易讓其他傳送的 goroutine 洩漏；給足暫存空間可以避免。
- 用一條 `chan struct{}` 加 `close` 通知 goroutine 停止，關閉會同時通知所有等待的 goroutine。
- 每寫一個 `go`，都要想清楚它什麼時候、靠什麼結束。
