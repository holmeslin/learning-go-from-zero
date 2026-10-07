# 走訪目錄

## 本集目標

會用 `filepath.WalkDir` 走過一個資料夾裡所有的檔案和子資料夾，並知道怎麼跳過不想進去的資料夾。

## 正文

### 為什麼需要走訪

很多 CLI 工具都要處理「這個資料夾底下的所有檔案」：`go vet ./...` 檢查所有套件、`grep -r` 搜尋所有檔案。資料夾裡有資料夾，裡面又有資料夾，層數不固定，自己寫會很麻煩。`path/filepath` 套件的 `WalkDir` 幫我們一層一層走下去，每遇到一個檔案或資料夾就呼叫一次我們給的函式。

### 先準備一個資料夾

為了讓範例每次結果都一樣，我們先在暫存資料夾裡建一個小專案。底下的 `makeDemo` 只是用第 12 章學過的 `os.MkdirAll` 和 `os.WriteFile` 建立檔案，重點在 `main`：

```go
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func makeDemo() (string, error) {
	root, err := os.MkdirTemp("", "walkdemo")
	if err != nil {
		return "", err
	}
	files := map[string]string{
		"main.go":         "package main\n",
		"README.md":       "# demo\n",
		"util/strings.go": "package util\n",
		"util/notes.txt":  "記得寫測試\n",
		".git/config":     "[core]\n",
	}
	for name, content := range files {
		path := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return "", err
		}
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			return "", err
		}
	}
	return root, nil
}

func main() {
	root, err := makeDemo()
	if err != nil {
		fmt.Println(err)
		return
	}
	defer os.RemoveAll(root)

	err = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		rel, _ := filepath.Rel(root, path)
		if d.IsDir() {
			fmt.Println("資料夾：", rel)
		} else {
			fmt.Println("檔案：  ", rel)
		}
		return nil
	})
	if err != nil {
		fmt.Println(err)
	}
}
```

執行結果：

```text
資料夾： .
資料夾： .git
檔案：   .git/config
檔案：   README.md
檔案：   main.go
資料夾： util
檔案：   util/notes.txt
檔案：   util/strings.go
```

### 一步一步看

`filepath.WalkDir(root, fn)` 從 `root` 開始，對每一個項目（包含 `root` 自己）呼叫一次 `fn`。`fn` 收三個參數：

- `path`：這個項目的完整路徑。我們用 `filepath.Rel` 把它變成相對於 `root` 的路徑，印起來比較短，`root` 自己就變成 `.`。
- `d`：一個 `fs.DirEntry`，可以問它 `d.IsDir()`（是不是資料夾）、`d.Name()`（名稱）。
- `err`：走到這裡時發生的錯誤，例如沒有權限讀取某個資料夾。

`fn` 回傳的 `error` 決定接下來怎麼走：回傳 `nil` 就繼續；回傳錯誤就整個停下來，而且 `WalkDir` 會把這個錯誤回傳給你。上面一開始的 `if err != nil { return err }`，意思就是「遇到問題就停止」。

另外注意順序：同一層裡的項目是依名稱排序的，而且會先走完一個資料夾的內容，再往下一個項目走。

### 跳過資料夾：`filepath.SkipDir`

`.git` 這種資料夾通常不想進去。在 `fn` 裡回傳特別的值 `filepath.SkipDir`，就會跳過整個資料夾。這次我們只算 `.go` 檔：

```go
package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

func makeDemo() (string, error) {
	root, err := os.MkdirTemp("", "walkdemo")
	if err != nil {
		return "", err
	}
	files := map[string]string{
		"main.go":         "package main\n",
		"README.md":       "# demo\n",
		"util/strings.go": "package util\n",
		"util/notes.txt":  "記得寫測試\n",
		".git/config":     "[core]\n",
		".git/hook.go":    "package hook\n",
	}
	for name, content := range files {
		path := filepath.Join(root, name)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return "", err
		}
		if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
			return "", err
		}
	}
	return root, nil
}

func main() {
	root, err := makeDemo()
	if err != nil {
		fmt.Println(err)
		return
	}
	defer os.RemoveAll(root)

	var goFiles []string
	err = filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() && d.Name() == ".git" {
			return filepath.SkipDir
		}
		if !d.IsDir() && filepath.Ext(path) == ".go" {
			rel, _ := filepath.Rel(root, path)
			goFiles = append(goFiles, rel)
		}
		return nil
	})
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println("找到", len(goFiles), "個 Go 檔：", goFiles)
}
```

執行結果：

```text
找到 2 個 Go 檔： [main.go util/strings.go]
```

`.git` 裡面雖然也有一個 `hook.go`，但整個資料夾被跳過了，所以只找到兩個。`filepath.SkipDir` 是一個哨兵錯誤（第 5 章），`WalkDir` 看到它就知道「不是真的出錯，只是要跳過」。

### 想知道檔案大小

`fs.DirEntry` 只帶著名稱和型別這些便宜的資訊。需要大小或修改時間時，再呼叫 `d.Info()`，它回傳 `fs.FileInfo` 和 `error`，裡面有 `Size()`、`ModTime()` 等方法。只在需要時才查，正是 `WalkDir` 比較快的原因。

## 重點整理

- `filepath.WalkDir(root, fn)` 走過 `root` 底下所有的檔案和資料夾（包含 `root` 自己），每個項目呼叫一次 `fn`。
- `fn` 收到路徑、`fs.DirEntry`、錯誤；記得先處理 `err` 參數。
- `fn` 回傳 `nil` 繼續、回傳錯誤停止、回傳 `filepath.SkipDir` 跳過這個資料夾。
- 同一層的項目依名稱排序；需要大小等詳細資訊時呼叫 `d.Info()`。
