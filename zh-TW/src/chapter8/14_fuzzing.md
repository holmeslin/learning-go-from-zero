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

加上 `-fuzz` 指定要跑的 fuzz 測試，`-fuzztime` 指定最多跑多久：

```bash
go test -fuzz=FuzzReverse -fuzztime=2s ./textutil
```

```text
fuzz: elapsed: 0s, gathering baseline coverage: 0/2 completed
fuzz: elapsed: 0s, gathering baseline coverage: 2/2 completed, now fuzzing with 14 workers
fuzz: minimizing 35-byte failing input file
fuzz: elapsed: 0s, minimizing
--- FAIL: FuzzReverse (0.04s)
    --- FAIL: FuzzReverse (0.00s)
        textutil_test.go:17: Reverse("Ή") = "\x89\xce"，不是合法的 UTF-8
    
    Failing input written to testdata/fuzz/FuzzReverse/be2fb4fb01accd28
    To re-run:
    go test -run=FuzzReverse/be2fb4fb01accd28
FAIL
exit status 1
FAIL	myapp/textutil	0.585s
```

不到一秒就找到了。因為是隨機的，**你找到的字元、檔名和數字都會不同**，但錯誤一定是同一種。

問題在哪？第 2 章學過，中文、希臘字母這類字元在 UTF-8 裡佔好幾個位元組。`Reverse` 把**位元組**顛倒，一個字元的幾個位元組順序也被打亂，就變成不合法的 UTF-8 了。

Go 把這個失敗的輸入存進 `testdata/fuzz/FuzzReverse/` 資料夾。之後每次執行普通的 `go test`，它都會被當成一個種子重新檢查，這個錯誤就不會再偷偷回來。

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

執行 `go test -v ./textutil`，可以看到剛才存下來的輸入也被檢查了：

```text
=== RUN   FuzzReverse
=== RUN   FuzzReverse/seed#0
=== RUN   FuzzReverse/seed#1
=== RUN   FuzzReverse/be2fb4fb01accd28
--- PASS: FuzzReverse (0.00s)
    --- PASS: FuzzReverse/seed#0 (0.00s)
    --- PASS: FuzzReverse/seed#1 (0.00s)
    --- PASS: FuzzReverse/be2fb4fb01accd28 (0.00s)
PASS
ok  	myapp/textutil	5.658s
```

再 fuzz 一次：

```text
fuzz: elapsed: 0s, gathering baseline coverage: 0/37 completed
fuzz: elapsed: 0s, gathering baseline coverage: 37/37 completed, now fuzzing with 14 workers
fuzz: elapsed: 3s, execs: 231061 (77017/sec), new interesting: 6 (total: 43)
fuzz: elapsed: 3s, execs: 231061 (0/sec), new interesting: 6 (total: 43)
PASS
ok  	myapp/textutil	10.447s
```

這次試了二十幾萬個輸入都沒問題（數字每次不同）。`testdata` 資料夾請一起保留下來，它是測試的一部分。

不加 `-fuzztime` 的話，fuzzing 會一直跑到找出錯誤或你按下 Ctrl+C 為止。

## 重點整理

- fuzz 測試以 `Fuzz` 開頭，參數是 `f *testing.F`；`f.Add` 加種子，`f.Fuzz` 裡寫「對任何輸入都必須成立」的規則。
- 普通的 `go test` 只用種子和 `testdata` 裡的輸入跑一次；`go test -fuzz=名稱` 才會產生隨機輸入。
- 找到的失敗輸入會存到 `testdata/fuzz/`，之後每次測試都會重新檢查。
- `-fuzztime` 限制 fuzzing 的時間；隨機找到的輸入和數字每次都不同。
