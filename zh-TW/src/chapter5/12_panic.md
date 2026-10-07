# `panic`

## 本集目標

認識 `panic`：程式遇到無法繼續的狀況時會發生什麼事，以及什麼時候該用 `error`、什麼時候會遇到 `panic`。

## 正文

### 程式「當掉」了

到目前為止，錯誤都是用 `error` 回傳值好好地交給呼叫者。但有些錯誤嚴重到程式根本沒辦法繼續，例如存取切片裡不存在的位置：

```go,exit=2
package main

import "fmt"

func main() {
	scores := []int{90, 85, 70}
	fmt.Println("開始")
	i := 5
	fmt.Println(scores[i])
	fmt.Println("結束")
}
```

執行結果（省略了後面幾行）：

```text
開始
panic: runtime error: index out of range [5] with length 3

goroutine 1 [running]:
main.main()
```

`scores` 只有 3 個元素，卻要拿第 5 個。這時 Go 不會回傳 `error`，而是直接 **panic**（恐慌）：

- 程式立刻停在這一行，`"結束"` 沒有印出來。
- 印出 `panic:` 加上原因，然後是一段「堆疊追蹤」（stack trace），告訴你是哪個函式、哪一行出事。實際的輸出後面還有檔案路徑和行號，這裡省略了。
- 程式以結束碼 2 結束，代表異常終止。

除了索引超出範圍，對 `nil` 的 map 寫入、透過 `nil` 指標存取欄位，也都會造成 panic。

### 自己呼叫 `panic`

也可以自己呼叫內建的 `panic` 函式，參數是任何值，通常放一段說明文字：

```go,exit=2
package main

import "fmt"

func mustPositive(n int) int {
	if n <= 0 {
		panic("n 必須是正數")
	}
	return n
}

func main() {
	fmt.Println(mustPositive(3))
	fmt.Println(mustPositive(-1))
	fmt.Println("這行不會執行")
}
```

執行結果（省略了後面幾行）：

```text
3
panic: n 必須是正數

goroutine 1 [running]:
main.mustPositive(...)
```

### panic 時，`defer` 照樣會執行

panic 發生後，程式不是馬上停止，而是先把目前函式裡已經 `defer` 的呼叫都執行完，再往呼叫它的函式回去，一路執行各層的 `defer`，最後才結束程式：

```go,exit=2
package main

import "fmt"

func main() {
	defer fmt.Println("defer 還是會執行")
	panic("出大事了")
}
```

執行結果（省略了後面幾行）：

```text
defer 還是會執行
panic: 出大事了

goroutine 1 [running]:
main.main()
```

所以用 `defer` 寫的收尾工作，就算遇到 panic 也會做完。

### 什麼時候該 panic？

答案是：**幾乎不要**。

- 可以預期的失敗，例如使用者輸入錯誤、找不到資料、網路斷線，一律用 `error` 回傳，讓呼叫者決定怎麼處理。
- `panic` 只留給「程式本身寫錯了」的情況，也就是照理說絕對不該發生的事，例如程式設計上的 bug。

一般寫程式時，你比較常「遇到」panic（通常是 bug，要去修程式），而不是自己「寫」panic。

## 重點整理

- panic 代表程式遇到無法繼續的狀況，會停止目前的流程，印出原因和堆疊追蹤，以結束碼 2 結束。
- 索引超出範圍、寫入 `nil` map、`nil` 指標取欄位都會造成 panic；也可以自己呼叫 `panic(值)`。
- panic 發生後，已經 `defer` 的呼叫仍然會執行。
- 可預期的錯誤用 `error`，`panic` 只用在程式本身有 bug 的情況。
