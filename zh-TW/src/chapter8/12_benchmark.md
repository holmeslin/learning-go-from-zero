# benchmark 與 `b.Loop`

## 本集目標

寫一個 benchmark（效能測試），用 `go test -bench` 量出函式執行一次要花多少時間。

## 正文

### 對不對，和快不快

前幾集的測試檢查的是「結果對不對」。有時候我們還想知道「有多快」：兩種寫法哪個比較快？改了程式之後有沒有變慢？

用碼錶手動計時並不準，執行一次太快了量不出來，而且每次都有誤差。Go 的 **benchmark** 會自動把函式重複執行很多次，再算出平均一次花多少時間。

### 寫一個 benchmark

benchmark 也寫在 `_test.go` 檔裡，規則和測試很像：

- 函式名稱以 `Benchmark` 開頭。
- 參數是 `b *testing.B`。
- 要量測的程式碼放在 `for b.Loop() { ... }` 裡。

我們來比較 `greet` 套件的 `Hello`（用 `+` 接字串）和 `Bye`（用 `fmt.Sprintf`）。

`greet/bench_test.go`：

```go,ignore
package greet

import "testing"

func BenchmarkHello(b *testing.B) {
	for b.Loop() {
		Hello("小明")
	}
}

func BenchmarkBye(b *testing.B) {
	for b.Loop() {
		Bye("小明")
	}
}
```

`b.Loop()` 是 Go 1.24 加入的寫法。它會決定要跑幾次：還要繼續量就回傳 `true`，量夠了就回傳 `false`，迴圈跟著結束。我們不需要自己決定次數。

你在網路上可能會看到舊的寫法 `for i := 0; i < b.N; i++`，它也能用，但 `b.Loop` 更不容易量錯，新寫的 benchmark 請用 `b.Loop`。

### 執行

`go test` 預設不會跑 benchmark，要加上 `-bench`，後面接要執行的 benchmark 名稱（`.` 代表全部）：

```bash
go test -bench=. ./greet
```

```text
goos: darwin
goarch: arm64
pkg: myapp/greet
cpu: Apple M4 Max
BenchmarkHello-14    	121566765	         9.720 ns/op
BenchmarkBye-14      	37498779	        32.65 ns/op
PASS
ok  	myapp/greet	3.080s
```

**你的數字一定會不同**，前四行的電腦資訊也會不一樣，因為這和電腦的速度、當下忙不忙都有關係。重點是看每一行的意思：

- `BenchmarkHello-14`：benchmark 名稱，`-14` 是執行時使用的 CPU 核心數。
- `121566765`：總共執行了幾次。
- `9.720 ns/op`：平均執行一次花 9.720 奈秒（ns，十億分之一秒）。op 是 operation，「一次操作」的意思。

在這台電腦上，`Hello` 大約比 `Bye` 快三倍。`fmt.Sprintf` 要處理格式動詞，做的事情比單純用 `+` 接字串多。不過兩個都只要幾十奈秒，對大部分程式來說根本感覺不到差別；benchmark 的用途是在**真的**需要變快的時候，幫你找出值得改的地方。

### 看記憶體用量

加上 `-benchmem` 還會顯示記憶體配置的狀況。`-bench` 後面可以只寫名稱的一部分，例如只跑名字裡有 `Hello` 的：

```bash
go test -bench=Hello -benchmem ./greet
```

```text
goos: darwin
goarch: arm64
pkg: myapp/greet
cpu: Apple M4 Max
BenchmarkHello-14    	123642078	         9.798 ns/op	       0 B/op	       0 allocs/op
PASS
ok  	myapp/greet	1.622s
```

`B/op` 是每次用掉多少位元組的記憶體，`allocs/op` 是每次向系統要了幾次記憶體。數字越小越好。

另外，`go test -bench` 會先把一般的測試跑一遍，全部通過才開始量測。

## 重點整理

- benchmark 函式以 `Benchmark` 開頭，參數是 `b *testing.B`，量測的程式碼放在 `for b.Loop() { ... }` 裡。
- `b.Loop` 是 Go 1.24 起的寫法，取代舊的 `for i := 0; i < b.N; i++`。
- `go test -bench=.` 執行 benchmark；`ns/op` 是平均一次花費的時間，`-benchmem` 加上記憶體資訊。
- benchmark 的數字隨電腦和當下狀況變動，只適合在同一台電腦上互相比較。
