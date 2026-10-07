# `goto`

## 本集目標

知道 Go 有 `goto`、它有哪些限制，以及為什麼平常幾乎用不到。

## 正文

`goto` 會讓程式直接跳到同一個函式裡某個標籤的位置繼續執行。上一集的標籤，`goto` 也能用。

### 基本用法

```go
package main

import "fmt"

func main() {
	i := 0
again:
	fmt.Println("第", i, "次")
	i++
	if i < 3 {
		goto again
	}
	fmt.Println("結束")
}
```

執行結果：

```text
第 0 次
第 1 次
第 2 次
結束
```

`goto again` 讓程式跳回 `again:` 那一行，重新往下執行，效果就像一個迴圈。

可是你應該也發現了：同樣的事情用 `for` 寫，一眼就看得出是迴圈；用 `goto` 寫，得從上到下追著跳來跳去才看得懂。這就是 `goto` 少用的原因。

### 限制一：不能跳過變數宣告

`goto` 不能往後跳過一個變數宣告，然後在後面用到那個變數的作用域裡落地：

```go,compile_fail
package main

import "fmt"

func main() {
	goto end
	msg := "你好"
	fmt.Println(msg)
end:
	fmt.Println("結束")
}
```

編譯錯誤：

```text
./main.go:6:7: goto end jumps over declaration of msg at ./main.go:7:6
```

如果允許這樣跳，到了 `end:` 之後 `msg` 雖然「在作用域裡」，卻從來沒有被賦值過。Go 乾脆禁止這種情況。

### 限制二：不能跳進區塊

`goto` 也不能從外面跳進 `{}` 區塊裡面，例如跳進 `if` 或 `for` 的大括號中：

```go,compile_fail
package main

import "fmt"

func main() {
	x := 5
	goto inside
	if x > 3 {
	inside:
		fmt.Println("在 if 裡面")
	}
}
```

編譯錯誤：

```text
./main.go:7:7: goto inside jumps into block starting at ./main.go:8:11
```

反過來，從區塊**裡面**跳到外面是可以的。另外，`goto` 只能跳到同一個函式裡的標籤，不能跳到別的函式。

### 那什麼時候會看到它？

在一般的程式碼裡，`for`、`break`、`continue`、標籤 `break`、`return` 已經能處理幾乎所有情況。`goto` 偶爾會出現在標準函式庫或自動產生的程式碼裡，處理一些特別講究效能的流程。

所以你只要做到：看到 `goto` 時知道它在做什麼，自己寫程式時優先用其他寫法。

## 重點整理

- `goto 標籤` 會跳到同一個函式裡該標籤的位置繼續執行。
- 不能跳過變數宣告，也不能從外面跳進區塊。
- `goto` 讓程式流程難追，平常請優先用 `for`、`break`、`continue`、`return`。
