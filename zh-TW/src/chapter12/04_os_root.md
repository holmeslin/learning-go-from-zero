# `os.Root`

## 本集目標

知道什麼是「路徑穿越」攻擊，並用 Go 1.24 加入的 `os.Root` 把檔案操作限制在某個目錄裡面。

## 正文

### 問題：使用者給的檔名不能信任

假設你寫了一個程式，讓使用者輸入檔名，程式從 `uploads` 目錄裡讀出那個檔案：

```go,ignore
data, err := os.ReadFile("uploads/" + name)
```

使用者乖乖輸入 `cat.jpg` 時沒問題。可是如果他輸入 `../../etc/passwd` 呢？`..` 代表「上一層目錄」，組起來的路徑就跳出了 `uploads`，跑去讀系統裡別的檔案。這叫做**路徑穿越**（path traversal），是很常見的安全漏洞。

自己檢查字串裡有沒有 `..` 很容易漏掉狀況，例如絕對路徑、符號連結（symbolic link，類似捷徑）。Go 1.24 起，標準庫提供了 `os.Root` 幫你處理。

### `os.OpenRoot`：把操作關在一個目錄裡

`os.OpenRoot(目錄)` 回傳一個 `*os.Root`。之後透過它做的所有檔案操作，路徑都以那個目錄為起點，而且**不能離開它**：

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	dir, err := os.MkdirTemp("", "ch12-*")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer os.RemoveAll(dir)

	root, err := os.OpenRoot(dir)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer root.Close()

	err = root.WriteFile("cat.txt", []byte("喵"), 0o644)
	if err != nil {
		fmt.Println("寫入失敗:", err)
		return
	}

	for _, name := range []string{"cat.txt", "../secret.txt", "/etc/passwd"} {
		data, err := root.ReadFile(name)
		if err != nil {
			fmt.Println(name, "→ 失敗:", err)
			continue
		}
		fmt.Println(name, "→", string(data))
	}
}
```

執行結果：

```text
cat.txt → 喵
../secret.txt → 失敗: openat ../secret.txt: path escapes from parent
/etc/passwd → 失敗: openat /etc/passwd: path escapes from parent
```

- `cat.txt` 在目錄裡面，正常讀到。
- `../secret.txt` 想往上跳，`/etc/passwd` 是絕對路徑，都會得到 `path escapes from parent`（路徑逃出了上層）的錯誤，根本不會去碰目錄外的檔案。
- `*os.Root` 用完要 `Close`，和檔案一樣。

`os.Root` 的方法名稱和 `os` 套件的函式幾乎一一對應：`root.Open`、`root.Create`、`root.OpenFile`、`root.Mkdir`、`root.Remove`、`root.Stat` 是 Go 1.24 就有的；`root.ReadFile`、`root.WriteFile`、`root.MkdirAll`、`root.RemoveAll`、`root.Rename` 等則是 Go 1.25 加入的。用 `go doc os.Root` 可以看到完整清單。

### 目錄裡面怎麼走都可以

限制的是「最後不能跑出去」，在裡面用子目錄、甚至用 `..` 繞一圈再回來都沒關係：

```go
package main

import (
	"fmt"
	"os"
)

func main() {
	dir, err := os.MkdirTemp("", "ch12-*")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer os.RemoveAll(dir)

	root, err := os.OpenRoot(dir)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	defer root.Close()

	if err := root.MkdirAll("logs/2026", 0o755); err != nil {
		fmt.Println("建立目錄失敗:", err)
		return
	}
	if err := root.WriteFile("logs/2026/app.log", []byte("啟動成功"), 0o644); err != nil {
		fmt.Println("寫入失敗:", err)
		return
	}

	data, err := root.ReadFile("logs/../logs/2026/app.log")
	if err != nil {
		fmt.Println("讀取失敗:", err)
		return
	}
	fmt.Println(string(data))
}
```

執行結果：

```text
啟動成功
```

### 只開一個檔案：`os.OpenInRoot`

如果只是要在某個目錄裡安全地開一個檔案，不想另外管理 `*os.Root`，可以用 `os.OpenInRoot(目錄, 檔名)`，它等於先 `OpenRoot` 再 `Open`：

```go,ignore
f, err := os.OpenInRoot("uploads", name)
```

### 什麼時候該用

只要檔名有任何一部分來自外部（使用者輸入、網路請求、設定檔、壓縮檔裡的檔名），就應該用 `os.Root`。第 14 章寫 Web 服務時，這會特別重要。

另外，`root.FS()` 可以把它變成下一集要介紹的 `fs.FS`。

## 重點整理

- 路徑穿越：用 `..` 或絕對路徑讓程式存取到原本不該碰的檔案。
- `os.OpenRoot(dir)` 回傳 `*os.Root`，透過它的檔案操作都不能離開 `dir`，逃出去會得到錯誤。
- `os.Root` 的方法和 `os` 的函式對應；Go 1.25 起多了 `ReadFile`、`WriteFile`、`MkdirAll` 等。
- 只開一個檔案可以用 `os.OpenInRoot`；檔名來自外部時就該用這些 API。
