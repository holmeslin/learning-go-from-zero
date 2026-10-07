# `path/filepath` 與 `io/fs`

## 本集目標

用 `path/filepath` 正確地組合與拆解路徑，用 `WalkDir` 走訪整個目錄，並認識代表「一整個檔案系統」的介面 `fs.FS`。

## 正文

### 組合路徑：`filepath.Join`

上兩集我們用 `dir + "/hello.txt"` 組路徑。這樣寫有兩個問題：Windows 的路徑分隔符號是 `\` 而不是 `/`；而且字串相加很容易多一個或少一個斜線。`filepath.Join` 會依照目前的作業系統，幫你用正確的分隔符號組起來，並順便整理多餘的部分。下面是在 macOS、Linux 上執行的結果：

```go
package main

import (
	"fmt"
	"path/filepath"
)

func main() {
	fmt.Println(filepath.Join("docs", "2026", "report.txt"))
	fmt.Println(filepath.Join("docs/", "/2026", "report.txt"))
	fmt.Println(filepath.Join("docs", "old", "..", "report.txt"))
}
```

執行結果：

```text
docs/2026/report.txt
docs/2026/report.txt
docs/report.txt
```

在 Windows 上，斜線會變成 `\`（下面走訪目錄的範例也一樣），例如 `docs\2026\report.txt`。從現在開始，組路徑一律用 `filepath.Join`。

### 拆解路徑：`Base`、`Dir`、`Ext`

```go
package main

import (
	"fmt"
	"path/filepath"
	"strings"
)

func main() {
	p := filepath.Join("photos", "2026", "cat.final.jpg")
	fmt.Println("Base:", filepath.Base(p))
	fmt.Println("Dir: ", filepath.Dir(p))
	fmt.Println("Ext: ", filepath.Ext(p))

	name := strings.TrimSuffix(filepath.Base(p), filepath.Ext(p))
	fmt.Println("不含副檔名:", name)
}
```

執行結果：

```text
Base: cat.final.jpg
Dir:  photos/2026
Ext:  .jpg
不含副檔名: cat.final
```

- `Base`：最後一段，通常就是檔名。
- `Dir`：去掉最後一段之後剩下的目錄。
- `Ext`：副檔名，從**最後一個** `.` 開始算，包含那個點。

另外有個名字很像的套件 `path`，它永遠用 `/`，是給網址這類「不是作業系統檔案路徑」的東西用的。處理檔案時用 `path/filepath`。

### 走訪目錄：`filepath.WalkDir`

`filepath.WalkDir(起點, 函式)` 會把起點底下所有的檔案和目錄一個一個交給你的函式，順序是依名稱排序，先走完一個子目錄再換下一個：

```go
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func main() {
	dir, err := os.MkdirTemp("", "ch12-*")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer os.RemoveAll(dir)

	os.MkdirAll(filepath.Join(dir, "src", "util"), 0o755)
	os.WriteFile(filepath.Join(dir, "README.md"), []byte("說明"), 0o644)
	os.WriteFile(filepath.Join(dir, "src", "main.go"), []byte("package main"), 0o644)
	os.WriteFile(filepath.Join(dir, "src", "util", "math.go"), []byte("package util"), 0o644)

	err = filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(dir, path)
		if err != nil {
			return err
		}
		if d.IsDir() {
			fmt.Println("[目錄]", rel)
		} else {
			fmt.Println("[檔案]", rel)
		}
		return nil
	})
	if err != nil {
		fmt.Println("走訪失敗:", err)
	}
}
```

執行結果：

```text
[目錄] .
[檔案] README.md
[目錄] src
[檔案] src/main.go
[目錄] src/util
[檔案] src/util/math.go
```

一步一步看：

- 傳給 `WalkDir` 的是一個函式（第 6 章的函式當參數），每遇到一個項目就呼叫一次。
- `path` 是完整路徑，會包含暫存目錄的位置，所以我們用 `filepath.Rel(dir, path)` 算出相對於 `dir` 的路徑再印出。起點本身的相對路徑是 `.`。
- `d` 的型別是 `fs.DirEntry`，`d.IsDir()` 判斷是不是目錄，`d.Name()` 拿到名稱。
- 函式回傳 `nil` 表示繼續；回傳錯誤就停止走訪，這個錯誤會變成 `WalkDir` 的回傳值。如果在某個目錄回傳 `filepath.SkipDir`，就會跳過那整個目錄。

為了讓範例短一點，建立檔案時沒有檢查錯誤，實際寫程式時要檢查。第 13 章寫 CLI 工具時還會再用到走訪目錄。

### `io/fs`：檔案系統也是介面

`io/fs` 套件定義了 `fs.FS` 介面，代表「一個唯讀的檔案系統」。它只有一個方法：

```go,ignore
type FS interface {
	Open(name string) (fs.File, error)
}
```

第 11 章 `//go:embed` 用的 `embed.FS` 就是一種 `fs.FS`。真實的目錄可以用 `os.DirFS(目錄)` 變成 `fs.FS`，上一集的 `root.FS()` 也可以。

針對 `fs.FS` 的工具函式都在 `io/fs` 裡，例如 `fs.ReadFile` 和 `fs.WalkDir`：

```go
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func countFiles(fsys fs.FS) (int, error) {
	count := 0
	err := fs.WalkDir(fsys, ".", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			fmt.Println("找到", path)
			count++
		}
		return nil
	})
	return count, err
}

func main() {
	dir, err := os.MkdirTemp("", "ch12-*")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer os.RemoveAll(dir)

	os.MkdirAll(filepath.Join(dir, "notes"), 0o755)
	os.WriteFile(filepath.Join(dir, "a.txt"), []byte("AAA"), 0o644)
	os.WriteFile(filepath.Join(dir, "notes", "b.txt"), []byte("BBB"), 0o644)

	fsys := os.DirFS(dir)
	n, err := countFiles(fsys)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println("共", n, "個檔案")

	data, err := fs.ReadFile(fsys, "notes/b.txt")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println("notes/b.txt 的內容:", string(data))
}
```

執行結果：

```text
找到 a.txt
找到 notes/b.txt
共 2 個檔案
notes/b.txt 的內容: BBB
```

注意兩點：

- `fs.FS` 裡的路徑**一律用 `/`**，而且是相對於那個檔案系統的根，起點寫 `"."`。所以印出來的路徑不含暫存目錄，在 Windows 上也一樣。
- `countFiles` 只要求 `fs.FS`。同一個函式可以拿來數真實目錄、`embed.FS` 嵌入的檔案，測試時也能換成假的檔案系統（標準庫的 `testing/fstest.MapFS`）。這就是第 4 章「參數只要求真正用到的介面」的好處。

## 重點整理

- 組路徑用 `filepath.Join`，它會用作業系統正確的分隔符號並整理多餘的 `/`、`..`。
- `filepath.Base`、`Dir`、`Ext` 拆出檔名、目錄、副檔名；`filepath.Rel` 算出相對路徑。
- `filepath.WalkDir` 依名稱順序走訪整個目錄樹，回呼函式回傳錯誤會停止，回傳 `filepath.SkipDir` 跳過目錄。
- `fs.FS` 是唯讀檔案系統的介面，路徑一律用 `/`；`os.DirFS`、`embed.FS`、`root.FS()` 都是 `fs.FS`，搭配 `fs.ReadFile`、`fs.WalkDir` 使用。
