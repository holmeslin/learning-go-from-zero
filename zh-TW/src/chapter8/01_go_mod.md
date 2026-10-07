# `go mod init` 與 `go.mod`

## 本集目標

知道什麼是模組、`go mod init` 做了什麼，以及看懂 `go.mod` 檔案裡的每一行。

## 正文

### 回頭看第 1 章

第 1 章寫第一個程式時，我們照抄了兩個指令：

```bash
go mod init hello
go run .
```

當時只說「照做就對了」。現在來解釋。

### 模組是什麼

**模組**（module）是 Go 管理程式碼的最大單位，可以把它想成「一個專案」。一個模組就是一個資料夾，裡面放著這個專案所有的程式碼，最上層有一個 `go.mod` 檔案，記錄這個模組的基本資料。

`go mod init hello` 的意思是：「在目前的資料夾建立一個新模組，名字叫 `hello`」。

```bash
mkdir hello
cd hello
go mod init hello
```

執行結果：

```text
go: creating new go.mod: module hello
```

它只做了一件事：建立 `go.mod` 檔案。

### `go.mod` 的內容

打開剛建立的 `go.mod`，會看到：

```gomod
module hello

go 1.27.0
```

- `module hello`：模組的名字，也叫**模組路徑**。之後模組裡的套件要互相引用，都以這個名字開頭（下一集會用到）。如果打算把程式碼放到網路上給別人用，模組路徑通常會寫成網址的形式，例如 `github.com/你的帳號/hello`；只在自己電腦上練習的話，取個簡單的名字就好。
- `go 1.27.0`：這個模組需要的**最低 Go 版本**，`go mod init` 會填入你目前使用的版本。

最後的 `.0` 可以省略，寫成 `go 1.27` 意思一樣。本書的 `go.mod` 範例都寫成這種較短的形式：

```gomod
module hello

go 1.27
```

### `go` 那一行很重要

這行不只是備註，Go 會依照它決定能使用哪些語言功能。舉例來說，第 3 章的 `new(expr)` 是 Go 1.26 才有的功能。如果把 `go` 那一行改成 `go 1.25`，再編譯 `p := new(3)` 這行程式，就會得到：

```text
./main.go:6:7: new(3) requires go1.26 or later (-lang was set to go1.25; check go.mod)
```

錯誤訊息直接告訴你：這個寫法需要 go1.26 以上，請檢查 `go.mod`。如果你從別處拿到一個舊專案，遇到這種訊息，就是 `go` 那一行的版本太舊了。可以用編輯器直接修改，也可以用指令：

```bash
go mod edit -go=1.27
```

### `go run .` 的那個點

`go run .` 的 `.` 代表「目前的資料夾」。意思是：把目前資料夾裡的程式編譯起來並執行。

Go 是以**資料夾**為單位處理程式碼的，同一個資料夾裡的 `.go` 檔案會被當成一個整體。所以 `main.go` 這個檔名其實不重要，改叫 `app.go` 也能跑；重要的是它在哪個資料夾裡。下一集會詳細說明。

另一個常用的指令是 `go build`，它只編譯、不執行，會在資料夾裡產生一個執行檔：

```bash
go build
./hello
```

執行檔的名字預設就是模組名字的最後一段，這裡是 `hello`。（Windows 上會是 `hello.exe`，執行時打 `.\hello.exe`。）

## 重點整理

- 模組就是一個專案，最上層的 `go.mod` 記錄模組路徑和需要的 Go 版本。
- `go mod init <名稱>` 建立 `go.mod`，並填入目前使用的 Go 版本。
- `go.mod` 的 `go` 那一行是最低 Go 版本，決定能使用哪些語言功能；版本太舊時用 `go mod edit -go=1.27` 修改。
- `go run .` 編譯並執行目前資料夾的程式；`go build` 只編譯並產生執行檔。
