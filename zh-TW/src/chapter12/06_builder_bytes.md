# `strings.Builder` 與 `bytes`

## 本集目標

用 `strings.Builder` 有效率地組出長字串，認識既能讀又能寫的 `bytes.Buffer`，以及和 `strings` 長得幾乎一樣的 `bytes` 套件。

## 正文

### 為什麼不要在迴圈裡一直用 `+`

Go 的字串不能修改。每次寫 `s += "x"`，其實是建立一個新字串，把舊的內容整個複製過去再加上 `"x"`。迴圈跑一萬次，就複製了一萬次越來越長的字串，很浪費。

`strings.Builder` 內部用一個會自動長大的 `[]byte` 存放內容，一直往後加，最後才一次變成字串。第 4 章已經把它當 `io.Writer` 用過，這集看看它自己的方法：

```go
package main

import (
	"fmt"
	"strings"
)

func main() {
	var sb strings.Builder
	for i := range 5 {
		if i > 0 {
			sb.WriteString(", ")
		}
		fmt.Fprintf(&sb, "%d", i*i)
	}
	sb.WriteByte('!')
	sb.WriteRune('✓')

	fmt.Println(sb.String())
	fmt.Println("長度:", sb.Len(), "byte")

	sb.Reset()
	sb.WriteString("重新開始")
	fmt.Println(sb.String())
}
```

執行結果：

```text
0, 1, 4, 9, 16!✓
長度: 18 byte
重新開始
```

- `WriteString` 加字串、`WriteByte` 加一個 byte、`WriteRune` 加一個字元（會轉成 UTF-8）。
- `Len` 是目前的 byte 數，`✓` 在 UTF-8 裡占 3 個 byte。
- `Reset` 清空，可以重複使用。
- `strings.Builder` 的零值就能直接用（第 3 章「讓零值有用」），但不要複製一個已經寫過東西的 Builder，要傳的話傳指標。

如果只是要把切片裡的字串用分隔符號接起來，第 2 章的 `strings.Join` 更省事，它內部用的就是 Builder。

### `bytes.Buffer`：又能寫又能讀

`bytes.Buffer` 也是一塊會長大的 byte 緩衝區，和 Builder 的差別是：它**同時是 `io.Writer` 和 `io.Reader`**，寫進去的東西可以再從前面讀出來：

```go
package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
)

func main() {
	var buf bytes.Buffer
	buf.WriteString("第一行\n")
	fmt.Fprintf(&buf, "第%s行\n", "二")
	buf.Write([]byte("第三行\n"))

	line, err := buf.ReadString('\n')
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Printf("先讀出一行: %q\n", line)
	fmt.Println("緩衝區還剩", buf.Len(), "byte")

	io.Copy(os.Stdout, &buf)
	fmt.Println("讀完後剩", buf.Len(), "byte")
}
```

執行結果：

```text
先讀出一行: "第一行\n"
緩衝區還剩 20 byte
第二行
第三行
讀完後剩 0 byte
```

- `ReadString('\n')` 讀到第一個換行為止（包含換行）。讀出來的部分就從緩衝區移走了。
- `&buf` 是 `io.Reader`，可以交給 `io.Copy`；剩下的兩行全部被搬到螢幕，緩衝區就空了。
- `buf.Bytes()` 和 `buf.String()` 可以拿到還沒讀走的內容。

什麼時候用哪個？只是要組字串，用 `strings.Builder`；需要一個「先寫進去、再當 Reader 交給別人」的暫存區，例如準備要傳給網路請求的內容，用 `bytes.Buffer`。

### `bytes` 套件：處理 `[]byte` 的 `strings`

讀檔、網路傳輸拿到的資料常常是 `[]byte`。`bytes` 套件提供了和第 2 章 `strings` 幾乎同名、同用法的函式，差別只在參數和回傳值是 `[]byte`：

```go
package main

import (
	"bytes"
	"fmt"
)

func main() {
	data := []byte("name=Andy;city=Taipei;lang=Go")

	fmt.Println(bytes.Contains(data, []byte("city")))
	fmt.Println(bytes.Index(data, []byte(";")))
	fmt.Printf("%s\n", bytes.ToUpper(data))

	for _, part := range bytes.Split(data, []byte(";")) {
		key, value, found := bytes.Cut(part, []byte("="))
		if found {
			fmt.Printf("%s → %s\n", key, value)
		}
	}

	a := []byte("go")
	b := []byte("go")
	fmt.Println(bytes.Equal(a, b))
}
```

執行結果：

```text
true
9
NAME=ANDY;CITY=TAIPEI;LANG=GO
name → Andy
city → Taipei
lang → Go
true
```

- `%s` 可以直接印出 `[]byte` 的文字內容。
- 切片不能用 `==` 比較，比較兩個 `[]byte` 的內容要用 `bytes.Equal`。
- 資料本來就是 `[]byte` 時，直接用 `bytes` 套件，就不必來回轉成 `string`，省下複製的成本。

Go 1.27 還在 `strings` 和 `bytes` 都加了 `CutLast`，和 `Cut` 一樣，只是從**最後一個**分隔符號切開。

## 重點整理

- 迴圈裡組長字串用 `strings.Builder`：`WriteString`、`WriteByte`、`WriteRune`，最後 `String()`。
- `bytes.Buffer` 同時是 `io.Writer` 和 `io.Reader`，寫進去的內容可以再讀出來。
- `bytes` 套件提供和 `strings` 對應的函式（`Contains`、`Split`、`Cut`、`ToUpper` 等），直接處理 `[]byte`。
- 比較兩個 `[]byte` 用 `bytes.Equal`。
