# goroutine

## 本集目標

學會用 `go` 關鍵字讓一個函式在背景執行，並知道 `main` 結束時，其他 goroutine 會跟著一起結束。

## 正文

### 同時做好幾件事

想像你在廚房煮飯：把米放進電鍋按下開關之後，你不會站在電鍋前面等它煮好，而是轉身去切菜。電鍋和你「同時」在工作。

Go 裡面，一段可以和其他程式碼同時執行的工作叫做 **goroutine**。其實我們從第 1 章就一直在用 goroutine 了：`main` 函式本身就是在一個 goroutine 裡執行的，叫做「main goroutine」。第 5 章 panic 的輸出裡出現過的 `goroutine 1 [running]:`，指的就是它。

### `go` 關鍵字

要開一個新的 goroutine，只要在函式呼叫前面加上 `go`：

```go,ignore
go say("哈囉")
```

這行的意思是「開一個新的 goroutine 去執行 `say("哈囉")`，我不等它，直接往下走」。沒有 `go` 的話，`main` 會等 `say` 執行完才繼續；加了 `go`，`main` 馬上就接著執行下一行。

我們來試試看：

```go
package main

import "fmt"

func say(word string) {
	for i := range 3 {
		fmt.Println(word, i)
	}
}

func main() {
	go say("背景")
	fmt.Println("main 結束")
}
```

執行結果（某一次）：

```text
main 結束
```

咦？`say` 裡的內容一行都沒印出來。

### `main` 結束，大家一起結束

原因是：**`main` 函式一回傳，整支程式就結束了，其他還在跑的 goroutine 會被直接中止**，不管它們做完了沒有。

上面的程式裡，`main` 開了新的 goroutine 之後，馬上印出「main 結束」然後回傳。新的 goroutine 很可能還來不及開始，程式就已經結束了。標題寫「某一次」是因為結果並不固定：偶爾新的 goroutine 動作比較快，可能會印出一兩行。goroutine 什麼時候開始、跑多快，是由 Go 的執行環境（runtime）安排的，我們沒辦法控制。

### 最粗糙的辦法：睡一下

既然問題是 `main` 太早結束，那就讓 `main` 等一下。`time.Sleep` 可以讓目前的 goroutine 暫停一段時間（`time` 套件第 12 章會正式介紹，這裡只用 `time.Sleep(100 * time.Millisecond)` 這種寫法，意思是暫停 100 毫秒）：

```go
package main

import (
	"fmt"
	"time"
)

func say(word string) {
	for i := range 3 {
		fmt.Println(word, i)
	}
}

func main() {
	go say("背景")
	say("前景")
	time.Sleep(100 * time.Millisecond)
	fmt.Println("main 結束")
}
```

執行結果（某一次）：

```text
前景 0
前景 1
前景 2
背景 0
背景 1
背景 2
main 結束
```

這次「背景」和「前景」都印出來了。不過這兩組的先後順序每次執行都可能不同，有時候會交錯在一起。這正是並行的特性：**兩個 goroutine 之間誰先誰後，沒有保證**。

### 為什麼睡一下不可靠

`time.Sleep` 只是「猜」背景工作大概多久會做完。這個猜法有兩個問題：

- 猜太短：電腦剛好很忙，背景工作還沒做完，程式就結束了，結果還是少印東西。
- 猜太長：背景工作早就做完了，程式卻還在白白等待。

真正的程式不應該靠猜。我們需要的是「等到背景工作真的做完為止」，下一集的 `sync.WaitGroup` 就是做這件事的。

### 匿名函式也可以

`go` 後面可以接任何函式呼叫，包括第 6 章學過的匿名函式。注意最後的 `()`：我們是在**呼叫**這個匿名函式，不是只寫出它：

```go,ignore
go func() {
	fmt.Println("我在另一個 goroutine 裡")
}()
```

這種寫法在並行程式裡非常常見。

## 重點整理

- goroutine 是可以和其他程式碼同時執行的工作；`main` 本身也在一個 goroutine 裡執行。
- 在函式呼叫前加 `go`，就會開一個新的 goroutine 執行它，呼叫的地方不會等它。
- `main` 回傳時整支程式結束，其他 goroutine 會被直接中止。
- 不同 goroutine 的執行順序沒有保證；用 `time.Sleep` 等待只是猜測，不可靠。
