# 完整範例

## 本集目標

把這一章的零件組起來，寫出一支真正能用的字詞統計工具 `wordfreq`。

## 正文

### 我們要做什麼

`wordfreq` 會統計文字有幾行、幾個字，並列出出現最多次的字。它要像一支正經的 CLI 工具：

- 可以讀檔案、讀整個資料夾（第 6 集）；沒給檔案時從 stdin 讀，所以能接在管線後面（第 5 集）。
- 用 `flag` 提供選項：`-top` 列出幾個、`-i` 不分大小寫、`-ext` 走訪資料夾時讀哪種檔案（第 2 集）。
- 錯誤寫到 stderr，並回傳正確的結束碼：0 成功、1 執行錯誤、2 用法錯誤（第 4 集）。

### 完整程式

```go,stdin=go\nis\nfun\ngo\nis\ngo
package main

import (
	"bufio"
	"cmp"
	"errors"
	"flag"
	"fmt"
	"io"
	"io/fs"
	"os"
	"path/filepath"
	"slices"
	"strings"
)

type counter struct {
	lines      int
	words      int
	freq       map[string]int
	ignoreCase bool
}

// add 讀完 r 的所有內容，累計行數、字數與每個字出現的次數。
func (c *counter) add(r io.Reader) error {
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		c.lines++
		for _, w := range strings.Fields(scanner.Text()) {
			w = strings.Trim(w, `.,!?;:"'()`)
			if w == "" {
				continue
			}
			if c.ignoreCase {
				w = strings.ToLower(w)
			}
			c.words++
			c.freq[w]++
		}
	}
	return scanner.Err()
}

func (c *counter) addFile(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return c.add(f)
}

// addPath 處理一個參數：檔案就直接讀，資料夾就走訪裡面副檔名符合的檔案。
func (c *counter) addPath(path, ext string) error {
	info, err := os.Stat(path)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return c.addFile(path)
	}
	return filepath.WalkDir(path, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() || filepath.Ext(p) != ext {
			return nil
		}
		return c.addFile(p)
	})
}

func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
	flags := flag.NewFlagSet("wordfreq", flag.ContinueOnError)
	flags.SetOutput(stderr)
	top := flags.Int("top", 3, "列出出現最多次的前幾個字")
	ignoreCase := flags.Bool("i", false, "不分大小寫")
	ext := flags.String("ext", ".txt", "走訪資料夾時要讀的副檔名")
	flags.Usage = func() {
		fmt.Fprintln(stderr, "用法：wordfreq [選項] [檔案或資料夾...]")
		fmt.Fprintln(stderr, "沒有給檔案時，從標準輸入讀取。")
		fmt.Fprintln(stderr)
		fmt.Fprintln(stderr, "選項：")
		flags.PrintDefaults()
	}
	if err := flags.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return 0
		}
		return 2
	}
	if *top < 1 {
		fmt.Fprintln(stderr, "wordfreq: -top 必須大於 0")
		return 2
	}

	c := &counter{freq: map[string]int{}, ignoreCase: *ignoreCase}
	if flags.NArg() == 0 {
		if err := c.add(stdin); err != nil {
			fmt.Fprintln(stderr, "wordfreq:", err)
			return 1
		}
	}
	for _, path := range flags.Args() {
		if err := c.addPath(path, *ext); err != nil {
			fmt.Fprintln(stderr, "wordfreq:", err)
			return 1
		}
	}

	words := make([]string, 0, len(c.freq))
	for w := range c.freq {
		words = append(words, w)
	}
	slices.SortFunc(words, func(a, b string) int {
		if n := cmp.Compare(c.freq[b], c.freq[a]); n != 0 {
			return n
		}
		return cmp.Compare(a, b)
	})

	fmt.Fprintf(stdout, "%d 行，%d 個字，%d 種不同的字\n", c.lines, c.words, len(c.freq))
	for _, w := range words[:min(*top, len(words))] {
		fmt.Fprintf(stdout, "%5d  %s\n", c.freq[w], w)
	}
	return 0
}

func main() {
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}
```

執行結果：

```text
6 行，6 個字，3 種不同的字
    3  go
    2  is
    1  fun
