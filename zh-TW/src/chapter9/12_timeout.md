# 逾時與 `time.After`

## 本集目標

學會用 `select` 加上 `time.After`，讓等待有時間上限，超過就放棄。

## 正文

### 不能一直等下去

上一集的 `select` 會等到某個 channel 有動靜為止。可是如果對方永遠不回應呢？例如查詢一個很慢的服務，使用者不會想等一分鐘。我們需要的是：「最多等 100 毫秒，等不到就放棄。」

### `time.After`

`time.After(d)` 會回傳一個 channel，經過 `d` 這段時間之後，這個 channel 會收到一個值（當時的時間）。把它放進 `select`，就是一個鬧鐘：

```go
package main

import (
	"fmt"
	"time"
)

func slowSearch(result chan string) {
	time.Sleep(500 * time.Millisecond)
	result <- "找到了"
}

func main() {
	result := make(chan string, 1)
	go slowSearch(result)

	select {
	case r := <-result:
		fmt.Println(r)
	case <-time.After(100 * time.Millisecond):
		fmt.Println("等太久了，不等了")
	}
}
```

執行結果（某一次）：

```text
等太久了，不等了
```

- 這次 `select` 走第二個 `case`：`slowSearch` 至少等 500 毫秒才送結果，鬧鐘設成 100 毫秒，通常會先逾時。
- `case <-time.After(...)`：我們只在乎鬧鐘響了沒，不需要收到的時間值，所以箭頭左邊沒有變數。
- 如果把 `slowSearch` 裡的 500 改成 10，通常會印出「找到了」。但時間長短不保證排程順序；如果選擇時結果和鬧鐘都準備好了，`select` 會隨機挑一個，也不保證剛好在第 100 毫秒就執行逾時分支。

注意 `result` 我們給了 1 格暫存區。逾時之後 `main` 不再接收；只要程式還在執行，`slowSearch` 做完時仍能把唯一的結果放進暫存區，不會卡在傳送那一行。逾時沒有取消它，也沒有等待它完成；這支範例的 `main` 一回傳，整支程式就結束了。如果程式繼續執行卻用 unbuffered channel，沒人接收的傳送就會一直卡住。第 16 集會詳細說明這個問題。

### 在迴圈裡使用

`time.After` 也常寫在迴圈裡，例如「一直收訊息，超過 200 毫秒沒有新訊息就結束」：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	messages := make(chan string)
	go func() {
		for _, m := range []string{"早安", "午安", "晚安"} {
			time.Sleep(20 * time.Millisecond)
			messages <- m
		}
	}()

	for {
		select {
		case m := <-messages:
			fmt.Println("收到", m)
		case <-time.After(200 * time.Millisecond):
			fmt.Println("200 毫秒沒有新訊息，結束")
			return
		}
	}
}
```

執行結果（某一次）：

```text
收到 早安
收到 午安
收到 晚安
200 毫秒沒有新訊息，結束
```

每一圈都呼叫一次 `time.After`，建立一個新的鬧鐘；收到訊息之後，這一圈的鬧鐘就不再有人理會。這次三則訊息都在逾時分支被選到前送達；若 goroutine 遲遲沒被排程，也可能提早選到逾時分支、少收到幾則訊息。

### 網路上的舊說法

你可能會在網路文章看到「不要在迴圈裡用 `time.After`，沒響的鬧鐘不會被回收，會造成記憶體洩漏，要改用 `time.NewTimer` 再呼叫 `Stop`」。**這是 Go 1.23 以前的說法**，現在已經不成立了：

- Go 1.23 起，沒有人再使用的鬧鐘，就算還沒響，也會被自動回收。`go doc time.After` 寫得很清楚：當 `time.After` 就夠用時，沒有理由改用 `NewTimer`。
- 舊文章還會提到鬧鐘的 channel 有 1 格暫存、要先清空才能重設之類的技巧。Go 1.23 起 `time` 套件建立的 channel 改成沒有暫存空間，這些技巧都不需要了；Go 1.27 更移除了切回舊行為的 `asynctimerchan` 設定，現在一律是新的行為。

所以放心在迴圈裡用 `time.After`。`time.NewTimer` 等其他計時工具，第 12 章介紹 `time` 套件時再說。

### 預告：`context`

真實的程式裡，「逾時」常常要一路傳給很多函式，例如一個請求要在 2 秒內完成，中間呼叫的每個函式都要知道還剩多少時間。這需要第 10 章的 `context`。本集的 `select` 加 `time.After`，適合單一個地方的簡單等待。

## 重點整理

- `time.After(d)` 回傳一個 channel，經過 `d` 之後會收到一個值。
- `select` 搭配 `case <-time.After(d):` 可設定逾時分支，但不保證精確的執行時間；多個分支都準備好時會隨機選擇。
- 逾時不會取消或等待背景工作；此例的 1 格暫存區能讓唯一一次傳送不因沒人接收而卡住。
- Go 1.23 起在迴圈中使用 `time.After` 不會洩漏記憶體，Go 1.27 起計時器的 channel 一律沒有暫存空間。
