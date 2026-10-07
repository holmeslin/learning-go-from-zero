# `bufio`

## 本集目標

看懂第 1 章讀輸入固定句型背後的原理，學會用 `bufio.Scanner` 一行一行（或一個字一個字）讀取，以及用 `bufio.Writer` 加速輸出並記得 `Flush`。

## 正文

`bufio` 的 `buf` 是 buffer（緩衝區）。它把上一集的 Reader 和 Writer 包一層，加上「一次搬一大塊，再慢慢分給你」的功能。

### 回頭看第 1 章的固定句型

第 1 章我們照抄過這三行：

```go,ignore
scanner := bufio.NewScanner(os.Stdin)
scanner.Scan()
line := scanner.Text()
```

現在可以完整解釋了：

- `os.Stdin` 是一個 `io.Reader`，代表鍵盤輸入。
- `bufio.NewScanner` 接收任何 `io.Reader`，回傳一個 `*bufio.Scanner`。
- `scanner.Scan()` 是方法，它往下讀到一行結束為止，回傳一個 `bool`：讀到東西是 `true`，沒得讀（`io.EOF`）或出錯是 `false`。以前我們沒理會這個回傳值。
- `scanner.Text()` 回傳剛剛讀到的那一行，不包含換行字元。

既然 `NewScanner` 吃的是 `io.Reader`，我們就能換成 `strings.NewReader`，不用真的打字也能測試。

### `for scanner.Scan()`：讀到沒有為止

因為 `Scan` 回傳 `bool`，最常見的寫法是直接當成 `for` 的條件：

```go
package main

import (
	"bufio"
	"fmt"
	"strings"
)

func main() {
	input := "蘋果\n香蕉\n芭樂\n"
	scanner := bufio.NewScanner(strings.NewReader(input))
	count := 0
	for scanner.Scan() {
		count++
		fmt.Println(count, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		fmt.Println("讀取錯誤:", err)
	}
	fmt.Println("共", count, "行")
}
```

執行結果：

```text
1 蘋果
2 香蕉
3 芭樂
共 3 行
```

迴圈結束有兩種可能：正常讀完，或是中途出錯。`scanner.Err()` 用來分辨：正常讀完時它是 `nil`（`io.EOF` 不算錯誤）。

把 `strings.NewReader(input)` 換回 `os.Stdin`，就能讀取使用者輸入的每一行，直到輸入結束。下面的範例假設依序輸入 `3`、`5`、`10` 三行：

```go,stdin=3\n5\n10
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	sum := 0
	for scanner.Scan() {
		n, err := strconv.Atoi(scanner.Text())
		if err != nil {
			fmt.Println("跳過不是整數的行:", scanner.Text())
			continue
		}
		sum += n
	}
	fmt.Println("總和:", sum)
}
```

執行結果：

```text
總和: 18
```

在終端機手動輸入時，按 `Ctrl+D`（Windows 是 `Ctrl+Z` 再按 Enter）表示輸入結束。

### 改成一個字一個字讀

Scanner 預設以「行」為單位切開。用 `Split` 可以換成別的切法，例如 `bufio.ScanWords` 以空白切成一個一個單字：

```go
package main

import (
	"bufio"
	"fmt"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(strings.NewReader("Go  is\nreally   fun"))
	scanner.Split(bufio.ScanWords)
	for scanner.Scan() {
		fmt.Printf("[%s]", scanner.Text())
	}
	fmt.Println()
}
```

執行結果：

```text
[Go][is][really][fun]
```

連續的空白和換行都被當成分隔，不會產生空字串。`Split` 要在第一次呼叫 `Scan` 之前設定。

另外要知道：Scanner 一行預設最多 64KB，超過會停下來並在 `Err()` 回報錯誤。一般文字檔不會遇到，真的要讀超長的行再查 `scanner.Buffer` 方法。

### `bufio.Writer` 與 `Flush`

每呼叫一次 `fmt.Println`，程式就要請作業系統輸出一次，大量輸出時這很慢。`bufio.Writer` 會先把資料存在自己的緩衝區，攢夠了才一次寫出去：

```go
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	w := bufio.NewWriter(os.Stdout)
	defer w.Flush()

	for i := range 3 {
		fmt.Fprintln(w, "第", i+1, "行")
	}
	fmt.Fprintln(w, "結束")
}
```

執行結果：

```text
第 1 行
第 2 行
第 3 行
結束
```

`bufio.NewWriter` 收一個 `io.Writer`，回傳的 `*bufio.Writer` 本身也是 `io.Writer`，所以 `fmt.Fprintln` 可以直接寫進去。

最重要的是 `Flush`：它把緩衝區裡剩下的資料真正寫出去。如果忘了呼叫，最後一批資料就會留在緩衝區，跟著程式一起消失：

```go
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	w := bufio.NewWriter(os.Stdout)
	fmt.Fprintln(w, "這行永遠不會出現")
	fmt.Println("程式結束")
}
```

執行結果：

```text
程式結束
```

`fmt.Println` 直接寫到 `os.Stdout`，所以有出現；寫進 `w` 的那行還躺在緩衝區裡，沒人 `Flush`，就不見了。所以建好 `bufio.Writer` 之後，習慣立刻接一行 `defer w.Flush()`。

`Flush` 也會回傳 `error`，寫檔案時如果在意寫入有沒有成功，應該檢查它，而不是只用 `defer` 丟掉。

## 重點整理

- `bufio.NewScanner` 接收任何 `io.Reader`；`Scan()` 回傳 `bool`，`Text()` 拿到這次讀到的內容。
- `for scanner.Scan() { ... }` 讀到沒有為止，結束後用 `scanner.Err()` 檢查有沒有出錯。
- `scanner.Split(bufio.ScanWords)` 可以改成以單字為單位切開。
- `bufio.NewWriter` 先把輸出存在緩衝區；一定要 `Flush`，否則最後的資料會遺失。
