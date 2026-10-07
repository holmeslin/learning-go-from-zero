# `close` 與 `range` channel

## 本集目標

學會用 `close` 告訴接收的一方「不會再有資料了」，並用 `for range` 一直接收到 channel 被關閉為止。

## 正文

### 不知道會有幾個值

前面的範例，接收的一方都事先知道要收幾次。可是很多時候，只有傳送的一方才知道什麼時候送完。這時傳送的一方可以呼叫內建函式 `close`，把 channel 關起來，意思是「我送完了」。

### `for range` 接收到關閉為止

`for range` 可以走訪 channel：每次迴圈接收一個值，channel 被關閉、而且裡面的值都拿完之後，迴圈就結束：

```go
package main

import "fmt"

func countdown(n int, ch chan int) {
	for i := n; i > 0; i-- {
		ch <- i
	}
	close(ch)
}

func main() {
	ch := make(chan int)
	go countdown(3, ch)
	for n := range ch {
		fmt.Println(n)
	}
	fmt.Println("發射！")
}
```

執行結果：

```text
3
2
1
發射！
```

`main` 完全不用知道會收到幾個數字。如果 `countdown` 忘了 `close(ch)`，`main` 的 `for range` 收完 1 之後會一直等下一個值，程式就卡住了。

走訪 channel 的 `for range` 只有一個變數，就是收到的值，沒有索引。

### comma-ok：判斷 channel 是不是關了

從已經關閉、而且空了的 channel 接收，不會阻塞，而是**馬上拿到該型別的零值**。為了分辨「真的收到 0」和「已經關了」，可以用第 2 章學過的 comma-ok 寫法：

```go
package main

import "fmt"

func main() {
	ch := make(chan int, 2)
	ch <- 10
	close(ch)

	v, ok := <-ch
	fmt.Println(v, ok)
	v, ok = <-ch
	fmt.Println(v, ok)
}
```

執行結果：

```text
10 true
0 false
```

- 關閉之前送進去的 10，關閉之後還是收得到，`ok` 是 `true`。
- 值都拿完之後，收到零值 0，`ok` 是 `false`，代表 channel 已經關閉。

`for range` 其實就是幫我們做了這件事：`ok` 變成 `false` 時結束迴圈。

### 關閉的規則

- **由傳送的一方關閉**，接收的一方不要關。因為只有傳送的一方知道什麼時候送完。
- 對已經關閉的 channel **傳送**，會 panic。
- 把同一個 channel **關兩次**，也會 panic。
- channel 不一定要關閉。只有當接收的一方需要知道「已經沒有資料了」（例如用了 `for range`），才需要 `close`。它和檔案不一樣，不關也不會浪費資源。

我們實際看看對關閉的 channel 傳送會怎樣：

```go,exit=2
package main

import "fmt"

func main() {
	ch := make(chan int, 1)
	close(ch)
	fmt.Println("關閉了")
	ch <- 1
}
```

執行結果（省略了後面幾行）：

```text
關閉了
panic: send on closed channel

goroutine 1 [running]:
main.main()
```

好幾個 goroutine 都在傳送時，誰來關閉呢？要等它們全部送完才能關，這時就要用到 `WaitGroup`，第 17 集的 worker pool 會示範。

## 重點整理

- `close(ch)` 表示不會再送資料；關閉前送進去的值仍然收得到。
- `for v := range ch` 會一直接收，直到 channel 關閉而且值都拿完。
- `v, ok := <-ch` 的 `ok` 為 `false` 代表 channel 已關閉且空了，這時 `v` 是零值。
- 由傳送的一方關閉；對已關閉的 channel 傳送或重複關閉都會 panic。
