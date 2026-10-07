# `encoding/json/v2`

## 本集目標

認識 Go 1.27 正式加入的 `encoding/json/v2`：它和舊版用法幾乎一樣，但預設行為更嚴格、更安全；並簡單看看底層的 `encoding/json/jsontext` 套件。

## 正文

### 為什麼要有 v2

`encoding/json` 已經用了十幾年，累積了一些當初設計上的問題：解碼時欄位名稱不分大小寫、JSON 裡出現重複的鍵也照收、遇到不合法的 UTF-8 偷偷換成 `�`。這些「寬鬆」在一般情況下沒事，但不同系統對同一份 JSON 解讀不一致時，就可能變成安全漏洞。

為了不弄壞既有的程式，Go 沒有直接改舊套件的行為，而是另外推出 `encoding/json/v2`。它在 Go 1.25 以實驗功能的身分出現，**Go 1.27 起正式可用**，不需要任何額外設定。

### 匯入與基本用法

v2 的套件名稱也叫 `json`，用法和 v1 幾乎一樣：

```go
package main

import (
	"encoding/json/v2"
	"fmt"
)

type User struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

func main() {
	data, err := json.Marshal(User{Name: "Andy", Age: 30})
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))

	var u User
	if err := json.Unmarshal([]byte(`{"name":"Betty","age":25}`), &u); err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Printf("%+v\n", u)
}
```

執行結果：

```text
{"name":"Andy","age":30}
{Name:Betty Age:25}
```

`Marshal` 和 `Unmarshal` 的呼叫方式完全相同，tag 的寫法也一樣。差別在於 v2 的函式最後可以多傳幾個**選項**（`Options`）調整行為，等一下會看到。

如果同一個檔案需要同時用到 v1 和 v2，因為兩個套件都叫 `json`，要用第 8 章的 `import` 別名，例如把舊的取名為 `jsonv1`。

### 差異一：編碼結果

下面把同一個值分別交給 v1 和 v2 編碼：

```go
package main

import (
	jsonv1 "encoding/json"
	"encoding/json/v2"
	"fmt"
)

type Item struct {
	Name  string         `json:"name"`
	Tags  []string       `json:"tags"`
	Attrs map[string]int `json:"attrs"`
	Count int            `json:"count,omitempty"`
	Stock int            `json:"stock,omitzero"`
}

func main() {
	it := Item{Name: "<盒子>"}

	v1, err := jsonv1.Marshal(it)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	v2, err := json.Marshal(it)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println("v1:", string(v1))
	fmt.Println("v2:", string(v2))
}
```

執行結果：

```text
v1: {"name":"\u003c盒子\u003e","tags":null,"attrs":null}
v2: {"name":"<盒子>","tags":[],"attrs":{},"count":0}
```

逐項比較：

- **nil 切片和 nil map**：v1 編成 `null`，v2 編成 `[]` 和 `{}`。接收端通常期待拿到陣列或物件，`null` 常常害對方程式出錯，v2 的結果比較友善。
- **`omitempty` 的意思變了**：v2 的 `omitempty` 是「編碼出來是空的 JSON 值（`null`、`""`、`{}`、`[]`）就省略」。`0` 不是空的 JSON 值，所以 `count` 在 v2 不會被省略。要省略數字 `0` 或 `false`，請改用 `omitzero`，它在 v1 和 v2 的意思都一樣，是最保險的寫法。
- **HTML 字元**：v1 會把 `<`、`>` 轉成 `<` 這種跳脫寫法，v2 只在 JSON 文法真的需要時才跳脫，輸出比較乾淨。

### 差異二：解碼更嚴格

```go
package main

import (
	jsonv1 "encoding/json"
	"encoding/json/v2"
	"fmt"
)

type User struct {
	Name string `json:"name"`
}

func main() {
	inputs := []string{
		`{"name":"Andy","name":"Admin"}`,
		"{\"name\":\"\xff\"}",
		`{"NAME":"Cindy"}`,
	}
	for _, in := range inputs {
		var a, b User
		errA := jsonv1.Unmarshal([]byte(in), &a)
		errB := json.Unmarshal([]byte(in), &b)
		fmt.Printf("v1: %q, 錯誤: %v\n", a.Name, errA)
		fmt.Printf("v2: %q, 錯誤: %v\n", b.Name, errB)
	}
}
```

執行結果：

```text
v1: "Admin", 錯誤: <nil>
v2: "Andy", 錯誤: jsontext: duplicate object member name "name"
v1: "�", 錯誤: <nil>
v2: "", 錯誤: jsontext: invalid UTF-8 within "/name" after offset 9
v1: "Cindy", 錯誤: <nil>
v2: "", 錯誤: <nil>
```

- **重複的鍵**：v1 默默用最後一個值，於是名字變成 `Admin`；v2 直接回報錯誤。想像一個系統檢查時看第一個 `name`、另一個系統執行時看最後一個，這種不一致正是攻擊者想利用的。注意 v2 的 `b.Name` 是 `Andy`：出錯之前已經填進去的欄位會留著，所以 `Unmarshal` 回傳錯誤時，不要使用解到一半的結果。
- **不合法的 UTF-8**：程式裡的 `\xff` 不是合法的 UTF-8。v1 把它換成 `�`（也就是 `�`）照樣接受；v2 拒絕。
- **大小寫**：v1 比對欄位名稱時不分大小寫，`NAME` 也能填進 `name`；v2 要求大小寫完全相同。

