# `pprof`

## 本集目標

用 `runtime/pprof` 與 `net/http/pprof` 收集 profile，再用 `go tool pprof` 找出程式把時間花在哪裡。

## 正文

### 不要用猜的

程式跑得慢，直覺常常猜錯原因。**profiling**（效能剖析）是讓程式在執行時記錄「時間花在哪些函式」「記憶體在哪裡配置」，再根據資料決定要改哪裡。Go 內建的工具叫 **pprof**，記錄下來的檔案叫 **profile**。

最常用的兩種 profile：

- **CPU profile**：每秒抽樣約 100 次，看程式當下正在執行哪個函式，累積起來就知道誰最耗 CPU。
- **heap profile**：抽樣記錄記憶體在哪裡配置，找出配置最多、或一直沒被回收的地方。

### `runtime/pprof`：寫進檔案

適合跑完就結束的程式，例如 CLI 工具：

```go
package main

import (
	"fmt"
	"os"
	"runtime/pprof"
)

func isPrime(n int) bool {
	if n < 2 {
		return false
	}
	for d := 2; d*d <= n; d++ {
		if n%d == 0 {
			return false
		}
	}
	return true
}

func countPrimes(limit int) int {
	count := 0
	for n := range limit {
		if isPrime(n) {
			count++
		}
	}
	return count
}

func main() {
	f, err := os.Create("cpu.prof")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer f.Close()

	if err := pprof.StartCPUProfile(f); err != nil {
		fmt.Println(err)
		return
	}
	defer pprof.StopCPUProfile()

	fmt.Println("質數個數：", countPrimes(10_000_000))
}
```

執行結果：

```text
質數個數： 664579
```

`pprof.StartCPUProfile(f)` 開始記錄，`defer pprof.StopCPUProfile()` 在 `main` 結束前停止並把資料寫進 `cpu.prof`。注意兩個 `defer` 的順序：後寫的 `StopCPUProfile` 先執行，資料寫完才關檔案。

heap profile 則是在想觀察的時間點呼叫 `pprof.WriteHeapProfile(f)`，寫進另一個檔案。

### `go tool pprof`：看結果

先編譯成執行檔再執行，讓 pprof 能對照執行檔找到函式名稱和原始碼：

```bash
go build -o primes .
./primes
go tool pprof -top primes cpu.prof
```

執行結果（某一次）：

```text
File: primes
Type: cpu
Duration: 1.11s, Total samples = 810ms (73.05%)
Showing nodes accounting for 810ms, 100% of 810ms total
      flat  flat%   sum%        cum   cum%
     710ms 87.65% 87.65%      800ms 98.77%  main.isPrime (inline)
      90ms 11.11% 98.77%       90ms 11.11%  runtime.asyncPreempt
      10ms  1.23%   100%      810ms   100%  main.countPrimes (inline)
         0     0%   100%      810ms   100%  main.main
         0     0%   100%      810ms   100%  runtime.main
```

（省略了 `Time:` 那一行。）兩個最重要的欄位：

- **flat**：花在這個函式**本身**的時間。
- **cum**：這個函式**加上它呼叫的函式**一共花的時間。

`main.main` 的 flat 是 0、cum 是 100%：它自己幾乎不做事，時間都花在它呼叫的函式裡。`main.isPrime` 的 flat 最大，熱點就是它。`(inline)` 表示這個函式被 inline 了（上上集提過）。

想看到某個函式裡**哪一行**最慢，用 `-list` 加函式名稱：

```bash
go tool pprof -list 'main.isPrime' primes cpu.prof
```

執行結果（某一次，省略了路徑）：

```text
Total: 810ms
ROUTINE ======================== main.isPrime in main.go
     710ms      800ms (flat, cum) 98.77% of Total
         .          .      9:func isPrime(n int) bool {
         .          .     10:	if n < 2 {
         .          .     11:		return false
         .          .     12:	}
     290ms      320ms     13:	for d := 2; d*d <= n; d++ {
     420ms      480ms     14:		if n%d == 0 {
         .          .     15:			return false
         .          .     16:		}
         .          .     17:	}
         .          .     18:	return true
         .          .     19:}
```

時間幾乎都在試除的迴圈裡。要加速，就該從演算法下手（例如改用篩法），而不是去改別的地方。

不加 `-top`、`-list` 直接執行 `go tool pprof primes cpu.prof`，會進入互動模式，可以輸入 `top`、`list isPrime` 等指令，`quit` 離開。加上 `-http=localhost:8080` 則會開瀏覽器介面，Go 1.26 起預設顯示**火焰圖**（flame graph）：每個方塊是一個函式，越寬代表花的時間越多，上下疊起來表示呼叫關係。

### `net/http/pprof`：給一直在跑的服務

Web 服務不會自己結束，沒辦法等它跑完再看檔案。這時 blank import `net/http/pprof`，它的 `init` 會把一組 `/debug/pprof/` 開頭的 handler 註冊到 `http.DefaultServeMux`：

```go,norun
package main

import (
	"fmt"
	"net/http"
	_ "net/http/pprof"
)

func main() {
	http.HandleFunc("/hello", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "哈囉")
	})
	fmt.Println("伺服器在 http://localhost:6060")
	if err := http.ListenAndServe("localhost:6060", nil); err != nil {
		fmt.Println(err)
	}
}
```

伺服器跑起來之後，在另一個終端機：

```bash
go tool pprof -top http://localhost:6060/debug/pprof/heap
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=10
```

第一行抓目前的 heap profile；第二行在接下來 10 秒收集 CPU profile，期間你可以對服務送請求。用瀏覽器打開 `http://localhost:6060/debug/pprof/` 可以看到所有種類，除了 `heap`、`profile`，還有 `goroutine`（所有 goroutine 卡在哪裡）、`allocs`，以及 Go 1.27 正式加入的 `goroutineleak`，它會列出被判斷為洩漏、永遠不會再醒來的 goroutine（第 9 章談過 goroutine 洩漏）。

注意兩件事：

- 這裡用的是 `http.DefaultServeMux`（`ListenAndServe` 第二個參數傳 `nil`）。如果你用自己的 `ServeMux`，這些路徑不會自動出現在上面。
- profile 會透露程式內部的資訊，**不要對外公開**。範例只聽 `localhost`；正式環境通常把它放在另一個只有內部能連的 port。

## 重點整理

- 效能問題要靠量測：CPU profile 看時間花在哪，heap profile 看記憶體在哪配置。
- 跑完就結束的程式用 `runtime/pprof`：`StartCPUProfile` + `defer StopCPUProfile()`，或 `WriteHeapProfile`。
- `go tool pprof -top` 看排行（flat 是自己、cum 含呼叫的函式），`-list` 看到每一行，`-http` 開圖形介面（預設火焰圖）。
- 長時間執行的服務 blank import `net/http/pprof`，從 `/debug/pprof/` 取得各種 profile，包含 Go 1.27 的 `goroutineleak`；不要對外公開。
