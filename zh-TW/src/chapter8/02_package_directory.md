# 套件與目錄

## 本集目標

了解套件（package）和資料夾的關係，把程式碼拆到另一個套件，並看懂 `package main` 的意思。

## 正文

### 每個檔案的第一行

從第 1 章開始，每個程式的第一行都是 `package main`。這一行宣告「這個檔案屬於哪個**套件**」。

套件是 Go 組織程式碼的基本單位，規則很單純：

- **一個資料夾就是一個套件。** 同一個資料夾裡的 `.go` 檔案，第一行的 `package` 名稱必須一樣。
- 同一個套件裡的函式、變數、型別，不管寫在哪個檔案，都可以直接互相使用。

### `main` 套件是特別的

名叫 `main` 的套件有特殊意義：它會被編譯成**可以執行的程式**，而執行時從 `func main()` 開始跑。這就是為什麼第 1 章的程式骨架一定是 `package main` 加上 `func main()`。

其他名字的套件不能直接執行，它們是讓別人 `import` 來用的工具箱，`fmt`、`strings` 都是這種套件。

### 拆出一個套件

我們建立一個模組 `myapp`，把打招呼的功能放進 `greet` 套件。資料夾結構如下：

```text
myapp/
├── go.mod
├── main.go
└── greet/
    └── greet.go
```

`go.mod`：

```gomod
module myapp

go 1.27
```

`greet/greet.go`：

```go,ignore
package greet

func Hello(name string) string {
	return "你好，" + name + "！"
}
```

`main.go`：

```go,ignore
package main

import (
	"fmt"

	"myapp/greet"
)

func main() {
	fmt.Println(greet.Hello("小明"))
}
```

在 `myapp` 資料夾執行：

```bash
go run .
```

執行結果：

```text
你好，小明！
```

### 這段程式在做什麼

- `greet/greet.go` 放在 `greet` 資料夾，第一行寫 `package greet`。慣例上，套件名稱和資料夾名稱相同，全小寫、不加底線。
- `main.go` 用 `import "myapp/greet"` 引入這個套件。引入的路徑是「模組路徑 + 資料夾路徑」，模組路徑就是 `go.mod` 裡的 `myapp`。
- 使用時寫 `greet.Hello(...)`：套件名稱、一個點、再接名稱。這和 `fmt.Println` 是完全一樣的寫法。

`import` 的括號裡，標準庫的套件和自己模組的套件中間空一行，這是 `gofmt` 和大家習慣的排法。

### 一個套件可以有很多檔案

套件變大時，可以在 `greet` 資料夾裡再加檔案，例如 `greet/bye.go`：

```go,ignore
package greet

func Bye(name string) string {
	return "再見，" + name + "！"
}
```

只要第一行同樣是 `package greet`，`Bye` 就屬於 `greet` 套件，`main.go` 可以直接用 `greet.Bye("小明")`，不需要多寫一行 `import`。

## 重點整理

- 一個資料夾就是一個套件，同資料夾的檔案 `package` 名稱必須相同，名稱慣例上和資料夾同名。
- `package main` 會被編譯成可執行的程式，從 `func main()` 開始執行。
- 引入自己模組的套件時，路徑是「模組路徑/資料夾路徑」，例如 `myapp/greet`。
- 使用其他套件的東西要寫 `套件名.名稱`，例如 `greet.Hello`。
