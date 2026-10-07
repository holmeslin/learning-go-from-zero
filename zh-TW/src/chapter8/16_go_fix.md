# `go fix`

## 本集目標

用 `go fix` 自動把舊式寫法改成新版 Go 的寫法。

## 正文

### 舊寫法還在到處跑

Go 很重視相容性，十年前寫的程式到今天幾乎都還能編譯。但語言和標準庫一直在進步，很多事情現在有更短、更清楚的寫法。例如：

- `interface{}` 現在可以寫成 `any`（第 4 章）。
- `for i := 0; i < 3; i++` 可以寫成 `for i := range 3`（第 1 章）。
- 用 `if` 挑出比較大的數，可以直接用內建的 `max`（第 2 章）。

網路上、舊專案裡充滿了舊寫法。一個一個找出來手動改太累了，`go fix` 可以幫我們自動改。

從 Go 1.26 開始，`go fix` 就是做這件事的工具：它內建一批「現代化」規則，找出可以改用新寫法的地方，直接幫你改好。

### 一個充滿舊寫法的程式

`main.go`：

```go
package main

import (
	"fmt"
	"strings"
)

func show(v interface{}) {
	fmt.Println(v)
}

func main() {
	for i := 0; i < 3; i++ {
		show(i)
	}

	a, b := 3, 7
	bigger := a
	if b > a {
		bigger = b
	}
	show(bigger)

	for _, w := range strings.Split("go is fun", " ") {
		show(w)
	}
}
```

執行結果：

```text
0
1
2
7
go
is
fun
```

程式完全正確，只是寫法比較舊。

### 先看看會改什麼

加上 `-diff`，`go fix` 只會顯示打算怎麼改，不會動到檔案：

```bash
go fix -diff ./...
```

```text
--- main.go (old)
+++ main.go (new)
@@ -5,23 +5,20 @@
 	"strings"
 )
 
-func show(v interface{}) {
+func show(v any) {
 	fmt.Println(v)
 }
 
 func main() {
-	for i := 0; i < 3; i++ {
+	for i := range 3 {
 		show(i)
 	}
 
 	a, b := 3, 7
-	bigger := a
-	if b > a {
-		bigger = b
-	}
+	bigger := max(b, a)
 	show(bigger)
 
-	for _, w := range strings.Split("go is fun", " ") {
+	for w := range strings.SplitSeq("go is fun", " ") {
 		show(w)
 	}
 }
```

（實際輸出中，檔名前面會有完整的資料夾路徑，這裡省略了。）

四個地方都被找出來了。最後一個很有意思：`strings.Split` 會先建立一個切片，`strings.SplitSeq` 則回傳第 7 章學過的迭代器，一個一個交出切好的字串，不必先建立整個切片。

### 真的修改

確認沒問題後，拿掉 `-diff`：

```bash
go fix ./...
```

沒有任何輸出，但 `main.go` 已經變成新寫法了：

```go
package main

import (
	"fmt"
	"strings"
)

func show(v any) {
	fmt.Println(v)
}

func main() {
	for i := range 3 {
		show(i)
	}

	a, b := 3, 7
	bigger := max(b, a)
	show(bigger)

	for w := range strings.SplitSeq("go is fun", " ") {
		show(w)
	}
}
```

執行結果和原本完全一樣：

```text
0
1
2
7
go
is
fun
```

`go fix` 的規則都經過設計，只做「意思不變」的修改。不過改完之後，還是跑一次 `go test ./...` 確認比較安心。

### 有哪些規則

想知道 `go fix` 會做哪些修改，執行：

```bash
go tool fix help
```

會列出所有規則和一行說明，例如 `any`（把 `interface{}` 換成 `any`）、`rangeint`（把三段式 `for` 換成 `range` 整數）、`minmax`（換成 `min`、`max`）、`stringsseq`（換成 `SplitSeq` 這類迭代器版本）等等。

## 重點整理

- `go fix ./...` 會把舊式寫法自動改成新版 Go 的寫法，例如 `interface{}` → `any`、三段式 `for` → `range` 整數。
- 加上 `-diff` 只顯示會怎麼改，不修改檔案。
- 修改不會改變程式的意思，但改完仍建議跑一次測試。
- `go tool fix help` 列出所有可用的規則。
