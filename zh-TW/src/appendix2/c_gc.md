# GC 概念

## 本集目標

理解 Go 垃圾回收器「標記、清除」的基本想法，知道 `GOGC` 和 `GOMEMLIMIT` 兩個調整旋鈕，以及 Go 1.26 起預設的 Green Tea GC。

## 正文

### 誰來收拾 heap

上一集說過，逃到 heap 的東西不會隨函式結束而消失。可是程式一直配置記憶體，總要有人把不再使用的部分收回來，不然記憶體很快就用完了。

在 Go 裡，這件事由執行環境裡的**垃圾回收器**（garbage collector，簡稱 **GC**）自動處理，你不需要、也沒辦法自己釋放記憶體。

### 標記與清除

Go 的 GC 屬於**標記清除**（mark and sweep）的做法，想像成大掃除：

1. **從根開始找**：「根」是程式一定還在用的東西，像是全域變數、每個 goroutine 的 stack 上的變數。
2. **標記**（mark）：從根出發，沿著指標一路走，走得到的物件都貼上「還在用」的標籤。
3. **清除**（sweep）：掃過整個 heap，沒貼標籤的物件就是沒人走得到的垃圾，把它的空間收回來重複使用。

重點是「**走得到**」：只要還有任何一條指標鏈能從根連到某個物件，它就不會被回收。反過來說，切片、map 裡留著用不到的指標，GC 也只能當它還在用。

Go 的 GC 大部分工作和你的程式**同時進行**，只有很短的時間需要讓所有 goroutine 停下來，所以一般不會感覺到程式卡頓。代價是 GC 會吃掉一部分 CPU。

### `GOGC`：多久掃一次

GC 什麼時候開始？由環境變數 **`GOGC`** 決定，預設是 `100`，意思是：

> 上一次 GC 結束時還活著的 heap 有多大，等新配置的量再多出它的 100%，就做下一次 GC。

例如上次掃完還有 4 MB 在用，heap 長到大約 8 MB 時就再掃一次。`GOGC` 越小，GC 越頻繁、記憶體用得越少、CPU 花得越多；越大則相反。`GOGC=off` 是完全關掉 GC。

看一個一直製造垃圾的程式：

```go
package main

import (
	"fmt"
	"runtime"
)

var keep [][]byte

func main() {
	for i := range 100_000 {
		buf := make([]byte, 1024)
		if i%100 == 0 {
			keep = append(keep, buf)
		}
	}

	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	fmt.Println("GC 次數：", m.NumGC)
	fmt.Println("目前使用的 heap（KB）：", m.HeapAlloc/1024)
	fmt.Println("累計配置（MB）：", m.TotalAlloc/1024/1024)
}
```

執行結果（某一次）：

```text
GC 次數： 34
目前使用的 heap（KB）： 3518
累計配置（MB）： 97
```

迴圈配置了十萬塊 1 KB 的記憶體，只留下其中百分之一，其他都變成垃圾。`runtime.ReadMemStats` 讀出 GC 的統計資料。每次執行的數字會有些不同。

用不同的 `GOGC` 跑同一支程式：

```bash
GOGC=50 go run .
GOGC=200 go run .
GOGC=off go run .
```

執行結果（某一次）：

```text
GC 次數： 79
目前使用的 heap（KB）： 1657
累計配置（MB）： 97
GC 次數： 14
目前使用的 heap（KB）： 7177
累計配置（MB）： 97
GC 次數： 0
目前使用的 heap（KB）： 100303
累計配置（MB）： 97
```

配置的總量都一樣，但 `GOGC=50` 掃了 79 次、heap 保持很小；`GOGC=200` 只掃 14 次、heap 大一些；關掉 GC 後垃圾全部留著。

### `GOMEMLIMIT`：記憶體上限

`GOGC` 只看比例，不管機器實際有多少記憶體。程式跑在記憶體有限的容器裡時，可以用 **`GOMEMLIMIT`** 設一個**軟性上限**，例如 `GOMEMLIMIT=512MiB`。快碰到上限時，GC 會更積極地回收，不再死守 `GOGC` 的比例。

「軟性」的意思是它不保證絕不超過：如果活著的資料本來就比上限大，GC 再怎麼掃也沒用，程式還是會超過。常見的搭配是 `GOGC=off` 加 `GOMEMLIMIT`：平常不浪費 CPU 掃描，接近上限才回收。

### 在程式裡調整

兩個設定也能用 `runtime/debug` 在程式裡改，回傳值是原本的設定：

```go
package main

import (
	"fmt"
	"runtime/debug"
)

func main() {
	old := debug.SetGCPercent(50)
	fmt.Println("原本的 GOGC：", old)

	limit := debug.SetMemoryLimit(-1)
	fmt.Println("目前的記憶體上限：", limit)
}
```

執行結果：

```text
原本的 GOGC： 100
目前的記憶體上限： 9223372036854775807
```

`SetMemoryLimit` 傳負數代表「不修改，只查詢」。預設的上限是 `int64` 能表示的最大值，也就是沒有限制。

### Green Tea GC

Go 1.26 起，預設的 GC 換成了新設計，叫 **Green Tea**（Go 1.25 時是實驗功能）。它沒有改變上面講的觀念，標記清除、`GOGC`、`GOMEMLIMIT` 都照舊，改的是標記時的工作方式：

- 舊的做法是沿著指標一個物件一個物件跳，物件散落在記憶體各處，CPU 快取很難發揮作用。
- Green Tea 把小物件按照它們所在的**記憶體分頁**集中處理，一次掃一整塊相鄰的記憶體，對快取比較友善，多核心時也比較好分工。

官方的說法是，大量使用 GC 的實際程式，GC 的額外負擔大約可減少 10%～40%，效果依程式而定。你不需要改任何程式碼就能享受到。如果遇到問題，建置時可以設定 `GOEXPERIMENT=nogreenteagc` 換回舊的 GC；官方預計之後會移除這個開關（Go 1.27 的工具鏈目前仍接受它）。

### 什麼時候需要調整

大多數程式**用預設值就好**。只有在量測後發現 GC 吃掉太多 CPU，或程式在容器裡記憶體不夠時，再考慮調整 `GOGC`、`GOMEMLIMIT`。更根本的做法通常是減少不必要的配置，這要靠上一集的逃逸分析和下一集的 `pprof` 找出來。

## 重點整理

- GC 自動回收 heap：從根（全域變數、stack）出發標記走得到的物件，再清除沒被標記的。
- GC 大部分工作和程式同時進行，代價是佔用一些 CPU。
- `GOGC`（預設 100）決定 heap 成長多少就做下一次 GC：越小越省記憶體、越耗 CPU；`off` 為關閉。
- `GOMEMLIMIT` 設定軟性記憶體上限；兩者也能用 `debug.SetGCPercent`、`debug.SetMemoryLimit` 在程式裡調整。
- Go 1.26 起預設使用 Green Tea GC，按記憶體分頁集中掃描小物件，觀念與設定方式不變。
