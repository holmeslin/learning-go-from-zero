# `io.Reader` 與 `io.Writer`

## 本集目標

認識 Go 讀寫資料的兩個核心介面 `io.Reader` 與 `io.Writer`，並用 `io.Copy` 把資料從一個地方搬到另一個地方。

## 正文

第 4 章已經用過 `io.Writer`：`fmt.Fprintln` 可以寫到螢幕，也可以寫進 `strings.Builder`。這集補上它的另一半 `io.Reader`，兩個合起來，就是 Go 處理「資料流」的基本功。

### `io.Reader`：可以讀出 byte 的東西

```go,ignore
type Reader interface {
	Read(p []byte) (n int, err error)
}
```

`Read` 的規則是：呼叫的人先準備好一個切片 `p`，`Read` 把資料填進去，回傳這次填了幾個 byte（`n`）。資料讀完時，回傳的錯誤是 `io.EOF`（End Of File，「讀到底了」的意思），這是第 5 章介紹過的哨兵錯誤。

`strings.NewReader` 可以把一個字串包裝成 `io.Reader`，很適合拿來練習：

```go
package main

import (
	"fmt"
	"io"
	"strings"
)

func main() {
	r := strings.NewReader("Hello, Go!")
	buf := make([]byte, 4)
	for {
		n, err := r.Read(buf)
		if n > 0 {
			fmt.Printf("讀到 %d 個 byte：%q\n", n, buf[:n])
		}
		if err == io.EOF {
			fmt.Println("讀完了")
			break
		}
		if err != nil {
			fmt.Println("錯誤:", err)
			return
		}
	}
}
```

執行結果：

```text
讀到 4 個 byte："Hell"
讀到 4 個 byte："o, G"
讀到 2 個 byte："o!"
讀完了
```

`buf` 只有 4 個 byte，所以每次最多讀 4 個，要讀好幾次才讀得完。最後一次只剩 2 個 byte，`n` 就是 2。注意要**先處理 `n` 再看 `err`**，因為有些 Reader 會在同一次呼叫裡同時給你最後一點資料和 `io.EOF`。

### 很多東西都是 Reader 和 Writer

這兩個介面都只有一個方法，所以標準庫裡到處都是它們：

| 型別 | Reader | Writer |
| --- | --- | --- |
| `os.Stdin`（鍵盤輸入） | ✓ | |
| `os.Stdout`（螢幕輸出） | | ✓ |
| `*os.File`（檔案，第 3 集） | ✓ | ✓ |
| `*strings.Reader` | ✓ | |
| `*strings.Builder` | | ✓ |
| `*bytes.Buffer`（第 6 集） | ✓ | ✓ |

之後的網路連線、HTTP 請求內容、壓縮檔，也都是 Reader 或 Writer。只要寫一次接收 `io.Reader` 的函式，就能處理所有這些來源。

### `io.Copy`：從 Reader 搬到 Writer

自己寫讀取迴圈有點麻煩。大部分時候我們只是想「把這裡的資料全部搬到那裡」，`io.Copy` 就是做這件事：

```go
package main

import (
	"fmt"
	"io"
	"os"
	"strings"
)

func main() {
	r := strings.NewReader("第一行\n第二行\n")
	n, err := io.Copy(os.Stdout, r)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println("總共複製了", n, "個 byte")
}
```

執行結果：

```text
第一行
第二行
總共複製了 20 個 byte
```

`io.Copy(dst, src)` 的順序是「目的地在前、來源在後」，和第 2 章的 `copy(dst, src)` 一樣。它會一直讀到 `io.EOF` 為止，所以讀完不算錯誤，`err` 是 `nil`。回傳的 `n` 是 `int64`，中文每個字在 UTF-8 裡占 3 個 byte，6 個字加 2 個換行，總共 20 個 byte。

如果想把全部內容讀進一個 `[]byte`，可以用 `io.ReadAll(r)`，用法和 `io.Copy` 類似，第 3 集讀檔時會看到相近的寫法。

### 自己做一個 Writer

只要有 `Write` 方法就是 `io.Writer`。我們來做一個「把寫進來的英文字母轉大寫，再交給另一個 Writer」的型別：

```go
package main

import (
	"fmt"
	"io"
	"os"
	"strings"
)

type upperWriter struct {
	w io.Writer
}

func (u upperWriter) Write(p []byte) (int, error) {
	upper := strings.ToUpper(string(p))
	_, err := io.WriteString(u.w, upper)
	if err != nil {
		return 0, err
	}
	return len(p), nil
}

func main() {
	out := upperWriter{w: os.Stdout}
	fmt.Fprintln(out, "hello, writer")
	io.Copy(out, strings.NewReader("go is fun\n"))
}
```

執行結果：

```text
HELLO, WRITER
GO IS FUN
```

- `Write` 回傳的 `n` 要代表「收下了幾個 byte」，所以回傳 `len(p)`，而不是轉換後的長度。
- `io.WriteString(w, s)` 可以把字串直接寫進任何 Writer。
- `upperWriter` 裡面又包了一個 Writer，這種「包一層、加一點功能」的寫法在 Go 很常見，下一集的 `bufio` 就是這樣做的。

## 重點整理

- `io.Reader` 只有 `Read(p []byte) (n int, err error)`；讀完時回傳 `io.EOF`，要先處理 `n` 再看 `err`。
- `io.Writer` 只有 `Write(p []byte) (n int, err error)`；`os.Stdout`、檔案、`strings.Builder` 都是 Writer。
- `strings.NewReader` 把字串變成 Reader；`io.Copy(dst, src)` 把 Reader 的內容全部搬到 Writer。
- 自己的型別只要實作 `Write`（或 `Read`），就能和標準庫所有的 Reader／Writer 工具搭配。