這些嚴格的預設值都可以用選項放寬，例如 `jsontext.AllowDuplicateNames(true)`、`jsontext.AllowInvalidUTF8(true)`、`json.MatchCaseInsensitiveNames(true)`，但除非真的需要，維持預設比較安全。

另外，`time.Duration` 在 v1 會被編成奈秒數字，v2 則因為「沒有公認的表示方式」直接回報錯誤，需要你自己決定格式。

### 用選項調整行為

v2 沒有 `MarshalIndent`，排版改用選項。另一個一定要知道的選項是 `json.Deterministic`：**v2 編碼 map 時，鍵的順序不固定**（v1 會排序），需要固定順序時要明確要求：

```go
package main

import (
	"encoding/json/jsontext"
	"encoding/json/v2"
	"fmt"
)

type Config struct {
	Port int `json:"port"`
}

func main() {
	scores := map[string]int{"carol": 72, "alice": 90, "bob": 85}
	data, err := json.Marshal(scores, json.Deterministic(true))
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))

	data, err = json.Marshal(scores, json.Deterministic(true), jsontext.Multiline(true))
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))

	var c Config
	err = json.Unmarshal([]byte(`{"port":8080,"debug":true}`), &c, json.RejectUnknownMembers(true))
	fmt.Println("錯誤:", err)
}
```

執行結果：

```text
{"alice":90,"bob":85,"carol":72}
{
	"alice": 90,
	"bob": 85,
	"carol": 72
}
錯誤: json: cannot unmarshal JSON string into Go main.Config: unknown object member name "debug"
```

- `json.Deterministic(true)`：讓同樣的輸入每次都產生同樣的輸出。
- `jsontext.Multiline(true)`：多行排版，預設用 Tab 縮排。
- `json.RejectUnknownMembers(true)`：遇到 struct 沒有的欄位就報錯，適合檢查設定檔有沒有打錯字。v1 和 v2 預設都是忽略。

### 讀寫 Reader／Writer

v1 的 `Encoder`／`Decoder` 在 v2 對應到兩個函式：

```go
package main

import (
	"encoding/json/v2"
	"fmt"
	"os"
	"strings"
)

type Point struct {
	X int `json:"x"`
	Y int `json:"y"`
}

func main() {
	var p Point
	err := json.UnmarshalRead(strings.NewReader(`{"x": 3, "y": 4}`), &p)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	p.X *= 10
	if err := json.MarshalWrite(os.Stdout, p); err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println()
}
```

執行結果：

```text
{"x":30,"y":4}
```

`UnmarshalRead(r, &v)` 從 `io.Reader` 讀，`MarshalWrite(w, v)` 寫到 `io.Writer`。和 v1 的 `Encoder.Encode` 不同，`MarshalWrite` 不會在最後加換行，所以範例自己補了一個 `fmt.Println()`。

### `encoding/json/jsontext`：底層的語法層

v2 分成兩層：`encoding/json/v2` 負責「JSON 和 Go 型別怎麼對應」，而 `encoding/json/jsontext` 只負責「JSON 文字的語法」，把 JSON 看成一連串的**token**（`{`、`}`、`[`、`]`、字串、數字、`true`、`false`、`null`）。剛剛用到的 `Multiline`、`AllowDuplicateNames` 都是它的選項。

大部分時候用不到它，但要處理很大的 JSON、只想挑其中一小部分時很有用：

```go
package main

import (
	"encoding/json/jsontext"
	"fmt"
	"io"
	"strings"
)

func main() {
	input := `{"name":"Andy","langs":["go",1,true]}`
	dec := jsontext.NewDecoder(strings.NewReader(input))
	for {
		tok, err := dec.ReadToken()
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Println("錯誤:", err)
			return
		}
		fmt.Printf("%-6v %s\n", tok.Kind(), tok)
	}
}
```

執行結果：

```text
{      {
string name
string Andy
string langs
[      [
string go
number 1
true   true
]      ]
}      }
```

`ReadToken` 一次讀一個 token，不需要先定義 struct。`jsontext` 也有對應的 `Encoder` 可以一個 token 一個 token 寫出 JSON，以及代表一段完整 JSON 文字的 `jsontext.Value` 型別。

### 該用哪一個

- 新寫的程式：建議用 v2，預設值比較安全。記得 `omitempty` 改用 `omitzero`、需要固定 map 順序時加 `json.Deterministic(true)`。
- 既有的程式：繼續用 `encoding/json` 完全沒問題，它會一直被支援，而且上一集提過，它的底層已經是 v2 了。

## 重點整理

- `encoding/json/v2` 在 Go 1.27 正式可用，`Marshal`／`Unmarshal` 用法和 v1 相同，另外可以傳選項。
- v2 編碼時 nil 切片是 `[]`、nil map 是 `{}`，不跳脫 HTML 字元；`omitempty` 只省略空的 JSON 值，省略 `0`／`false` 要用 `omitzero`。
- v2 解碼預設拒絕重複的鍵和不合法的 UTF-8，欄位名稱比對區分大小寫。
- v2 編碼 map 的順序不固定，用 `json.Deterministic(true)` 固定；排版用 `jsontext.Multiline(true)`；讀寫 Reader／Writer 用 `UnmarshalRead`／`MarshalWrite`。
- `encoding/json/jsontext` 處理 JSON 的語法層，可以一個 token 一個 token 讀寫。
