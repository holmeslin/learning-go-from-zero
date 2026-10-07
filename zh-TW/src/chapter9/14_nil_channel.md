# nil channel

## 本集目標

知道 `nil` channel 的行為，並學會在 `select` 裡把 channel 設成 `nil` 來「關掉」某個 `case`。

## 正文

### channel 的零值是 `nil`

和切片、map 一樣，只宣告不 `make` 的 channel，值是 `nil`：

```go,ignore
var ch chan int // ch 是 nil
```

`nil` channel 的行為很特別：

| 動作 | 結果 |
| --- | --- |
| 傳送 `ch <- v` | 永遠阻塞 |
| 接收 `<-ch` | 永遠阻塞 |
| `close(ch)` | panic：`close of nil channel` |

「永遠阻塞」聽起來沒什麼用，忘了 `make` 時還會讓程式卡住。但在 `select` 裡，這個特性剛好很好用。

### 在 `select` 裡，`nil` 的 `case` 永遠不會被選中

`select` 只會選「可以進行」的 `case`。對 `nil` channel 的操作永遠不能進行，所以那個 `case` 就等於不存在。換句話說：**把 channel 變數設成 `nil`，就能關掉 `select` 裡對應的 `case`**。

### 合併兩個 channel

假設有兩個來源各自送出一些數字，送完就關閉。我們想把兩邊的數字全部收齊：

```go
package main

import (
	"fmt"
	"slices"
)

func send(nums []int) <-chan int {
	out := make(chan int)
	go func() {
		for _, n := range nums {
			out <- n
		}
		close(out)
	}()
	return out
}

func main() {
	a := send([]int{1, 3, 5})
	b := send([]int{2, 4})

	var all []int
	for a != nil || b != nil {
		select {
		case n, ok := <-a:
			if !ok {
				a = nil
				continue
			}
			all = append(all, n)
		case n, ok := <-b:
			if !ok {
				b = nil
				continue
			}
			all = append(all, n)
		}
	}
	slices.Sort(all)
	fmt.Println(all)
}
```

執行結果：

```text
[1 2 3 4 5]
```

一步一步看：

- 用第 10 集的 comma-ok 判斷 channel 關了沒。`ok` 是 `false` 時，把那個變數設成 `nil`，之後 `select` 就不會再選它。
- 兩個都變成 `nil` 時，`for` 的條件不成立，迴圈結束。
- 兩邊送來的順序不固定，所以最後用 `slices.Sort` 排序再印，輸出才會一致。

### 如果不設成 `nil` 會怎樣

第 10 集說過，從已經關閉的 channel 接收，會**馬上**拿到零值。假設 `a` 先關了，卻沒有設成 `nil`：每次 `select` 時，`a` 的 `case` 都能立刻進行，`select` 會一直選到它，迴圈不停空轉，還可能把一堆 0 加進結果裡。設成 `nil` 正是為了避免這種情況。

### 不要忘了 `make`

另一方面，`nil` channel 也是常見的錯誤來源：宣告了 `var ch chan int` 卻忘了 `make`，接下來的傳送或接收就會永遠卡住。如果所有 goroutine 都卡住，Go 會回報死結，下一集就來看這個錯誤。

## 重點整理

- channel 的零值是 `nil`；對 `nil` channel 傳送或接收會永遠阻塞，`close` 會 panic。
- `select` 裡對 `nil` channel 的 `case` 永遠不會被選中。
- 合併多個 channel 時，某個 channel 關閉後把變數設成 `nil`，就能停用那個 `case`。
- 所有來源都變成 `nil` 時就可以結束迴圈。
