# `sync.WaitGroup` 與 `wg.Go`

## 本集目標

學會用 `sync.WaitGroup` 等所有 goroutine 做完再繼續，並看懂 `wg.Go` 和傳統 `Add`／`Done` 兩種寫法。

## 正文

### 等大家都做完

上一集用 `time.Sleep` 猜時間，不可靠。`sync` 套件的 `WaitGroup` 可以真正做到「等一群 goroutine 全部結束」。

`WaitGroup` 就像一張點名表：每開始一件工作就登記一筆，工作做完就劃掉一筆，`Wait` 會一直等到表上全部劃掉為止。

### `wg.Go`

Go 1.25 起，`WaitGroup` 有一個 `Go` 方法，把「登記」「開 goroutine」「做完劃掉」三件事一次包辦：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	for i := range 3 {
		wg.Go(func() {
			fmt.Println("工作", i, "完成")
		})
	}
	wg.Wait()
	fmt.Println("全部完成")
}
```

執行結果（某一次）：

```text
工作 2 完成
工作 1 完成
工作 0 完成
全部完成
```

一步一步看：

- `var wg sync.WaitGroup`：`WaitGroup` 的零值就能直接用，不需要初始化（第 3 章「讓零值有用」提過這種設計）。
- `wg.Go(func() { ... })`：在新的 goroutine 裡執行這個匿名函式，並在點名表上登記一筆；函式回傳時自動劃掉。
- `wg.Wait()`：等到所有登記的工作都結束才往下走。

三個「工作」的順序每次都可能不同，但「全部完成」一定在最後，因為 `Wait` 會等它們全部結束。

匿名函式裡直接用了迴圈變數 `i`。第 6 章說過，Go 1.22 起每一圈的 `i` 都是各自獨立的變數，所以每個 goroutine 看到的是自己那一圈的 `i`，不會互相干擾。

### 讓輸出有固定順序

如果希望結果照順序印出，可以讓每個 goroutine 把結果寫到切片裡「自己的格子」，等 `Wait` 之後再由 `main` 依序印：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	words := []string{"蘋果", "香蕉", "櫻桃"}
	lengths := make([]int, len(words))

	var wg sync.WaitGroup
	for i, w := range words {
		wg.Go(func() {
			lengths[i] = len([]rune(w))
		})
	}
	wg.Wait()

	for i, w := range words {
		fmt.Println(w, lengths[i])
	}
}
```

執行結果：

```text
蘋果 2
香蕉 2
櫻桃 2
```

每個 goroutine 只寫 `lengths[i]` 這一格，彼此不碰同一個位置；`main` 等 `Wait` 回傳之後才讀，這時大家都寫完了。這是安全的寫法。如果好幾個 goroutine 同時改**同一個**變數，就會出問題，下一集會說明。

### 傳統寫法：`Add` 與 `Done`

`wg.Go` 是比較新的寫法，你在別人的程式裡會常常看到 Go 1.25 以前的傳統寫法：

```go,ignore
var wg sync.WaitGroup
for i := range 3 {
	wg.Add(1)
	go func() {
		defer wg.Done()
		fmt.Println("工作", i, "完成")
	}()
}
wg.Wait()
```

- `wg.Add(1)`：點名表登記一筆。
- `go func() { ... }()`：自己開 goroutine。
- `defer wg.Done()`：函式結束時劃掉一筆。用第 5 章的 `defer`，就算中途 `return` 也不會忘記。

有一個規則要特別注意：**`Add` 要在 `go` 之前呼叫，不能寫在 goroutine 裡面**。如果寫在裡面，`main` 可能在新的 goroutine 還沒來得及 `Add` 之前就呼叫了 `Wait`，這時點名表是空的，`Wait` 就直接回傳了。`wg.Go` 幫我們處理好這件事，這也是它比較不容易寫錯的原因。

### 兩個小提醒

- 用 `wg.Go` 時，傳進去的函式不可以 panic（`go doc sync.WaitGroup.Go` 有寫）。
- `WaitGroup` 開始使用之後就不能複製。要把它交給別的函式時，一律傳指標 `*sync.WaitGroup`。複製了的話，`go vet` 會警告你。

## 重點整理

- `sync.WaitGroup` 用來等待一群 goroutine 全部結束；零值就能用。
- Go 1.25 起用 `wg.Go(func() { ... })` 開 goroutine，再用 `wg.Wait()` 等待。
- 傳統寫法是 `wg.Add(1)`、`go func() { defer wg.Done(); ... }()`，`Add` 必須在 `go` 之前。
- 想要固定順序的輸出，可以讓每個 goroutine 寫切片中自己的格子，`Wait` 之後再印。
- `WaitGroup` 不能複製，要傳給函式時傳指標。
