# fuzzing

## 本集目標

用 fuzzing（模糊測試）讓 Go 自動產生大量隨機輸入，找出我們自己想不到的錯誤。

## 正文

### 我們想不到的輸入

表格驅動測試只能測我們**想得到**的情況。可是很多錯誤偏偏藏在想不到的地方：奇怪的字元、特別長的字串、空字串……

**fuzzing** 的做法是：我們只寫下「不管輸入什麼，都必須成立的規則」，由 Go 不斷產生隨機輸入來檢查，直到找出違反規則的例子。

### 要測試的函式

在 `myapp` 模組新增 `textutil` 套件，寫一個把字串前後顛倒的函式。

`textutil/textutil.go`：

```go,ignore
package textutil

// Reverse 把字串前後顛倒。
func Reverse(s string) string {
	b := []byte(s)
	for i, j := 0, len(b)-1; i < j; i, j = i+1, j-1 {
		b[i], b[j] = b[j], b[i]
	}
	return string(b)
}
```

用 `"Go"`、`"hello"` 測試都沒問題。你可能已經看出毛病了，先假裝沒看到，讓 fuzzing 來找。

### 寫一個 fuzz 測試

`textutil/textutil_test.go`：

```go,ignore
package textutil

import (
	"testing"
	"unicode/utf8"
)

func FuzzReverse(f *testing.F) {
	f.Add("Go")
	f.Add("hello")
	f.Fuzz(func(t *testing.T, s string) {
		if !utf8.ValidString(s) {
			return
		}
		r := Reverse(s)
		if !utf8.ValidString(r) {
			t.Errorf("Reverse(%q) = %q，不是合法的 UTF-8", s, r)
		}
		if Reverse(r) != s {
			t.Errorf("Reverse 兩次之後和原本不一樣：%q", s)
		}
	})
}
```

- 函式名稱以 `Fuzz` 開頭，參數是 `f *testing.F`。
- `f.Add` 提供幾個**種子**，作為產生隨機輸入的起點。
- `f.Fuzz` 接收一個函式，第一個參數是 `t *testing.T`，後面是要隨機產生的輸入，這裡是一個字串 `s`。

裡面檢查兩條規則：合法的 UTF-8 字串顛倒後，仍然要是合法的 UTF-8；顛倒兩次要變回原本的字串。隨機產生的位元組不一定是合法的 UTF-8，這種輸入不在我們的討論範圍內，直接 `return` 跳過。`utf8.ValidString` 會檢查字串是不是合法的 UTF-8。

### 先當成普通測試

直接執行 `go test ./textutil`，只會用種子跑一次，就像一般的表格測試：

```text
ok  	myapp/textutil	0.465s
```

兩個種子都是英文，當然通過。

### 開始 fuzzing

加上 `-fuzz` 指定要跑的 fuzz 測試，`-fuzztime=2s` 讓這次隨機探索約跑兩秒；準備、收尾等工作也需要時間，整個指令可能花得更久：

```bash
go test -fuzz=FuzzReverse -fuzztime=2s ./textutil
```

執行結果（某一次）：

```text
fuzz: elapsed: 0s, gathering baseline coverage: 0/42 completed
fuzz: minimizing 33-byte failing input file
fuzz: elapsed: 0s, gathering baseline coverage: 13/42 completed
--- FAIL: FuzzReverse (0.02s)
    --- FAIL: FuzzReverse (0.00s)
        textutil_test.go:17: Reverse("秧") = "\xa7\xa7\xe7"，不是合法的 UTF-8
    
    Failing input written to testdata/fuzz/FuzzReverse/f12301413e1dcca2
    To re-run:
    go test -run=FuzzReverse/f12301413e1dcca2
FAIL
exit status 1
FAIL	myapp/textutil	1.959s
```

這次很快就找到了，但**不保證兩秒內一定找到失敗**。如果時間到了仍顯示 `PASS`，只代表這次沒找到，不表示程式沒有錯，也不表示你操作錯誤。可以延長 `-fuzztime` 再試。找到的字元、檔名和數字每次可能不同；上面這次也用了先前保留的 fuzz 快取，所以準備檢查的輸入不只原本的兩個種子。

問題在哪？第 2 章學過，中文、希臘字母這類字元在 UTF-8 裡佔好幾個位元組。`Reverse` 把**位元組**顛倒，一個字元的幾個位元組順序也被打亂，就變成不合法的 UTF-8 了。

如果 fuzzing 找到失敗，Go 會把輸入存進 `testdata/fuzz/FuzzReverse/` 資料夾。之後每次執行普通的 `go test`，它都會被當成一個種子重新檢查，這個錯誤就不會再偷偷回來。

### 不靠隨機也能重現

不管剛才有沒有找到失敗，我們都在 `FuzzReverse` 的 `f.Add("hello")` 後面、`f.Fuzz` 前面加上這一行：

```go,ignore
f.Add("中")
```

再執行 `go test -v ./textutil`。`"中"` 是已知的多位元組字元，普通測試就會確定在第三個種子 `FuzzReverse/seed#2` 失敗，訊息會有 `Reverse("中") = "\xad\xb8\xe4"，不是合法的 UTF-8`，不必等待隨機命中。保留這個種子，修正後還要用它檢查。

### 修正

把位元組換成 `rune`，以字元為單位顛倒：

```go,ignore
func Reverse(s string) string {
	r := []rune(s)
	for i, j := 0, len(r)-1; i < j; i, j = i+1, j-1 {
		r[i], r[j] = r[j], r[i]
	}
	return string(r)
}
```

執行 `go test -v ./textutil`，三個種子都應該通過；如果剛才有存下隨機找到的失敗輸入，也會一起檢查。想單獨重跑已知的 `"中"`，可以用前面學過的 `-run`：

```bash
go test -v -run="FuzzReverse/seed#2" ./textutil
```

執行結果（某一次）：

```text
=== RUN   FuzzReverse
=== RUN   FuzzReverse/seed#2
--- PASS: FuzzReverse (0.00s)
    --- PASS: FuzzReverse/seed#2 (0.00s)
PASS
ok  	myapp/textutil	0.189s
```

再執行一次 `go test -fuzz=FuzzReverse -fuzztime=2s ./textutil`：

執行結果（某一次）：

```text
fuzz: elapsed: 0s, gathering baseline coverage: 0/43 completed
fuzz: elapsed: 0s, gathering baseline coverage: 43/43 completed, now fuzzing with 14 workers
fuzz: elapsed: 3s, execs: 218898 (72934/sec), new interesting: 3 (total: 46)
fuzz: elapsed: 3s, execs: 218898 (0/sec), new interesting: 3 (total: 46)
PASS
ok  	myapp/textutil	11.192s
```

這次試了二十幾萬個輸入都沒找到失敗（數字每次不同），但這不是所有輸入都正確的證明。如果有產生 `testdata` 資料夾，請一起保留下來，它是測試的一部分。

不加 `-fuzztime` 的話，fuzzing 會一直跑到找出錯誤或你按下 Ctrl+C 為止。

## 重點整理

- fuzz 測試以 `Fuzz` 開頭，參數是 `f *testing.F`；`f.Add` 加種子，`f.Fuzz` 裡寫「對任何輸入都必須成立」的規則。
- 普通的 `go test` 只用種子和 `testdata` 裡的輸入跑一次；`go test -fuzz=名稱` 才會產生隨機輸入。
- 找到的失敗輸入會存到 `testdata/fuzz/`，之後每次測試都會重新檢查。
- `-fuzztime` 限制隨機探索的時間，不保證在時間內找到失敗；已知的多位元組種子可以用普通 `go test` 確定重現本例的錯誤。
