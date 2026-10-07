# pipeline

## 本集目標

學會把資料處理拆成好幾個用 channel 串起來的階段，也就是 pipeline。

## 正文

### 像工廠的生產線

工廠的生產線上，每個工作站只做一件事：一站切割、一站組裝、一站包裝，半成品沿著輸送帶一站一站往下傳。每一站都在同時工作：包裝站在包第一件時，組裝站已經在組第二件了。

**pipeline**（管線）就是用 goroutine 和 channel 做出這樣的生產線：

- 每個**階段**是一個函式，接收一條 `<-chan`，開一個 goroutine 處理，回傳一條新的 `<-chan`。
- 上一個階段的輸出，就是下一個階段的輸入。

### 三個階段

```go
package main

import "fmt"

func generate(nums ...int) <-chan int {
	out := make(chan int)
	go func() {
		for _, n := range nums {
			out <- n
		}
		close(out)
	}()
	return out
}

func square(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		for n := range in {
			out <- n * n
		}
		close(out)
	}()
	return out
}

func onlyOdd(in <-chan int) <-chan int {
	out := make(chan int)
	go func() {
		for n := range in {
			if n%2 == 1 {
				out <- n
			}
		}
		close(out)
	}()
	return out
}

func main() {
	for n := range onlyOdd(square(generate(1, 2, 3, 4, 5))) {
		fmt.Println(n)
	}
}
```

執行結果：

```text
1
9
25
```

資料這樣流動：

```text
generate ──> square ──> onlyOdd ──> main
 1 2 3 4 5    1 4 9 16 25   1 9 25
```

每個階段都長得一樣，都是第 13 集「建立 channel、開 goroutine 傳送、回傳 `<-chan`」的寫法：

- 用 `for range in` 一直讀上一站的資料，上一站關閉時迴圈結束。
- 處理完送到自己的 `out`。
- 自己的輸入讀完了，就 `close(out)`，通知下一站「我也做完了」。

關閉就這樣一站一站往下傳，最後 `main` 的 `for range` 結束。因為只有一條線、每站都照順序處理，輸出的順序是固定的。

### 階段可以自由組合

因為每個階段的輸入和輸出型別一樣，可以像積木一樣重新排列：

```go,ignore
square(square(generate(1, 2, 3))) // 1 16 81
onlyOdd(generate(1, 2, 3, 4, 5))  // 1 3 5
```

要新增一個處理步驟，只要再寫一個同樣形狀的函式，接到線上就好。

### 某一站特別慢的時候

如果其中一個階段特別慢，可以讓好幾個 goroutine 同時讀同一條輸入 channel 來分擔，就像上一集的 worker pool；再用 `WaitGroup` 等它們都做完後關閉輸出。這種「一條分給多個、多個合成一條」的做法叫做 fan-out／fan-in。代價是輸出的順序就不再固定了。

### 小心提早離開

如果 `main` 只想拿前兩個結果就 `break`，後面的階段還會繼續送資料，卻沒有人接收，整條線的 goroutine 都會卡住，也就是第 16 集的 goroutine 洩漏。要讓 pipeline 可以中途停下來，每一站都得注意一條停止通知的 channel，實務上會用第 10 章的 `context` 來做。

### 和迭代器的比較

第 7 章的迭代器也能把資料一個一個傳下去，而且更簡單、更快。如果不需要「好幾站同時工作」，用迭代器就好；pipeline 的好處在於每一站都在自己的 goroutine 裡**同時**運作，適合每一站都要花時間等待（例如讀檔、呼叫網路服務）的情況。

## 重點整理

- pipeline 是用 channel 串起來的多個階段，每個階段在自己的 goroutine 裡同時工作。
- 每個階段：接收 `<-chan`、`for range` 讀輸入、處理後送出、讀完就 `close(out)`、回傳 `<-chan`。
- 關閉會一站一站往下傳，讓整條線自然結束。
- 中途停止需要停止通知（之後用 `context`），否則會造成 goroutine 洩漏；不需要並行時，迭代器更簡單。
