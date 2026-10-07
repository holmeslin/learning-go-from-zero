# stdin/stdout 管線

## 本集目標

寫出能放進管線（`|`）的程式：從標準輸入讀資料、結果寫到標準輸出、錯誤訊息寫到標準錯誤。

## 正文

### 三條管子

每支程式一啟動，就自動接好三條「管子」：

| 名稱 | Go 裡的變數 | 預設接到 |
| --- | --- | --- |
| 標準輸入（stdin） | `os.Stdin` | 鍵盤 |
| 標準輸出（stdout） | `os.Stdout` | 終端機畫面 |
| 標準錯誤（stderr） | `os.Stderr` | 終端機畫面 |

`fmt.Println` 其實就是寫到 `os.Stdout`；第 1 章的讀一行輸入固定句型，讀的就是 `os.Stdin`。stdout 和 stderr 平常都顯示在畫面上，看起來一樣，但它們是兩條不同的管子，這一點等一下會很重要。

### 一直讀到沒有資料為止

以前我們只讀一行。CLI 工具通常要把輸入**全部**讀完，做法是把 `scanner.Scan()` 放進 `for` 迴圈：沒有下一行時它回傳 `false`，迴圈就結束。

下面這支 `sum` 把每一行的整數加起來，看不懂的行就略過，並把警告寫到 stderr：

```go,stdin=10\n20\nabc\n\n30
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	total := 0
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		n, err := strconv.Atoi(line)
		if err != nil {
			fmt.Fprintf(os.Stderr, "第 %d 行不是整數，略過：%q\n", lineNo, line)
			continue
		}
		total += n
	}
	if err := scanner.Err(); err != nil {
		fmt.Fprintln(os.Stderr, "讀取失敗：", err)
		os.Exit(1)
	}
	fmt.Println(total)
}
```

執行結果：

```text
第 3 行不是整數，略過："abc"
60
```

幾個重點：

- `for scanner.Scan()` 會一行一行讀，直到輸入結束。
- 迴圈結束後要檢查 `scanner.Err()`：輸入正常讀完時它是 `nil`，真的出錯（例如讀取失敗、某一行太長）才不是 `nil`。
- **結果**用 `fmt.Println` 寫到 stdout，**警告和錯誤**用 `fmt.Fprintln(os.Stderr, ...)` 寫到 stderr。

從鍵盤直接執行時，打完資料要按 Ctrl+D（Windows 是 Ctrl+Z 再按 Enter）告訴程式「輸入結束了」。

### 接上管線

真正好玩的是不用鍵盤，而是把別的程式的輸出接過來。終端機裡的 `|` 叫做**管線**（pipe），它把左邊程式的 stdout 接到右邊程式的 stdin：

```bash
go build -o sum .
printf '10\n20\nabc\n\n30\n' > nums.txt
seq 1 5 | ./sum
cat nums.txt | ./sum
./sum < nums.txt
```

執行結果：

```text
15
第 3 行不是整數，略過："abc"
60
第 3 行不是整數，略過："abc"
60
```

- `seq 1 5` 會輸出 1 到 5 各一行，`sum` 把它們加起來。
- `cat nums.txt | ./sum` 把檔案內容透過管線送進來。
- `./sum < nums.txt` 是**輸入重新導向**，直接把檔案接到 stdin，效果一樣。

`sum` 完全不知道資料是從鍵盤、檔案還是另一支程式來的，它只管讀 `os.Stdin`。這就是管線的威力：每支小程式只做一件事，再用 `|` 串起來。

### 為什麼錯誤要寫到 stderr

用 `>` 可以把 stdout 存進檔案：

```bash
./sum < nums.txt > result.txt
cat result.txt
```

執行結果：

```text
第 3 行不是整數，略過："abc"
60
```

第一行是執行 `./sum` 時直接出現在畫面上的警告，第二行是 `cat result.txt` 印出的檔案內容。`>` 只會導走 stdout，所以：

- `result.txt` 裡只有乾淨的結果 `60`，下一支程式可以放心拿去用。
- 警告走 stderr，仍然顯示在畫面上，使用者不會錯過。

如果把警告也用 `fmt.Println` 印，它就會混進 `result.txt`，把資料弄髒。這就是為什麼第 2 集的用法說明、第 4 集的錯誤訊息，都寫到 `os.Stderr`。

### 大量輸出時用 `bufio.Writer`

每次 `fmt.Println` 到 `os.Stdout` 都會直接寫一次，輸出幾十萬行時會很慢。可以用第 12 章的 `bufio.NewWriter` 先累積起來再一次寫出：

```go,stdin=go\nrust\nzig
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	w := bufio.NewWriter(os.Stdout)
	defer w.Flush()

	for scanner.Scan() {
		fmt.Fprintln(w, strings.ToUpper(scanner.Text()))
	}
}
```

執行結果：

```text
GO
RUST
ZIG
```

記得 `defer w.Flush()`，否則最後還留在緩衝區的資料不會寫出去。也因為這樣，用了 `bufio.Writer` 的程式更要注意第 4 集的陷阱：在 `main` 裡呼叫 `os.Exit` 會跳過 `Flush`。

這支 `upper` 也能接在管線中間，例如 `./upper < langs.txt | sort -r` 會先轉大寫，再交給 `sort` 反向排序。

## 重點整理

- 每支程式都有 stdin、stdout、stderr 三條管子，對應 `os.Stdin`、`os.Stdout`、`os.Stderr`。
- 用 `for scanner.Scan()` 讀完全部輸入，結束後檢查 `scanner.Err()`。
- 結果寫 stdout，錯誤與警告寫 stderr，這樣 `> 檔案` 或 `|` 只會拿到乾淨的資料。
- `a | b` 把 a 的輸出接到 b 的輸入；`< 檔案` 把檔案接到 stdin。
- 大量輸出用 `bufio.NewWriter(os.Stdout)`，並記得 `defer w.Flush()`。
