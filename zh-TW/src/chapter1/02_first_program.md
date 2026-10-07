# 第一個程式

## 本集目標

建立一個 Go 專案，寫出並執行第一個會印出文字的程式。

## 正文

### 建立專案資料夾

每個 Go 程式都放在自己的資料夾裡。打開終端機，依序輸入下面三行指令：

```bash
mkdir hello
cd hello
go mod init hello
```

一行一行來看：

- `mkdir hello`：建立一個叫 `hello` 的資料夾。
- `cd hello`：走進這個資料夾，之後的指令都在這裡面執行。
- `go mod init hello`：告訴 Go「這個資料夾是一個叫 `hello` 的專案」。它會在資料夾裡產生一個 `go.mod` 檔案，記錄專案的名稱和 Go 版本。這個檔案現在不用去動它。

### 寫程式碼

用 VS Code 打開 `hello` 資料夾，在裡面新增一個檔案，取名為 `main.go`，然後把下面的程式碼打進去：

```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
```

建議用打的而不是複製貼上，比較容易記住。存檔。

### 執行

回到終端機（確認還在 `hello` 資料夾裡），輸入：

```bash
go run .
```

執行結果：

```text
Hello, World!
```

恭喜！你的第一個 Go 程式跑起來了。`go run .` 的意思是「執行目前這個資料夾裡的程式」，那個 `.` 代表「目前的資料夾」。

### 這些程式碼是什麼意思？

現在先把程式碼分成兩部分來看：

```go,ignore
package main

import "fmt"

func main() {
	...
}
```

這是每支 Go 程式都需要的「骨架」。`package main`、`import "fmt"`、`func main() { ... }` 這三樣東西，現在請先**照抄**就好，它們的意思會在後面的章節解釋（函式在第 2 章，`package` 和 `import` 在第 8 章）。現在你只需要知道：程式會從 `func main()` 的大括號 `{}` 裡面開始執行。

大括號裡的 `fmt.Println("Hello, World!")` 才是我們真正要電腦做的事：把 `Hello, World!` 印到畫面上。下一集會好好介紹它。

之後本書的每個範例都會長成這個樣子。想自己試的話，把 `main.go` 的內容換成範例程式碼，再執行 `go run .` 就可以了。

## 重點整理

- 用 `mkdir`、`cd` 建立並進入資料夾，再用 `go mod init <名稱>` 建立專案。
- 程式碼寫在 `main.go`，用 `go run .` 執行。
- `package main`、`import "fmt"`、`func main() { ... }` 是程式骨架，先照抄，之後章節會解釋。
- 程式從 `func main()` 的大括號裡開始執行。
