# `go test`

## 本集目標

寫出第一個測試函式，用 `go test` 自動檢查程式的結果對不對。

## 正文

### 為什麼要寫測試

到目前為止，我們確認程式對不對的方法是：執行，看輸出，用眼睛比對。函式少的時候還行，多了之後，每改一個地方就要全部重看一遍，很快就會漏掉。

**測試**就是用程式來檢查程式：把「輸入什麼、應該得到什麼」寫下來，交給 `go test` 一次跑完。

### 測試檔案的規則

延續 `myapp` 模組，我們要測試 `greet` 套件的 `Hello`。規則有三條：

1. 測試檔的檔名以 `_test.go` 結尾，和被測試的程式放在同一個資料夾。這種檔案只在 `go test` 時編譯，不會跑進正式的程式裡。
2. 測試函式的名字以 `Test` 開頭，後面接大寫字母，例如 `TestHello`。
3. 測試函式只有一個參數 `t *testing.T`，沒有回傳值。

`greet/greet_test.go`：

```go,ignore
package greet

import "testing"

func TestHello(t *testing.T) {
	got := Hello("小明")
	want := "你好，小明！"
	if got != want {
		t.Errorf("Hello(%q) = %q，想要 %q", "小明", got, want)
	}
}
```

測試檔的第一行和 `greet.go` 一樣是 `package greet`，所以它屬於 `greet` 套件，連小寫的名稱都能直接使用。

`got` 是實際得到的結果，`want` 是我們想要的結果，兩個不一樣就呼叫 `t.Errorf` 回報錯誤。`t.Errorf` 的用法和 `fmt.Printf` 一樣，`%q` 會把字串加上雙引號印出來，空字串也看得清楚。`got`、`want` 是 Go 社群慣用的變數名稱。

### 執行測試

在 `greet` 資料夾裡執行：

```bash
go test
```

```text
PASS
ok  	myapp/greet	2.425s
```

`PASS` 代表所有測試都通過了。最後的秒數是花費的時間，你的數字會不同。

加上 `-v`（verbose，詳細）可以看到每個測試的狀況：

```bash
go test -v
```

```text
=== RUN   TestHello
--- PASS: TestHello (0.00s)
PASS
ok  	myapp/greet	0.351s
```

在模組最上層，用 `./...` 一次測試所有套件：

```bash
go test ./...
```

```text
?   	myapp	[no test files]
ok  	myapp/greet	0.370s
```

`myapp` 本身（`main.go` 那個套件）沒有測試檔，所以顯示 `no test files`。如果程式碼沒改又跑一次，時間的位置可能會顯示 `(cached)`，意思是 Go 直接沿用上次的結果。

### 測試失敗長什麼樣子

故意把 `want` 改成 `"哈囉，小明！"`，再執行 `go test ./...`：

```text
?   	myapp	[no test files]
--- FAIL: TestHello (0.00s)
    greet_test.go:9: Hello("小明") = "你好，小明！"，想要 "哈囉，小明！"
FAIL
FAIL	myapp/greet	0.376s
FAIL
```

失敗訊息告訴我們：哪個測試失敗（`TestHello`）、在測試檔第幾行（第 9 行），以及我們用 `t.Errorf` 寫的說明。錯誤訊息寫得清楚，修起來就快。

`t.Errorf` 回報錯誤後，測試函式會**繼續執行**下去。如果遇到「這裡錯了，後面也沒必要檢查」的情況，可以改用 `t.Fatalf`，它回報錯誤後會立刻結束這個測試函式。

## 重點整理

- 測試寫在 `_test.go` 結尾的檔案，函式名稱以 `Test` 開頭，參數是 `t *testing.T`。
- 比較 `got` 和 `want`，不一樣就用 `t.Errorf` 回報；`t.Fatalf` 回報後立刻停止該測試。
- `go test` 測試目前資料夾，`go test ./...` 測試整個模組，`-v` 顯示每個測試的結果。
- 失敗訊息會標出測試名稱和行號；花費的秒數每次都會不同。
