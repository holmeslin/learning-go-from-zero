# buffered channel

## 本集目標

學會建立有暫存空間的 channel，並知道它什麼時候會阻塞、什麼時候不會。

## 正文

### 加一個暫存區

上一集的 channel 沒有暫存空間，傳送的人一定要等到有人接收。`make` 加上第二個參數，就可以建立有暫存空間的 **buffered channel**（緩衝通道）：

```go,ignore
ch := make(chan string, 3)
```

這條管子裡可以先放 3 個值。就像餐廳的出餐檯：廚師把餐點放上檯子就能繼續做下一道，不必等服務生來拿；但檯子放滿了，廚師就只能等。

### 什麼時候會阻塞

| 動作 | 會阻塞的時候 |
| --- | --- |
| 傳送 `ch <- v` | 暫存區**滿了** |
| 接收 `<-ch` | 暫存區**空的** |

暫存區還有空位時，傳送馬上就完成，不用等任何人：

```go
package main

import "fmt"

func main() {
	ch := make(chan string, 3)
	ch <- "第一道菜"
	ch <- "第二道菜"
	fmt.Println("檯子上有", len(ch), "道菜，最多放", cap(ch), "道")

	fmt.Println(<-ch)
	fmt.Println(<-ch)
	fmt.Println("檯子上有", len(ch), "道菜")
}
```

執行結果：

```text
檯子上有 2 道菜，最多放 3 道
第一道菜
第二道菜
檯子上有 0 道菜
```

- 這個程式只有一個 goroutine，卻能傳送又接收，因為暫存區有空位，傳送不會卡住。換成上一集沒有暫存空間的 channel，第一個傳送就會永遠等下去。
- 先放進去的先拿出來，就像排隊一樣。
- `len(ch)` 是目前暫存區裡有幾個值，`cap(ch)` 是暫存區的大小，和第 2 章切片的 `len`、`cap` 很像。

上一集用 `make(chan string)` 建立的 channel，就是暫存區大小為 0 的 channel，也叫做 **unbuffered channel**（無緩衝通道）。

### 生產者比較快的時候

暫存區讓兩邊不必每次都碰面。下面的廚師一口氣做 3 道菜，不用等服務生：

```go
package main

import "fmt"

func main() {
	ch := make(chan string, 3)
	done := make(chan bool)

	go func() {
		for i := 1; i <= 3; i++ {
			ch <- fmt.Sprintf("第 %d 道菜", i)
		}
		done <- true
	}()

	<-done
	fmt.Println("廚師做完了，檯子上有", len(ch), "道菜")
	for range 3 {
		fmt.Println("送出", <-ch)
	}
}
```

執行結果：

```text
廚師做完了，檯子上有 3 道菜
送出 第 1 道菜
送出 第 2 道菜
送出 第 3 道菜
```

廚師的 goroutine 把 3 道菜都放上檯子，再用 `done` 通知 `main`。這裡 `<-done` 只是用來「等通知」，收到的 `true` 我們不需要，所以沒有存到變數裡。

如果把 `ch` 的大小改成 2，廚師放第 3 道菜時就會卡住，因為 `main` 正在等 `done`，沒人拿菜，兩邊互相等，程式就當掉了。這叫做死結，第 15 集會詳細說明。

### 暫存區大小怎麼決定

- 不確定時，用 unbuffered channel。它保證傳送完成時對方已經收到，程式的行為最好推理。
- 當你**確切知道**最多會有幾個值時（例如開了 5 個 goroutine，每個送一個結果），把暫存區設成那個數字，可以讓傳送的一方不必等待，第 16 集會看到這個技巧的用處。
- 不要用「設大一點」來掩蓋程式的問題。暫存區再大也會有滿的一天。

## 重點整理

- `make(chan 型別, n)` 建立暫存區大小為 `n` 的 buffered channel；`n` 是 0 或省略時就是 unbuffered channel。
- 傳送只在暫存區滿時阻塞，接收只在暫存區空時阻塞。
- 值的順序是先進先出；`len(ch)`、`cap(ch)` 可以看目前數量和容量。
- 不確定時用 unbuffered；確定數量時才設定對應的大小。
