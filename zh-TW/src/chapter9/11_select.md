# `select`

## 本集目標

學會用 `select` 同時等待好幾個 channel，哪個先準備好就處理哪個，並用 `default` 做到「不等待」。

## 正文

### 同時等好幾個 channel

假設你同時跟兩家店訂了外送，哪一家先到就先開門拿。如果寫成：

```go,ignore
a := <-shopA
b := <-shopB
```

就會先死等 A 店，就算 B 店早就到了也不理它。`select` 可以讓我們**同時**等好幾個 channel：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	pizza := make(chan string)
	noodles := make(chan string)

	go func() {
		time.Sleep(50 * time.Millisecond)
		pizza <- "披薩"
	}()
	go func() {
		time.Sleep(10 * time.Millisecond)
		noodles <- "牛肉麵"
	}()

	for range 2 {
		select {
		case food := <-pizza:
			fmt.Println("收到", food)
		case food := <-noodles:
			fmt.Println("收到", food)
		}
	}
}
```

執行結果：

```text
收到 牛肉麵
收到 披薩
```

`select` 的寫法很像第 1 章的 `switch`，但每個 `case` 都是一個 channel 的操作：

- `select` 會等到其中**某一個** `case` 可以進行（這裡是某個 channel 有值可以接收），就執行那個 `case`，然後結束整個 `select`。
- 牛肉麵 10 毫秒就送到，披薩要 50 毫秒，所以第一圈收到牛肉麵，第二圈收到披薩。
- 一次 `select` 只會執行一個 `case`，所以我們用迴圈跑兩次。

`case` 也可以是傳送，例如 `case ch <- v:`，表示「如果現在送得出去，就送」。

### 同時準備好的時候

如果好幾個 `case` 剛好**同時**都可以進行，`select` 會**隨機**挑一個，不是照寫的順序。這是故意的設計，避免排在前面的 channel 永遠優先、後面的一直輪不到。所以不要依賴 `case` 的順序。

### `default`：不想等

`select` 可以加一個 `default`。如果所有 `case` 都還不能進行，就馬上執行 `default`，不會停下來等。下面這個訊息箱只放得下一則訊息，滿了就把新訊息丟掉：

```go
package main

import "fmt"

func main() {
	inbox := make(chan string, 1)
	for i := 1; i <= 3; i++ {
		select {
		case inbox <- fmt.Sprintf("訊息 %d", i):
			fmt.Println("放進訊息", i)
		default:
			fmt.Println("箱子滿了，丟掉訊息", i)
		}
	}

	select {
	case msg := <-inbox:
		fmt.Println("讀到", msg)
	default:
		fmt.Println("沒有訊息")
	}
}
```

執行結果：

```text
放進訊息 1
箱子滿了，丟掉訊息 2
箱子滿了，丟掉訊息 3
讀到 訊息 1
```

- 第一圈，暫存區有空位，傳送可以進行，選中第一個 `case`。
- 第二、三圈，暫存區滿了，傳送會阻塞，所以走 `default`。
- 最後的 `select` 用同樣的方式「有就拿，沒有就算了」。

沒有 `default` 的 `select` 會一直等；有 `default` 的 `select` 絕對不會等。不要在迴圈裡用帶 `default` 的 `select` 反覆檢查，那會讓 CPU 一直空轉。

### 空的 `select`

`select {}` 沒有任何 `case`，會永遠等下去。偶爾會在「`main` 什麼都不做，只想讓其他 goroutine 一直跑」的程式裡看到它，知道是什麼意思就好。

## 重點整理

- `select` 同時等待好幾個 channel 操作，哪個先可以進行就執行哪個 `case`，只執行一個。
- 好幾個 `case` 同時可以進行時，隨機挑一個。
- 加上 `default` 後，所有 `case` 都不能進行時會立刻執行 `default`，不會等待。
- 沒有 `case` 的 `select {}` 會永遠阻塞。
