# data race 與 `-race`

## 本集目標

知道好幾個 goroutine 同時修改同一個變數會發生 data race，並學會用 `-race` 把它找出來。

## 正文

### 一個算錯的計數器

我們開 100 個 goroutine，每個都把 `count` 加 1000 次。照理說最後應該是 100 × 1000 = 100000：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	count := 0
	var wg sync.WaitGroup
	for range 100 {
		wg.Go(func() {
			for range 1000 {
				count++
			}
		})
	}
	wg.Wait()
	fmt.Println(count)
}
```

執行結果（某一次）：

```text
53717
```

多跑幾次，你會得到 43629、45543 之類的數字，每次都不一樣，而且幾乎都不是 100000。程式不會當掉，只是**默默地算錯**。

### 為什麼會算錯

`count++` 看起來只有一步，其實電腦要做三件事：

1. 讀出 `count` 現在的值。
2. 把它加 1。
3. 把新的值寫回 `count`。

假設 `count` 是 5，兩個 goroutine 剛好同時執行 `count++`：

| 時間 | goroutine A | goroutine B |
| --- | --- | --- |
| 1 | 讀到 5 | |
| 2 | | 讀到 5 |
| 3 | 算出 6，寫回 | |
| 4 | | 算出 6，寫回 |

加了兩次，`count` 卻只變成 6，有一次加法就這樣不見了。

這種情況叫做 **data race**（資料競爭）：**兩個以上的 goroutine 同時存取同一個變數，而且其中至少一個在寫入**，中間又沒有任何同步的機制。Go 對 data race 的態度很明確：有 data race 的程式就是錯的，結果是什麼都不保證。

上一集讓每個 goroutine 寫切片裡「各自的格子」就沒有問題，因為它們沒有碰到同一個變數。

### 用 `-race` 抓出 data race

data race 很難靠肉眼發現，因為它不是每次都會造成錯誤的結果。Go 內建了 **race detector**（競爭偵測器），在 `go run`、`go build`、`go test` 後面加上 `-race` 就會啟用：

```bash
go run -race .
```

執行結果的開頭（省略了檔案路徑）：

```text
==================
WARNING: DATA RACE
Read at 0x00c000012188 by goroutine 8:
  main.main.func1()
      .../main.go:14 +0x38

Previous write at 0x00c000012188 by goroutine 7:
  main.main.func1()
      .../main.go:14 +0x48
```

看懂這份報告的重點：

- `WARNING: DATA RACE`：找到 data race 了。
- `Read at ... by goroutine 8`：第 8 號 goroutine 在讀。
- `Previous write at ... by goroutine 7`：而第 7 號 goroutine 之前在同一個位址寫過。
- `main.go:14`：出事的是第 14 行，也就是 `count++`。

報告的最後會印出 `Found 2 data race(s)` 這樣的總數，程式的結束碼也會變成 66（不是 0），讓你知道出問題了。位址、goroutine 編號和找到的數量每次都可能不同。

寫測試時也一樣：

```bash
go test -race ./...
```

`./...` 代表目前資料夾和底下所有的套件。

### 使用 `-race` 的注意事項

- race detector 只能抓到**實際有執行到**的 data race。沒跑到的程式碼，它看不到；所以搭配測試一起用最有效。
- 開了 `-race` 的程式會變慢、吃更多記憶體，所以平常是在開發和測試時開，不會拿來當正式版本。
- `-race` 需要 cgo（第 11 章會介紹），也就是電腦上要裝有 C 編譯器，而且只支援部分作業系統和 CPU 的組合（例如 Windows 只支援 `windows/amd64`），完整清單可以用 `go help build` 查看。

### 怎麼修？

修正 data race 的方法，就是讓同一時間只有一個 goroutine 能碰這個變數，或是乾脆不要共用變數。接下來幾集會學到三種工具：`sync.Mutex`（下一集）、`sync/atomic`（第 6 集），以及 channel（第 8 集起）。

## 重點整理

- 兩個以上的 goroutine 同時存取同一個變數、其中至少一個在寫入，就是 data race。
- 有 data race 的程式結果不保證，常常是默默算錯，而且每次結果不同。
- `go run -race`、`go test -race` 可以在執行時偵測 data race，找到時會印出 `WARNING: DATA RACE` 和出事的行號。
- race detector 只抓得到有執行到的程式碼；它需要 cgo，而且只支援部分平台。
