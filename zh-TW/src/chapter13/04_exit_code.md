# 結束碼

## 本集目標

知道程式結束時會回報一個「結束碼」，會用 `os.Exit` 回傳正確的數字，並避開 `os.Exit` 讓 `defer` 不執行的陷阱。

## 正文

### 程式的最後一句話

每支程式結束時，都會交給作業系統一個整數，叫做**結束碼**（exit code）。約定很簡單：**0 代表成功，不是 0 代表失敗**。

在終端機裡，剛結束的那支程式的結束碼放在 `$?`，可以用 `echo` 看：

```bash
go build -o greet .
./greet
echo $?
./greet -n abc
echo $?
```

`greet` 是第 2 集用 `flag` 寫的程式。第一次正常結束，第二次選項打錯：

執行結果：

```text
哈囉，世界
0
invalid value "abc" for flag -n: parse error
Usage of ./greet:
  -loud
    	大聲一點（加上驚嘆號）
  -n int
    	重複幾次 (default 1)
  -name string
    	要打招呼的對象 (default "世界")
2
```

`main` 函式正常跑完，結束碼就是 0。`flag` 解析失敗時用的是 2。

為什麼要在意？因為別的程式（還有 shell 指令稿）是靠結束碼判斷你成功了沒。例如 `./greet && echo 成功` 只有在 `greet` 結束碼為 0 時才會印出「成功」。CLI 工具出錯卻回傳 0，就等於說謊。

### `os.Exit`

想自己指定結束碼，就呼叫 `os.Exit`：

```go,exit=2
package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "用法：hello <名字>")
		os.Exit(2)
	}
	fmt.Println("哈囉，" + os.Args[1])
}
```

執行結果：

```text
用法：hello <名字>
```

這次沒有給參數，所以程式印出用法後以結束碼 2 結束。`os.Exit` 會**立刻**結束整支程式，後面的程式碼都不會執行。

常見的慣例：

| 結束碼 | 意思 |
| --- | --- |
| 0 | 成功 |
| 1 | 一般錯誤，例如檔案打不開、網路連不上 |
| 2 | 用法錯誤，例如參數不夠、選項打錯（`flag` 就是用 2） |

你可能還記得第 5 章說過，`panic` 讓程式結束時的結束碼也是 2。不用擔心兩者撞號，`panic` 會印出一大段錯誤訊息，很好分辨。

### 陷阱：`os.Exit` 不會執行 `defer`

`os.Exit` 是「立刻」結束，連 `defer` 都不等：

```go,exit=1
package main

import (
	"fmt"
	"os"
)

func main() {
	defer fmt.Println("收尾：關閉檔案")

	fmt.Println("開始工作")
	fmt.Fprintln(os.Stderr, "出錯了")
	os.Exit(1)
}
```

執行結果：

```text
開始工作
出錯了
```

「收尾：關閉檔案」沒有印出來！如果 `defer` 裡做的是關閉檔案、把緩衝區寫進磁碟，這些事就全被跳過了。

### 慣用寫法：把工作放進 `run`

解決辦法是讓 `main` 只做一件事：呼叫真正做事的函式，看它有沒有回傳錯誤，再決定結束碼。所有的 `defer` 都寫在 `run` 裡面：

```go,exit=1
package main

import (
	"errors"
	"fmt"
	"os"
)

func run() error {
	defer fmt.Println("收尾：關閉檔案")

	fmt.Println("開始工作")
	return errors.New("讀取設定失敗")
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, "錯誤：", err)
		os.Exit(1)
	}
}
```

執行結果：

```text
開始工作
收尾：關閉檔案
錯誤： 讀取設定失敗
```

`run` 用 `return` 結束，所以它的 `defer` 會照常執行；回到 `main` 之後才呼叫 `os.Exit(1)`，這時 `main` 自己沒有任何 `defer`，就不會漏掉東西。這個「`main` 很薄、`run` 回傳 `error`」的寫法在 Go 的 CLI 工具裡非常常見，第 8 集的完整範例也會用它。

## 重點整理

- 程式結束時會回報結束碼：0 是成功，非 0 是失敗；在終端機用 `echo $?` 查看。
- 慣例：0 成功、1 一般錯誤、2 用法錯誤。
- `os.Exit(n)` 立刻結束程式，**不會執行 `defer`**。
- 把工作寫在回傳 `error` 的 `run` 函式裡，`main` 只負責印錯誤和呼叫 `os.Exit`。