```

在書裡執行時沒有參數，所以它從 stdin 讀了 6 行、每行一個字。

### 程式怎麼組起來的

**`counter` 負責計算。** 它的 `add` 方法收一個 `io.Reader`（第 12 章），用 `for scanner.Scan()` 一行一行讀，再用 `strings.Fields` 切成字、`strings.Trim` 去掉前後的標點。因為參數是 `io.Reader`，不管資料來自 `os.Stdin` 還是 `os.Open` 打開的檔案，都是同一段程式碼。

**`addPath` 處理檔案和資料夾。** 先用 `os.Stat` 看參數是什麼：是檔案就直接讀；是資料夾就用 `filepath.WalkDir` 走訪，只讀副檔名符合 `-ext` 的檔案。`addFile` 裡的 `defer f.Close()` 確保每個檔案讀完都會關閉。

**`run` 是整支程式的主體。** 它不直接碰 `os.Args`、`os.Stdin`，而是把參數、輸入、輸出、錯誤輸出都當成參數收進來，並回傳結束碼：

- 用 `flag.NewFlagSet` 搭配 `flag.ContinueOnError`，解析失敗時不會直接結束，而是回傳錯誤讓我們決定結束碼。`-h` 會回傳特別的 `flag.ErrHelp`，這時算成功、回傳 0；其他解析錯誤回傳 2。
- `flags.SetOutput(stderr)` 讓 `flag` 自動產生的錯誤訊息也寫到我們給的 `stderr`。
- 計算完用第 6 章的 `slices.SortFunc` 排序：次數多的在前，次數一樣就照字母順序，這樣結果每次都一樣。

**`main` 只有一行。** `os.Exit(run(...))` 把真正的 `os.Args[1:]`、`os.Stdin`、`os.Stdout`、`os.Stderr` 交給 `run`。所有 `defer` 都在 `run` 和它呼叫的函式裡，`os.Exit` 不會跳過任何收尾。

這樣設計還有一個好處：`run` 可以在測試裡直接呼叫，給它一個 `strings.NewReader` 當輸入、`bytes.Buffer` 當輸出，不用真的打指令。

### 實際用用看

先編譯，再準備一個檔案和一個資料夾：

```bash
go build -o wordfreq .
printf 'The cat sat on the mat.\nThe dog sat too!\n' > poem.txt
mkdir -p notes/2026
printf 'Go is fun.\nGo is fast.\n' > notes/a.txt
printf 'go go GO\n' > notes/2026/b.txt
printf 'ignore me go\n' > notes/c.md
```

讀檔案，和用 `-i`、`-top` 調整：

```bash
./wordfreq poem.txt
./wordfreq -i -top 5 poem.txt
```

執行結果：

```text
2 行，10 個字，8 種不同的字
    2  The
    2  sat
    1  cat
2 行，10 個字，7 種不同的字
    3  the
    2  sat
    1  cat
    1  dog
    1  mat
```

不分大小寫之後，`The` 和 `the` 合併成 3 次。

讀整個資料夾（包含子資料夾，只讀 `.txt`），或接在管線後面：

```bash
./wordfreq -i notes
cat poem.txt notes/a.txt | ./wordfreq -top 1
```

執行結果：

```text
3 行，9 個字，4 種不同的字
    5  go
    2  is
    1  fast
4 行，16 個字，12 種不同的字
    2  Go
```

`notes/c.md` 不是 `.txt`，所以沒被算進去；改用 `-ext .md` 就只會讀它。

最後看看出錯的情況和結束碼：

```bash
./wordfreq nope.txt
echo $?
./wordfreq -top 0 poem.txt
echo $?
```

執行結果：

```text
wordfreq: stat nope.txt: no such file or directory
1
wordfreq: -top 必須大於 0
2
```

檔案不存在是執行錯誤，回傳 1；`-top 0` 是使用者給錯參數，回傳 2。

### 還可以加什麼

如果要處理很大的資料夾，可以加上第 7 集的 `signal.NotifyContext`，在走訪時檢查 context，讓 Ctrl+C 能乾淨地停下來。你也可以試著加一個 `-min` 選項，只統計長度至少幾個字元的字。

## 重點整理

- 把工作寫在 `run(args, stdin, stdout, stderr) int`，`main` 只做 `os.Exit(run(...))`，`defer` 就不會被跳過，也方便測試。
- 用 `flag.ContinueOnError` 自己決定結束碼：`flag.ErrHelp` 回傳 0，其他解析錯誤回傳 2。
- 讀取的函式收 `io.Reader`，同一段程式碼就能處理 stdin 和檔案。
- 沒給檔案時讀 stdin，工具就能放進管線；結果寫 stdout、錯誤寫 stderr。
