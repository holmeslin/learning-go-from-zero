# 死結

## 本集目標

認識 Go 的死結錯誤訊息，知道幾種常見的死結寫法和改法，並了解 Go 不是每種卡住都偵測得到。

## 正文

### 大家都在等

**死結**（deadlock）就是每個 goroutine 都在等別人，而沒有任何一個能往下走。就像窄巷裡兩台車迎面相遇，都在等對方先倒車，結果誰都動不了。

### 最簡單的死結

```go,exit=2
package main

import "fmt"

func main() {
	ch := make(chan int)
	ch <- 1
	fmt.Println(<-ch)
}
```

執行結果（省略了後面幾行）：

```text
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
```

`ch` 沒有暫存空間，`ch <- 1` 要等到有人接收才能完成。可是唯一能接收的就是 `main` 自己的下一行，而 `main` 正卡在傳送。整支程式只有這一個 goroutine，它睡著了，就沒有人能叫醒它。

Go 的執行環境發現「**所有** goroutine 都在睡覺」時，就會印出 `fatal error: all goroutines are asleep - deadlock!` 並結束程式，結束碼是 2。下面的 `goroutine 1 [chan send]:` 告訴你第 1 號 goroutine 卡在傳送（`chan send`），實際的輸出還會有檔案路徑和行號。

這和第 5 章的 panic 不一樣：fatal error 沒辦法用 `recover` 救回來。

改法：讓另一個 goroutine 來接收或傳送，或是用有暫存空間的 channel。

### 等 `WaitGroup` 時卡住

這是很常見的寫法錯誤：

```go,exit=2
package main

import (
	"fmt"
	"sync"
)

func main() {
	results := make(chan int)
	var wg sync.WaitGroup
	for i := 1; i <= 3; i++ {
		wg.Go(func() {
			results <- i * i
		})
	}
	wg.Wait()
	close(results)
	for r := range results {
		fmt.Println(r)
	}
}
```

執行結果（省略了後面幾行）：

```text
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [sync.WaitGroup.Wait]:
```

三個 goroutine 都卡在 `results <- i * i`，等人接收；`main` 卻卡在 `wg.Wait()`，等它們結束。互相等待，誰也動不了。

改法是把「等待並關閉」交給另一個 goroutine，`main` 馬上開始接收：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	results := make(chan int)
	var wg sync.WaitGroup
	for i := 1; i <= 3; i++ {
		wg.Go(func() {
			results <- i * i
		})
	}
	go func() {
		wg.Wait()
		close(results)
	}()

	total := 0
	for r := range results {
		total += r
	}
	fmt.Println("總和：", total)
}
```

執行結果：

```text
總和： 14
```

這個「另外開一個 goroutine 去 `Wait` 再 `close`」的寫法非常實用，第 17 集還會再用到。

### 其他常見的死結

- **忘了 `close`**：用 `for range` 接收，傳送的一方卻沒有關閉 channel，收完最後一個值就一直等下去。
- **對 `nil` channel 傳送或接收**：忘了 `make`，見上一集。
- **同一把鎖鎖兩次**：Go 的 `Mutex` 不會記得是誰鎖的，同一個 goroutine 在 `Unlock` 之前再 `Lock` 一次，也會卡住自己。

```go,exit=2
package main

import (
	"fmt"
	"sync"
)

func main() {
	var mu sync.Mutex
	mu.Lock()
	fmt.Println("鎖上一次")
	mu.Lock()
	fmt.Println("鎖上兩次")
}
```

執行結果（省略了後面幾行）：

```text
鎖上一次
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [sync.Mutex.Lock]:
```

### 偵測不到的情況

Go 只有在「**全部**」goroutine 都睡著時才會回報死結。如果只有一部分 goroutine 互相卡住，而其他 goroutine 還在跑（例如一個正在等網路回應、或正在 `time.Sleep` 的 goroutine），Go 不會報錯，那些卡住的 goroutine 就這樣默默地一直等下去。

真正的伺服器程式總會有 goroutine 在等網路連線，所以實務上看到的多半是這種「部分卡住」，程式不會當掉，卻有東西永遠做不完。下一集要談的 goroutine 洩漏，就是這種問題。

## 重點整理

- 死結是所有 goroutine 都在互相等待，沒有任何一個能繼續。
- 所有 goroutine 都睡著時，Go 會印出 `fatal error: all goroutines are asleep - deadlock!`，結束碼 2，而且無法 `recover`。
- 常見原因：unbuffered channel 沒人接收、`Wait` 和傳送互相等、忘了 `close`、`nil` channel、同一把鎖鎖兩次。
- 「等待後關閉」可以交給另一個 goroutine 做：`go func() { wg.Wait(); close(ch) }()`。
- 只有部分 goroutine 卡住時，Go 偵測不到。
