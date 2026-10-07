# 逃逸分析

## 本集目標

知道變數可能放在 stack 或 heap，學會用 `go build -gcflags=-m` 看編譯器的決定，並讀懂常見的幾種訊息。

## 正文

### stack 與 heap

程式執行時，變數放在兩種地方：

- **stack**（堆疊）：每次呼叫函式，就在 stack 上切一塊空間給它的區域變數；函式一 `return`，整塊收回。配置和回收幾乎不花時間。
- **heap**（堆積）：存放「函式結束後還要繼續活著」的東西。用完之後要等**垃圾回收**（下一集）發現沒人用了才會清掉，成本比較高。

在 Go 裡，你**不需要**決定變數放哪裡，`new`、`&`、`make` 也不代表一定在 heap。編譯器會分析每個變數會不會在函式結束後還被用到，這個分析叫**逃逸分析**（escape analysis）：會「逃出」函式的放 heap，不會的放 stack。

這也是為什麼第 3 章可以安心回傳區域變數的指標：編譯器看到它逃出去了，就自動把它放到 heap。

### 叫編譯器說出它的決定

```go
package main

import "fmt"

type Point struct {
	X, Y int
}

func sum(p Point) int {
	return p.X + p.Y
}

func newPoint(x, y int) *Point {
	p := Point{X: x, Y: y}
	return &p
}

func squares(n int) int {
	s := make([]int, n)
	total := 0
	for i := range s {
		s[i] = i * i
		total += s[i]
	}
	return total
}

func main() {
	a := Point{X: 1, Y: 2}
	b := newPoint(3, 4)
	total := sum(a) + b.X + squares(5)
	fmt.Println(total)
}
```

執行結果：

```text
36
```

在這個模組的資料夾執行：

```bash
go build -gcflags='-m -l' .
```

執行結果：

```text
# escape
./main.go:14:2: moved to heap: p
./main.go:19:11: make([]int, n) does not escape
./main.go:32:13: ... argument does not escape
./main.go:32:14: total escapes to heap
```

（第一行的 `escape` 是這個範例的模組名稱。）`-gcflags` 把參數交給編譯器：`-m` 是「印出最佳化的決定」，`-l` 是「先不要做 inline」，讓輸出單純一點，等一下再解釋。每行開頭是 `檔名:行:欄`，對照程式碼來看：

- **`moved to heap: p`**（第 14 行）：`newPoint` 回傳了 `&p`，函式結束後 `p` 還要被用，所以放到 heap。
- **`make([]int, n) does not escape`**（第 19 行）：`s` 只在 `squares` 裡用，函式結束就沒人要了，可以放在 stack。注意長度 `n` 是執行時才知道的，Go 1.26 起編譯器在更多這類情況下也能把切片放在 stack。
- **`... argument does not escape`**（第 32 行）：`fmt.Println` 的可變參數會被包成一個切片，這個切片本身沒逃出去。
- **`total escapes to heap`**（第 32 行）：`fmt.Println` 的參數型別是 `any`，`total` 要裝進介面值裡傳過去，編譯器判斷不了 `Println` 會拿它做什麼，只好放到 heap。

`sum(a)` 傳的是值的複本，`a` 完全沒出現在輸出裡，代表它留在 stack 上。

### inline 會改變結果

拿掉 `-l` 再跑一次：

```bash
go build -gcflags=-m .
```

執行結果：

```text
# escape
./main.go:9:6: can inline sum
./main.go:13:6: can inline newPoint
./main.go:18:6: can inline squares
./main.go:30:15: inlining call to newPoint
./main.go:31:14: inlining call to sum
./main.go:31:33: inlining call to squares
./main.go:32:13: inlining call to fmt.Println
./main.go:14:2: moved to heap: p
./main.go:19:11: make([]int, n) does not escape
./main.go:31:33: make([]int, 5) does not escape
./main.go:32:13: ... argument does not escape
./main.go:32:14: total escapes to heap
```

多出來的 `can inline`、`inlining call to` 是 **inline**（內嵌）：小函式的內容被直接貼進呼叫的地方，省掉一次函式呼叫。貼進 `main` 之後，編譯器能看到更多前後文：第 31 行的 `make([]int, 5)` 就是 `squares` 被貼進來的那一份，長度變成固定的 5。

想知道「為什麼」逃逸，可以用 `-gcflags='-m=2'`，它會把推理過程一步一步印出來，例如 `p` 是因為 `return &p` 而逃出 `newPoint`。

### 該不該在意

大部分時候**不需要**。先寫出清楚、正確的程式；等本附錄 `pprof` 那一集介紹的工具或第 8 章的 benchmark 告訴你某段程式花了很多時間在配置記憶體，再用 `-m` 找出是哪些變數逃到 heap，看看能不能避免。常見的手法像是：回傳值而不是指標、避免在熱點把值轉成介面、重複使用切片。不要為了少一次 heap 配置，把程式改得難懂。

## 重點整理

- 變數放在 stack（隨函式結束回收，很便宜）或 heap（交給 GC 回收）；由編譯器的逃逸分析決定，不是由 `new`、`&` 決定。
- `go build -gcflags=-m` 印出編譯器的決定；加 `-l` 關掉 inline 讓輸出單純，`-m=2` 會說明原因。
- `moved to heap`、`escapes to heap` 代表放到 heap；`does not escape` 代表留在 stack。
- 回傳區域變數的指標、把值轉成介面（例如傳給 `fmt.Println`）是常見的逃逸原因。
- 先求清楚正確，量測確定是瓶頸後再處理逃逸。
