# worker pool

## 本集目標

學會用固定數量的 goroutine 消化一整批工作，也就是 worker pool，並把前面學的 channel、`WaitGroup`、`close` 組合起來。

## 正文

### 為什麼不要一個工作開一個 goroutine

goroutine 很便宜，一次開幾千個也沒問題。可是工作本身常常會用到有限的資源：同時打開的檔案數、資料庫連線、對方伺服器願意接受的請求數。如果有一萬筆工作就同時開一萬個 goroutine，很可能把這些資源一下子用光。

**worker pool**（工人池）的做法是：先開固定幾個「工人」goroutine，把工作放進一條 channel，工人們從 channel 裡一件一件拿來做，做完再拿下一件。不管工作有多少，同時在做的永遠只有那幾個。就像銀行開 3 個櫃檯，客人再多也是排隊，輪到了才辦。

### 完整範例

```go
package main

import (
	"cmp"
	"fmt"
	"slices"
	"sync"
)

type result struct {
	n      int
	square int
}

func worker(jobs <-chan int, results chan<- result) {
	for n := range jobs {
		results <- result{n: n, square: n * n}
	}
}

func main() {
	jobs := make(chan int)
	results := make(chan result)

	var wg sync.WaitGroup
	for range 3 {
		wg.Go(func() {
			worker(jobs, results)
		})
	}

	go func() {
		for n := 1; n <= 9; n++ {
			jobs <- n
		}
		close(jobs)
	}()

	go func() {
		wg.Wait()
		close(results)
	}()

	var all []result
	for r := range results {
		all = append(all, r)
	}
	slices.SortFunc(all, func(a, b result) int {
		return cmp.Compare(a.n, b.n)
	})
	for _, r := range all {
		fmt.Printf("%d 的平方是 %d\n", r.n, r.square)
	}
}
```

執行結果：

```text
1 的平方是 1
2 的平方是 4
3 的平方是 9
4 的平方是 16
5 的平方是 25
6 的平方是 36
7 的平方是 49
8 的平方是 64
9 的平方是 81
```

### 拆開來看

這個程式裡有三種角色，各自負責一件事：

1. **工人**：3 個 goroutine 都執行 `worker`，用 `for range jobs` 不停拿工作，把結果送進 `results`。`jobs` 被關閉、而且工作都拿完之後，`for range` 結束，工人就下班了。
2. **派工的人**：一個 goroutine 把 1 到 9 送進 `jobs`，送完就 `close(jobs)`。這是第 10 集的規則：由傳送的一方關閉。
3. **收尾的人**：一個 goroutine 等所有工人下班（`wg.Wait()`），再 `close(results)`。這是第 15 集學到的寫法。為什麼不能讓工人自己關 `results`？因為有 3 個工人在送，誰最後一個送完只有 `WaitGroup` 知道；先送完的工人如果把它關掉，其他工人再送就會 panic。

`main` 自己只負責用 `for range results` 收結果，直到 `results` 被關閉。

`worker` 的參數用了第 13 集的單向 channel：工人只能從 `jobs` 接收、只能往 `results` 傳送，寫錯方向會編譯失敗。

### 結果的順序

哪個工人拿到哪個數字、誰先做完，每次執行都不一樣，所以收到結果的順序也不固定。我們把結果放進 `result` struct，記下是哪個數字算出來的，最後用第 6 章的 `slices.SortFunc` 依 `n` 排序再印。只要結果裡記著「這是哪一筆工作的」，順序亂掉也沒關係。

### 要開幾個工人

工人的數量就是「同時最多做幾件事」：

- 工作主要在等待（等網路、等硬碟）時，可以開多一點。
- 工作主要在計算時，開到和 CPU 核心數差不多就夠了，再多也不會更快。

最好的方法是實際量測，第 8 章的 benchmark 可以派上用場。

## 重點整理

- worker pool 用固定數量的 goroutine 消化工作，限制同時進行的數量。
- 工人用 `for range jobs` 拿工作；派工的一方送完就 `close(jobs)`。
- 用另一個 goroutine `wg.Wait()` 再 `close(results)`，`main` 用 `for range results` 收結果。
- 結果的順序不固定；在結果裡記下對應的工作，需要時再排序。
