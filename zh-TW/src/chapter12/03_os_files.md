# `os` 檔案操作

## 本集目標

學會用 `os` 套件讀寫檔案：一次讀寫整個檔案的 `os.ReadFile`／`os.WriteFile`，以及開檔後慢慢讀寫的 `os.Create`／`os.Open`，並記得用 `defer` 關檔。

## 正文

### 先準備一個暫存目錄

練習寫檔時，我們不想在你的電腦裡留下一堆垃圾檔案。`os.MkdirTemp` 會在系統的暫存區建立一個名字不重複的新目錄，用完再用 `os.RemoveAll` 整個刪掉：

```go,ignore
dir, err := os.MkdirTemp("", "ch12-*")
if err != nil {
	fmt.Println("錯誤:", err)
	return
}
defer os.RemoveAll(dir)
```

第一個參數空字串表示「用系統預設的暫存區」，第二個參數裡的 `*` 會被換成一串亂數。本集所有範例都會先這樣做。目錄的實際位置每台電腦都不同，所以範例不會把它印出來。

路徑我們先用 `dir + "/hello.txt"` 這種方式組合，第 5 集會介紹更正式的 `filepath.Join`。

### 一次寫入、一次讀出

檔案不大的時候，最簡單的就是一次搞定：

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

	path := dir + "/hello.txt"
	err = os.WriteFile(path, []byte("你好，檔案！\n第二行\n"), 0o644)
	if err != nil {
		fmt.Println("寫入失敗:", err)
		return
	}

	data, err := os.ReadFile(path)
	if err != nil {
		fmt.Println("讀取失敗:", err)
		return
	}
	fmt.Print(string(data))
	fmt.Println("檔案大小:", len(data), "byte")
}
```

執行結果：

```text
你好，檔案！
第二行
檔案大小: 29 byte
```

- `os.WriteFile(路徑, 內容, 權限)`：檔案不存在就建立，已經存在就**整個覆蓋**。內容是 `[]byte`，字串要先轉換。
- `os.ReadFile(路徑)`：回傳整個檔案內容的 `[]byte` 和一個 `error`。

### 權限 `0o644` 是什麼

`0o644` 是附錄一介紹過的八進位數字，代表檔案建立時的權限（在 macOS、Linux 上才有意義，Windows 大致會忽略）。三個數字依序是「擁有者」「同群組」「其他人」，每個數字是讀（4）、寫（2）、執行（1）加起來：

| 數字 | 意思 |
| --- | --- |
| `6` = 4 + 2 | 可讀、可寫 |
| `4` | 只能讀 |
| `5` = 4 + 1 | 可讀、可執行（目錄常用） |

所以 `0o644` 就是「自己可讀寫，其他人只能讀」，一般檔案用它就對了；目錄則常用 `0o755`。

### 開檔、寫入、關檔

檔案很大，或要一點一點寫入時，就要先「開檔」拿到一個 `*os.File`。`*os.File` 同時是 `io.Reader` 和 `io.Writer`，前兩集學的工具全部用得上：

```go
package main

import (
	"bufio"
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
	path := dir + "/scores.txt"

	f, err := os.Create(path)
	if err != nil {
		fmt.Println("建立失敗:", err)
		return
	}
	for i := range 3 {
		fmt.Fprintf(f, "第 %d 位: %d 分\n", i+1, 80+i*5)
	}
	if err := f.Close(); err != nil {
		fmt.Println("關檔失敗:", err)
		return
	}

	f, err = os.Open(path)
	if err != nil {
		fmt.Println("開檔失敗:", err)
		return
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		fmt.Println("讀到 →", scanner.Text())
	}
}
```

執行結果：

```text
讀到 → 第 1 位: 80 分
讀到 → 第 2 位: 85 分
讀到 → 第 3 位: 90 分
```

- `os.Create`：建立檔案準備寫入（已存在就清空），權限是 `0o666` 再扣掉系統設定的遮罩，通常就是 `0o644`。
- `os.Open`：開啟檔案準備**讀取**，只能讀不能寫。
- 開了檔就一定要 `Close`。作業系統能同時開的檔案數量有限，而且寫入的資料可能要到關檔時才真正落地。

讀檔時，開檔成功後立刻 `defer f.Close()` 是標準寫法。寫檔時則建議像上面一樣**自己呼叫 `Close` 並檢查錯誤**：磁碟滿了之類的寫入錯誤，有時要到關檔那一刻才會回報，用 `defer` 就會把它默默丟掉。

### 檔案不存在

開一個不存在的檔案會得到錯誤。要判斷是不是「不存在」，用第 5 章的 `errors.Is` 搭配 `os.ErrNotExist`：

```go
package main

import (
	"errors"
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

	_, err = os.ReadFile(dir + "/nothing.txt")
	if errors.Is(err, os.ErrNotExist) {
		fmt.Println("檔案不存在，改用預設設定")
	} else if err != nil {
		fmt.Println("其他錯誤:", err)
	}
}
```

執行結果：

```text
檔案不存在，改用預設設定
```

### 附加到檔案後面

`os.WriteFile` 和 `os.Create` 都會覆蓋舊內容。想在檔案後面繼續加，用 `os.OpenFile` 並指定旗標：

```go,ignore
f, err := os.OpenFile(path, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
```

`O_APPEND` 是「寫在最後面」，`O_CREATE` 是「不存在就建立」，`O_WRONLY` 是「只寫」，用 `|` 組合起來。寫日誌檔時常用這個寫法。

## 重點整理

- `os.WriteFile`／`os.ReadFile` 一次寫入或讀出整個檔案，適合小檔案。
- `os.Create` 建立檔案來寫、`os.Open` 開啟檔案來讀，得到的 `*os.File` 同時是 `io.Reader` 和 `io.Writer`。
- 開檔後一定要 `Close`；讀檔用 `defer f.Close()`，寫檔最好自己檢查 `Close` 的錯誤。
- `0o644` 表示自己可讀寫、其他人只能讀；用 `errors.Is(err, os.ErrNotExist)` 判斷檔案不存在。
- `os.MkdirTemp` 建立暫存目錄，`os.RemoveAll` 清掉整個目錄。
