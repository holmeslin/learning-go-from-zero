# channel

## 本集目標

學會建立 channel，並用 `<-` 在 goroutine 之間傳送和接收資料。

## 正文

### goroutine 之間的管子

前面幾集，goroutine 之間共用變數，再用鎖保護。Go 還有另一種想法：**把資料「交給」對方處理，而不是同時共用並修改它**。

**channel**（通道）就像一條連接兩個 goroutine 的管子：一邊把資料放進去，另一邊從管子另一頭拿出來。Go 社群有一句常被引用的話：「不要用共享記憶體來溝通，而要用溝通來共享記憶體。」說的就是這個。

### 建立、傳送、接收

```go
package main

import "fmt"

func main() {
	ch := make(chan string)
	go func() {
		ch <- "飯煮好了"
	}()
	msg := <-ch
	fmt.Println(msg)
}
```

執行結果：

```text
飯煮好了
```

- `make(chan string)`：建立一個傳送 `string` 的 channel。型別寫成 `chan string`，channel 和 map 一樣要用 `make` 建立。
- `ch <- "飯煮好了"`：**傳送**。箭頭指向 channel，表示把值放進去。
- `msg := <-ch`：**接收**。箭頭從 channel 指出來，表示把值拿出來。

一個 channel 只能傳一種型別的資料，`chan string` 只能傳字串，`chan int` 只能傳整數。

### 傳送和接收會互相等待

注意這次我們**沒有**用 `time.Sleep`，也沒有用 `WaitGroup`，`main` 卻乖乖等到了背景 goroutine 的訊息。這是因為：

- 用 `make(chan string)` 建立的 channel 沒有暫存空間。傳送的一方會**停在那裡等**，直到有人來接收。
- 接收的一方也一樣，會**停在那裡等**，直到有人傳送。

所以 `main` 執行到 `msg := <-ch` 時，會一直等，等背景 goroutine 送出資料才繼續。像接力賽交棒一樣，兩個人要在同一個時間點碰面，資料才交得出去。這種「停下來等」叫做**阻塞**（block）。

### 收集好幾個 goroutine 的結果

channel 很適合用來收集結果。下面開 5 個 goroutine 各算一個平方，`main` 接收 5 次再加總：

```go
package main

import "fmt"

func square(n int, ch chan int) {
	ch <- n * n
}

func main() {
	ch := make(chan int)
	for i := 1; i <= 5; i++ {
		go square(i, ch)
	}

	total := 0
	for range 5 {
		total += <-ch
	}
	fmt.Println("平方和：", total)
}
```

執行結果：

```text
平方和： 55
```

- channel 可以當參數傳給函式，型別寫 `chan int`。channel 本身就是一個「參照」，傳給函式不會複製出另一條管子，雙方用的是同一條。
- 5 個 goroutine 送出的順序不一定，但加法和順序無關，所以結果固定是 1 + 4 + 9 + 16 + 25 = 55。
- `main` 剛好接收 5 次，因為我們知道會有 5 個值送進來。如果多收一次，就會永遠等下去，第 15 集會看到這種情況。

這個平方和範例只傳整數，每個 goroutine 算自己的值，只有 `main` 修改 `total`，沒有共同修改資料，所以沒有 data race。

### 傳送切片仍會共用資料

channel 傳送的是值，不會自動深複製。傳切片只會複製它的 header，雙方仍指向同一個底層陣列。傳 map 或指標時，也仍可能共用資料。

下面把切片交給背景 goroutine 修改，等它用另一個 channel 通知完成後，`main` 才讀取：

```go
package main

import "fmt"

func main() {
	numbers := []int{1, 2, 3}
	ch := make(chan []int)
	done := make(chan bool)
	go func() {
		received := <-ch
		received[0] = 100
		done <- true
	}()
	ch <- numbers
	<-done
	fmt.Println(numbers)
}
```

執行結果：

```text
[100 2 3]
```

原本的 `numbers` 也變了，證明資料沒有被隔離。這裡約定：傳送端交出資料後，先不再讀寫它，直到接收端通知完成。這是雙方約定的**所有權**交接，不是 Go 自動強制的規則。

如果在 `ch <- numbers` 之後、`<-done` 之前加上 `numbers[0] = 200`，就會和背景 goroutine 的寫入形成 data race。傳送前的寫入會透過 channel 同步給接收端，但傳送後繼續修改共用資料，不會自動和接收端的操作排好順序。

所以要遵守交接約定，或另外用同一把 `Mutex` 等同步工具保護共用資料；不能只因為用了 channel，就認為沒有 data race。

### channel 和鎖怎麼選

- 要把資料**交給**另一個 goroutine，或是要讓 goroutine 之間**互相通知**、等待，用 channel。
- 好幾個 goroutine 要**共同修改**一份資料（例如一個計數器、一個 map），用 `Mutex` 或 atomic 通常比較簡單。

兩種都是正確的工具，選讓程式比較好懂的那一種。

## 重點整理

- channel 用 `make(chan 型別)` 建立，用來在 goroutine 之間傳遞資料。
- `ch <- v` 傳送、`v := <-ch` 接收；箭頭方向就是資料流動的方向。
- 沒有暫存空間的 channel，傳送和接收會互相等待，可以用來同步。
- 傳切片、map 或指標仍可能共用資料；交出後遵守所有權約定，或另外同步，才能避免 data race。
