# 記憶體模型

## 本集目標

用直覺理解 Go 記憶體模型的核心概念 happens-before，知道為什麼 data race 一定是錯的，以及哪些工具能建立「先後」關係。

## 正文

### 一個看起來沒問題的程式

```go
package main

import (
	"fmt"
	"time"
)

var message string
var ready bool

func main() {
	go func() {
		message = "哈囉"
		ready = true
	}()
	for !ready {
		time.Sleep(time.Millisecond)
	}
	fmt.Println(message)
}
```

執行結果（某一次）：

```text
哈囉
```

goroutine 先寫 `message`、再把 `ready` 設成 `true`；`main` 等到 `ready` 變成 `true` 才印 `message`。看起來一定會印出「哈囉」，在你的電腦上通常也真的是。

但用第 9 章的 `-race` 跑一次：

```bash
go run -race .
```

執行結果（某一次，節錄並省略路徑）：

```text
==================
WARNING: DATA RACE
Write at 0x000102f9a388 by goroutine 7:
  main.main.func1()
      main.go:14 +0x6c

Previous read at 0x000102f9a388 by main goroutine:
  main.main()
      main.go:16 +0x44
...
Found 2 data race(s)
exit status 66
```

`ready` 和 `message` 都有 data race。這不是 race detector 太囉嗦：這個程式**真的**是錯的，只是剛好沒出事。

### 「我寫的順序」不等於「別人看到的順序」

為了跑得快，編譯器和 CPU 都會在**不改變單一 goroutine 結果**的前提下調整動作：

- 編譯器可能把兩個寫入調換順序，因為對這個 goroutine 自己來說，先寫哪個都一樣。
- 編譯器可能把 `ready` 的值暫存在 CPU 的暫存器裡，迴圈每次都讀那份舊的，永遠看不到別人的修改。
- 多核心 CPU 各有自己的快取，一個核心寫進去的值，要過一陣子另一個核心才看得到，而且不保證按照寫入的順序。

所以另一個 goroutine 可能先看到 `ready == true`，卻還看到空的 `message`；也可能一直看不到 `ready` 變成 `true`。這些在單一 goroutine 裡完全合理的最佳化，一碰到多個 goroutine 共用變數，就變成問題。

### happens-before：「保證看得到」的關係

Go 的**記憶體模型**（memory model）是一份規則，說明「一個 goroutine 寫的值，另一個 goroutine 什麼時候保證讀得到」。核心概念是 **happens-before**（發生在……之前）：

> 如果動作 A happens-before 動作 B，那 B 一定看得到 A 以及 A 之前做的所有事。

在同一個 goroutine 裡，前面的程式碼 happens-before 後面的程式碼，這符合直覺。但**不同 goroutine 之間，預設沒有任何先後關係**，除非你用同步工具把它們「接起來」。

常見的接法：

| 動作 A | happens-before 動作 B |
| --- | --- |
| `go f()` 這行敘述 | `f` 開始執行 |
| 往 channel 送值 | 那個值被接收完成 |
| `close(ch)` | 接收端因為 channel 關閉而收到零值 |
| `mu.Unlock()` | 下一次 `mu.Lock()` 回傳 |
| `wg.Done()`（或 `wg.Go` 的函式結束） | `wg.Wait()` 回傳 |
| `once.Do(f)` 裡的 `f` 結束 | 任何 `once.Do` 回傳 |

`sync/atomic` 的操作之間也有類似的保證。

### 改成正確的寫法

用 channel 把兩個 goroutine 接起來：

```go
package main

import "fmt"

var message string

func main() {
	done := make(chan struct{})
	go func() {
		message = "哈囉"
		close(done)
	}()
	<-done
	fmt.Println(message)
}
```

執行結果：

```text
哈囉
```

推理一遍：goroutine 裡，寫 `message` 在 `close(done)` 之前（同一個 goroutine）；`close(done)` happens-before `main` 的 `<-done` 收到值；`<-done` 在 `fmt.Println` 之前（同一個 goroutine）。整條鏈接起來，`fmt.Println` 一定看得到 `"哈囉"`。用 `-race` 跑也不會再有警告。

### 為什麼 data race 一定是錯的

**data race** 的定義是：兩個 goroutine 存取同一個變數，至少一個是寫入，而且兩者之間**沒有** happens-before 關係。

既然沒有先後關係，Go 就不保證讀的那一方會看到什麼：舊值、新值，甚至一個寫到一半的值（例如字串、切片、介面這種由好幾個部分組成的值，可能讀到新的指標配上舊的長度），程式因此當掉也有可能。這和「結果偶爾不準」是兩回事：data race 讓程式的行為**沒有定義**，測試時正常不代表上線後正常。

所以判斷並行程式對不對，不要問「這樣跑跑看有沒有問題」，而是問「每一對讀寫之間，有沒有用 channel、`Mutex`、`WaitGroup`、atomic 等工具建立 happens-before」。沒有的話，就是錯的。

## 重點整理

- 編譯器和 CPU 會重排、暫存讀寫，所以一個 goroutine 寫的順序，不保證是另一個 goroutine 看到的順序。
- 記憶體模型用 happens-before 描述「保證看得到」：A happens-before B，B 就看得到 A 和 A 之前的所有寫入。
- 不同 goroutine 之間預設沒有先後關係，要靠 channel、`close`、`Mutex`、`WaitGroup`、`Once`、atomic 建立。
- data race 是兩個 goroutine 存取同一變數、至少一個寫入、且沒有 happens-before；它讓行為沒有定義，一定要修正，`-race` 能幫你找出來。
