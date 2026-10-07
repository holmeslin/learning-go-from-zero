# 單向 channel

## 本集目標

學會在函式參數和回傳值上標示 channel 只能傳送或只能接收，讓編譯器幫忙抓錯。

## 正文

### 只用一半的管子

到目前為止，我們的 channel 都是雙向的：誰拿到都可以傳送，也可以接收。但實際上，一個函式通常只用其中一邊：負責生產資料的只會傳送，負責消費的只會接收。

Go 可以在型別上標示方向：

| 型別 | 意思 | 箭頭的位置 |
| --- | --- | --- |
| `chan int` | 雙向 | 沒有箭頭 |
| `chan<- int` | 只能傳送 | 箭頭指進 `chan` |
| `<-chan int` | 只能接收 | 箭頭從 `chan` 指出來 |

記法和傳送、接收的寫法一樣：箭頭指向 `chan` 就是把資料放進去。

### 在參數上標示方向

```go
package main

import "fmt"

func produce(out chan<- int) {
	for i := 1; i <= 3; i++ {
		out <- i * 10
	}
	close(out)
}

func consume(in <-chan int) {
	for v := range in {
		fmt.Println("處理", v)
	}
}

func main() {
	ch := make(chan int)
	go produce(ch)
	consume(ch)
}
```

執行結果：

```text
處理 10
處理 20
處理 30
```

`main` 裡的 `ch` 是雙向的 `chan int`。傳給 `produce` 時會自動轉成只能傳送的 `chan<- int`，傳給 `consume` 時自動轉成只能接收的 `<-chan int`。反過來，單向的 channel 沒辦法轉回雙向。

### 編譯器幫你把關

標了方向之後，用錯邊就無法編譯。例如在 `consume` 裡不小心傳送：

```go,compile_fail
package main

func consume(in <-chan int) {
	in <- 1
}

func main() {
	ch := make(chan int)
	go consume(ch)
}
```

編譯錯誤：

```text
./main.go:4:2: invalid operation: cannot send to receive-only channel <-chan int in (variable of type <-chan int)
```

`close` 也一樣：只能接收的 channel 不能 `close`，因為照第 10 集的規則，關閉是傳送那一方的事。這樣一來，「消費者不小心關掉 channel」這種錯誤在編譯時就會被擋下來。

### 回傳只能接收的 channel

另一個常見的寫法，是讓函式自己建立 channel、開 goroutine 往裡面送資料，然後回傳一個 `<-chan`：

```go
package main

import "fmt"

func countTo(n int) <-chan int {
	out := make(chan int)
	go func() {
		for i := 1; i <= n; i++ {
			out <- i
		}
		close(out)
	}()
	return out
}

func main() {
	for v := range countTo(3) {
		fmt.Println(v)
	}
}
```

執行結果：

```text
1
2
3
```

呼叫的人只拿得到接收的那一頭，不能往裡面亂塞資料，也不能關閉它。第 18 集的 pipeline 會大量使用這種寫法。

上一集的 `time.After` 也是這樣，它的回傳型別就是只能接收的 `<-chan time.Time`。

## 重點整理

- `chan<- T` 只能傳送，`<-chan T` 只能接收，`chan T` 是雙向。
- 雙向 channel 可以自動轉成單向，反過來不行。
- 在參數和回傳值上標示方向，用錯邊（包括對只能接收的 channel 呼叫 `close`）會編譯錯誤。
- 「函式建立 channel、開 goroutine 傳送、回傳 `<-chan`」是常見的寫法。
