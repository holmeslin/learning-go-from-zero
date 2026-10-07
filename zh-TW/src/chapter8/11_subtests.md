# `t.Run` 子測試

## 本集目標

用 `t.Run` 幫表格的每一列取名字，變成可以個別執行的子測試。

## 正文

### 每一列都是一個小測試

上一集的表格驅動測試有個小缺點：在 `go test -v` 的輸出裡，整張表只顯示成一個 `TestHello`。如果想知道每一列各自的結果，或者只想重跑某一列，就要用 `t.Run`。

`t.Run(名字, 函式)` 會建立一個**子測試**，用指定的名字執行那個函式。我們在表格裡多加一個欄位 `label` 當作名字：

`greet/greet_test.go`：

```go,ignore
package greet

import "testing"

func TestHello(t *testing.T) {
	tests := []struct {
		label string
		name  string
		want  string
	}{
		{"中文名字", "小明", "你好，小明！"},
		{"英文名字", "Andy", "你好，Andy！"},
		{"空字串", "", "你好，朋友！"},
	}
	for _, tt := range tests {
		t.Run(tt.label, func(t *testing.T) {
			got := Hello(tt.name)
			if got != tt.want {
				t.Errorf("Hello(%q) = %q，想要 %q", tt.name, got, tt.want)
			}
		})
	}
}
```

`t.Run` 的第二個參數是一個匿名函式，參數同樣是 `t *testing.T`，這是子測試自己的 `t`。匿名函式裡用到外面的 `tt`，就是第 6 章的閉包。

執行 `go test -v ./greet`：

```text
=== RUN   TestHello
=== RUN   TestHello/中文名字
=== RUN   TestHello/英文名字
=== RUN   TestHello/空字串
--- PASS: TestHello (0.00s)
    --- PASS: TestHello/中文名字 (0.00s)
    --- PASS: TestHello/英文名字 (0.00s)
    --- PASS: TestHello/空字串 (0.00s)
PASS
ok  	myapp/greet	0.458s
```

每一列都有自己的名字和結果，名字的格式是「`測試函式名/子測試名`」。

### 失敗時更清楚

把英文名字那列的預期結果故意改成 `"Hello, Andy!"`，執行 `go test ./greet`：

```text
--- FAIL: TestHello (0.00s)
    --- FAIL: TestHello/英文名字 (0.00s)
        greet_test.go:19: Hello("Andy") = "你好，Andy！"，想要 "Hello, Andy!"
FAIL
FAIL	myapp/greet	0.929s
FAIL
```

一看就知道是「英文名字」這一列出錯。子測試失敗時，它上一層的 `TestHello` 也會被標成失敗。

### 只跑某一個子測試

`-run` 可以指定要執行哪些測試，子測試用 `/` 分隔：

```bash
go test -v -run 'TestHello/空字串' ./greet
```

```text
=== RUN   TestHello
=== RUN   TestHello/空字串
--- PASS: TestHello (0.00s)
    --- PASS: TestHello/空字串 (0.00s)
PASS
ok  	myapp/greet	0.373s
```

只有「空字串」那一列被執行。表格很大、只想專心修某一列的時候，這招非常好用。名字裡最好不要放空白，在指令裡指定時會比較方便。

`t.Run` 裡也可以放心使用 `t.Fatalf`：它只會結束**這一個**子測試，其他列照樣執行。

## 重點整理

- `t.Run(名字, func(t *testing.T) { ... })` 建立有名字的子測試。
- 表格驅動測試搭配 `t.Run`，每一列都有獨立的名字和結果。
- 子測試的完整名字是 `測試函式名/子測試名`，可用 `go test -run` 只執行特定子測試。
- 子測試裡的 `t.Fatalf` 只結束該子測試。
