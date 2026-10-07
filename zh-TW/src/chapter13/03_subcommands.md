# 子命令

## 本集目標

做出像 `go build`、`go test` 那樣「一支程式、好幾個子命令」的工具，而且每個子命令有自己的選項。

## 正文

### 什麼是子命令

`go` 這支程式本身不做事，真正的工作由第一個參數決定：`go build` 編譯、`go test` 測試、`go mod init` 建立模組。這個第一個參數就是**子命令**（subcommand）。而且 `go build -o` 的 `-o`，在 `go test` 裡並不存在：每個子命令有自己的一組選項。

做法分兩步：

1. 看 `os.Args[1]` 決定要執行哪個子命令。
2. 每個子命令用 `flag.NewFlagSet` 建立自己的選項，解析 `os.Args[2:]`。

### 範例：`textkit`

我們做一個小工具，有 `upper`（轉大寫）和 `repeat`（重複）兩個子命令：

```go
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

func usage() {
	fmt.Fprintln(os.Stderr, "用法：textkit <子命令> [選項] <字>...")
	fmt.Fprintln(os.Stderr)
	fmt.Fprintln(os.Stderr, "子命令：")
	fmt.Fprintln(os.Stderr, "  upper   轉成大寫")
	fmt.Fprintln(os.Stderr, "  repeat  重複好幾次")
}

func upperCmd(args []string) {
	fs := flag.NewFlagSet("upper", flag.ExitOnError)
	fs.Parse(args)
	fmt.Println(strings.ToUpper(strings.Join(fs.Args(), " ")))
}

func repeatCmd(args []string) {
	fs := flag.NewFlagSet("repeat", flag.ExitOnError)
	n := fs.Int("n", 2, "重複幾次")
	sep := fs.String("sep", " ", "分隔符號")
	fs.Parse(args)

	text := strings.Join(fs.Args(), " ")
	parts := make([]string, *n)
	for i := range parts {
		parts[i] = text
	}
	fmt.Println(strings.Join(parts, *sep))
}

func main() {
	if len(os.Args) < 2 {
		usage()
		return
	}
	switch os.Args[1] {
	case "upper":
		upperCmd(os.Args[2:])
	case "repeat":
		repeatCmd(os.Args[2:])
	default:
		fmt.Fprintln(os.Stderr, "不認得的子命令：", os.Args[1])
		usage()
	}
}
```

執行結果：

```text
用法：textkit <子命令> [選項] <字>...

子命令：
  upper   轉成大寫
  repeat  重複好幾次
```

沒有給子命令時，印出用法說明。來看看實際使用的樣子：

```bash
go build -o textkit .
./textkit upper hello go
./textkit repeat -n 3 -sep " | " 咚
./textkit repeat 哈
```

執行結果：

```text
HELLO GO
咚 | 咚 | 咚
哈 哈
```

### 一步一步看

- `main` 先確認至少有一個參數，再用 `switch` 依 `os.Args[1]` 分派給對應的函式；不認得的子命令就印出錯誤和用法。
- 每個子命令函式收到的是 `os.Args[2:]`，也就是**去掉程式名稱和子命令之後**剩下的參數。
- `repeatCmd` 用 `flag.NewFlagSet("repeat", ...)` 建立自己的選項 `-n` 和 `-sep`，`upperCmd` 則沒有任何選項。`NewFlagSet` 的第一個參數是名稱，會出現在說明文字裡。

### 每個子命令有自己的說明

因為每個子命令都是獨立的 `FlagSet`，`-h` 也各自分開。`./textkit repeat -h`：

執行結果：

```text
Usage of repeat:
  -n int
    	重複幾次 (default 2)
  -sep string
    	分隔符號 (default " ")
```

把 `repeat` 的選項拿去給 `upper` 用，就會被拒絕。`./textkit upper -n 3 a`：

執行結果：

```text
flag provided but not defined: -n
Usage of upper:
```

`upper` 沒有任何選項，所以 `Usage of upper:` 底下是空的。

### 子命令要寫在最前面

有了子命令，參數的順序就是「程式名稱 → 子命令 → 子命令的選項 → 位置參數」。如果你想要所有子命令共用的選項（例如 `-verbose`），可以先用預設的 `flag.Parse()` 解析它們，再拿 `flag.Args()` 的第一個字當子命令，剩下的交給子命令的 `FlagSet`。小工具通常用不到，先記得有這個做法就好。

## 重點整理

- 子命令就是第一個參數，用 `switch os.Args[1]` 分派給不同的函式。
- 每個子命令用 `flag.NewFlagSet` 建立自己的選項，解析 `os.Args[2:]`。
- 每個 `FlagSet` 有自己的 `-h` 說明，名稱就是 `NewFlagSet` 的第一個參數。
- 沒給或給錯子命令時，印出錯誤與用法說明。
