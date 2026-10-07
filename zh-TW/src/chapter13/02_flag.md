# `flag`

## 本集目標

會用標準庫的 `flag` 套件定義選項（`-name 小美`、`-n 3`、`-loud`），讀取剩下的參數，並自訂用法說明。

## 正文

### 定義選項

很多指令都有「選項」（flag），像 `go build -o hello` 的 `-o`。`flag` 套件幫我們解析這種寫法，三個最常用的函式是 `flag.String`、`flag.Int`、`flag.Bool`：

```go
package main

import (
	"flag"
	"fmt"
)

func main() {
	name := flag.String("name", "世界", "要打招呼的對象")
	times := flag.Int("n", 1, "重複幾次")
	loud := flag.Bool("loud", false, "大聲一點（加上驚嘆號）")
	flag.Parse()

	msg := "哈囉，" + *name
	if *loud {
		msg += "！！！"
	}
	for range *times {
		fmt.Println(msg)
	}
}
```

執行結果：

```text
哈囉，世界
```

一步一步看：

- 每個函式收三個參數：選項名稱、預設值、說明文字。
- 它們回傳的是**指標**（`*string`、`*int`、`*bool`），所以使用時要寫 `*name`。因為真正的值要等到解析完才知道，`flag` 先給你一個「之後會放好值的位置」。
- `flag.Parse()` 才是真正去讀 `os.Args[1:]` 的那一步，一定要在使用選項之前呼叫。

沒給任何選項時，用的都是預設值。帶上選項執行：

```bash
go build -o greet .
./greet -name 小美 -n 2 -loud
./greet -name=Andy --n=3
```

執行結果：

```text
哈囉，小美！！！
哈囉，小美！！！
哈囉，Andy
哈囉，Andy
哈囉，Andy
```

選項可以寫成 `-name 小美` 或 `-name=小美`，一個減號或兩個減號都可以。`bool` 選項比較特別：只寫 `-loud` 就代表 `true`。

### 免費的 `-h` 與錯誤訊息

`flag` 會自動幫你做出說明。執行 `./greet -h`：

執行結果：

```text
Usage of ./greet:
  -loud
    	大聲一點（加上驚嘆號）
  -n int
    	重複幾次 (default 1)
  -name string
    	要打招呼的對象 (default "世界")
```

使用者打錯時，`flag.Parse()` 會印出錯誤加上同樣的說明，然後直接結束程式。例如 `./greet -n abc`：

執行結果：

```text
invalid value "abc" for flag -n: parse error
Usage of ./greet:
  -loud
    	大聲一點（加上驚嘆號）
  -n int
    	重複幾次 (default 1)
  -name string
    	要打招呼的對象 (default "世界")
```

`-n` 是 `int` 選項，`abc` 轉不成整數，所以你在程式裡完全不用自己寫 `strconv.Atoi`。

### 剩下的參數：`flag.Args`

選項後面不屬於任何選項的字，叫做**位置參數**。解析完之後用 `flag.Args()` 拿到（型別是 `[]string`），`flag.NArg()` 是它的個數：

```go
package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	sep := flag.String("sep", " ", "字之間的分隔符號")
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "用法：join [選項] <字>...")
		fmt.Fprintln(os.Stderr, "把所有的字接成一行。")
		fmt.Fprintln(os.Stderr)
		fmt.Fprintln(os.Stderr, "選項：")
		flag.PrintDefaults()
	}
	flag.Parse()

	if flag.NArg() == 0 {
		flag.Usage()
		return
	}
	fmt.Println(strings.Join(flag.Args(), *sep))
}
```

執行結果：

```text
用法：join [選項] <字>...
把所有的字接成一行。

選項：
  -sep string
    	字之間的分隔符號 (default " ")
```

這支程式沒拿到任何字，所以印出用法。帶參數執行：

```bash
go build -o join .
./join -sep , a b c
./join a b -sep ,
```

執行結果：

```text
a,b,c
a b -sep ,
```

注意第二行：**選項必須寫在位置參數前面**。`flag` 一碰到第一個不是選項的字（這裡是 `a`）就停止解析，後面的 `-sep ,` 全部被當成普通的字。`bool` 選項也要小心：`-loud false` 會被當成「`-loud` 加上一個位置參數 `false`」，想關掉要寫 `-loud=false`。

### 自訂用法說明：`flag.Usage`

上面的程式把自己的函式指定給 `flag.Usage`。`-h` 或解析出錯時，`flag` 都會呼叫它，所以說明文字可以寫成你想要的樣子。裡面的 `flag.PrintDefaults()` 會印出所有選項的清單。說明文字寫到 `os.Stderr`（標準錯誤）是慣例，第 5 集會解釋為什麼。

沒拿到參數時，我們用 `return` 結束；更好的做法是回傳一個表示「用法錯誤」的結束碼，第 4 集會介紹。

### `FlagSet`：自己的一組選項

`flag.String` 這些函式其實是把選項註冊到一個預設的 `*flag.FlagSet`（名叫 `flag.CommandLine`），再由 `flag.Parse()` 解析 `os.Args[1:]`。我們也可以自己建立一組，並且**指定要解析哪個切片**：

```go
package main

import (
	"flag"
	"fmt"
)

func main() {
	fs := flag.NewFlagSet("greet", flag.ExitOnError)
	name := fs.String("name", "世界", "要打招呼的對象")
	times := fs.Int("n", 1, "重複幾次")

	fs.Parse([]string{"-name", "小美", "-n", "2", "其他", "參數"})

	for range *times {
		fmt.Println("哈囉，" + *name)
	}
	fmt.Println("剩下：", fs.Args())
}
```

執行結果：

```text
哈囉，小美
哈囉，小美
剩下： [其他 參數]
```

`flag.NewFlagSet` 的第二個參數決定解析失敗時怎麼辦：`flag.ExitOnError` 是直接結束程式（`flag.Parse()` 就是這樣）；`flag.ContinueOnError` 則是把錯誤回傳給你自己處理。

能指定切片有兩個好處：一是像上面這樣，不用真的打指令就能試；二是可以讓不同的子命令各有自己的選項，這就是下一集的主題。

## 重點整理

- `flag.String`／`flag.Int`／`flag.Bool` 定義選項（名稱、預設值、說明），回傳指標，要寫 `*name` 取值。
- 一定要先呼叫 `flag.Parse()` 再使用選項；`-h` 與錯誤訊息會自動產生。
- 選項要寫在位置參數前面；位置參數用 `flag.Args()`、`flag.NArg()` 取得。
- 指定 `flag.Usage` 可以自訂說明，`flag.PrintDefaults()` 印出選項清單。
- `flag.NewFlagSet` 建立自己的一組選項，`fs.Parse(切片)` 可以解析任何字串切片。
