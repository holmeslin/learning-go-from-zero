# `os.Args`

## 本集目標

知道怎麼讀到使用者在指令後面打的參數，並分清楚 `os.Args[0]` 和真正的參數。

## 正文

### 指令後面的那些字

在終端機打 `go build -o hello .` 時，`-o`、`hello`、`.` 都是交給 `go` 這支程式的**命令列參數**（command-line arguments）。我們自己寫的程式也收得到，放在 `os.Args` 這個字串切片裡：

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println("參數個數：", len(os.Args)-1)
	for i, arg := range os.Args[1:] {
		fmt.Printf("第 %d 個：%s\n", i+1, arg)
	}
}
```

執行結果：

```text
參數個數： 0
```

直接執行時沒有給參數，所以是 0。在指令後面多打幾個字，它們就會依序出現：

```bash
go run . 小明 小美 "王 大明"
```

執行結果：

```text
參數個數： 3
第 1 個：小明
第 2 個：小美
第 3 個：王 大明
```

參數之間用空白分開。想讓一個參數裡面包含空白，就用引號包起來，像 `"王 大明"` 就是一個參數。

### `os.Args[0]` 是程式自己

為什麼上面要從 `os.Args[1:]` 開始？因為 `os.Args[0]` 固定是「這支程式是怎麼被叫起來的」，通常是執行檔的路徑。把整個 `os.Args` 印出來看看：

```go,norun
package main

import (
	"fmt"
	"os"
)

func main() {
	fmt.Println(os.Args)
}
```

先用 `go build` 編譯成名叫 `hello` 的執行檔，再帶參數執行：

```bash
go build -o hello .
./hello 你好
```

執行結果：

```text
[./hello 你好]
```

用 `go run .` 執行時，Go 會先把程式編譯到一個暫存資料夾再執行，所以 `os.Args[0]` 會是一串很長的暫存路徑。不管怎樣，真正的參數都從 `os.Args[1]` 開始。

### 先檢查長度再取值

使用者不一定會照你想的方式打指令。直接取 `os.Args[1]`，如果沒有參數就會 `panic`（索引超出範圍）。所以要先檢查長度：

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("用法：greet <名字>...")
		return
	}
	for _, name := range os.Args[1:] {
		fmt.Println("哈囉，" + name)
	}
}
```

執行結果：

```text
用法：greet <名字>...
```

上面是沒給參數的情況。給了參數之後：

```bash
go run . Andy Bob
```

執行結果：

```text
哈囉，Andy
哈囉，Bob
```

沒給參數時印出**用法說明**（usage），是 CLI 工具的禮貌。

### 參數一律是字串

`os.Args` 的元素都是 `string`。就算使用者打的是 `42`，你拿到的也是字串 `"42"`，要當數字用就得自己用 `strconv.Atoi` 轉換、檢查錯誤。

自己處理 `os.Args` 很快就會變得麻煩：選項的順序、`-n 3` 和 `-n=3` 兩種寫法、預設值、說明文字……下一集的 `flag` 套件會幫我們做掉這些事。

## 重點整理

- 命令列參數放在 `os.Args`，型別是 `[]string`。
- `os.Args[0]` 是程式本身的路徑，真正的參數從 `os.Args[1:]` 開始。
- 取值前先檢查 `len(os.Args)`，參數不夠時印出用法說明。
- 參數都是字串，需要數字要自己轉換並檢查錯誤。
