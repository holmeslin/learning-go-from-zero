# 表格驅動測試

## 本集目標

把多組「輸入和預期結果」整理成一個表格，用一個迴圈全部測完。

## 正文

### 測試越寫越長

上一集只測了 `Hello("小明")`。可是 `Hello` 還有一個特別的規則：名字是空字串時要改用「朋友」。這種邊界情況最容易出錯，一定要測。

如果每種情況都複製一份 `got`、`want`、`if`，測試很快就變得又長又重複。Go 社群最常用的做法是**表格驅動測試**（table-driven test）：把測試資料列成一張表，再用迴圈一筆一筆檢查。

### 寫成表格

`greet/greet_test.go`：

```go,ignore
package greet

import "testing"

func TestHello(t *testing.T) {
	tests := []struct {
		name string
		want string
	}{
		{"小明", "你好，小明！"},
		{"Andy", "你好，Andy！"},
		{"", "你好，朋友！"},
	}
	for _, tt := range tests {
		got := Hello(tt.name)
		if got != tt.want {
			t.Errorf("Hello(%q) = %q，想要 %q", tt.name, got, tt.want)
		}
	}
}
```

`tests` 是一個匿名 struct 的切片（第 3 章學過匿名 struct），每個元素就是表格的一列：`name` 是輸入，`want` 是預期的結果。迴圈變數慣例上叫 `tt`，取自 test table。

執行 `go test -v ./greet`：

```text
=== RUN   TestHello
--- PASS: TestHello (0.00s)
PASS
ok  	myapp/greet	0.755s
```

最後的秒數每次都不同，你的數字會不一樣。

### 要多測一種情況？加一行就好

這就是表格的好處：想多測一組資料，只要在表格裡多加一列，檢查的程式碼完全不用動。

如果有一列寫錯了，例如把空字串那列的預期結果寫成 `"你好，！"`，`go test ./greet` 會告訴我們是哪一組輸入出了問題：

```text
--- FAIL: TestHello (0.00s)
    greet_test.go:17: Hello("") = "你好，朋友！"，想要 "你好，！"
FAIL
FAIL	myapp/greet	0.539s
FAIL
```

因為我們在 `t.Errorf` 裡印出了輸入 `tt.name`，一眼就看得出是空字串那組失敗。在表格驅動測試裡，錯誤訊息一定要包含輸入值，否則只知道「第 17 行錯了」，卻不知道是表格的哪一列。

另外注意，這裡用 `t.Errorf` 而不是 `t.Fatalf`：一列失敗了，其他列還是會繼續檢查，一次就能看到所有出錯的地方。

## 重點整理

- 表格驅動測試把多組輸入和預期結果寫成 struct 切片，用 `for range` 逐一檢查。
- 多測一種情況只要在表格加一列。
- 錯誤訊息要印出輸入值，才知道是哪一列失敗。
- 用 `t.Errorf` 讓所有列都能被檢查到。
