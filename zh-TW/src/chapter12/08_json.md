# `encoding/json`

## 本集目標

用 `encoding/json` 在 Go 的資料和 JSON 文字之間互相轉換：`Marshal`、`MarshalIndent`、`Unmarshal`，以及處理資料流的 `Encoder`／`Decoder`。

## 正文

### JSON 長什麼樣子

JSON 是網路服務之間最常用的資料格式，用純文字表示資料：

```text
{"name": "Andy", "age": 30, "tags": ["go", "rust"], "admin": false}
```

`{}` 是物件（像 Go 的 struct 或 map），`[]` 是陣列（像切片），另外還有字串、數字、`true`/`false` 和 `null`。

附錄一的「struct tag 初探」已經用過 `json.Marshal`，也介紹了 `json:"name"`、`omitempty`、`omitzero` 這些 tag。這集把讀寫兩個方向補齊。

### 編碼：`Marshal` 與 `MarshalIndent`

把 Go 的值轉成 JSON 叫做**編碼**（marshal）：

```go
package main

import (
	"encoding/json"
	"fmt"
)

type Book struct {
	Title  string   `json:"title"`
	Author string   `json:"author"`
	Pages  int      `json:"pages"`
	Tags   []string `json:"tags,omitempty"`
	secret string
}

func main() {
	b := Book{Title: "小王子", Author: "聖修伯里", Pages: 96, Tags: []string{"童話", "經典"}, secret: "不會出現"}

	data, err := json.Marshal(b)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))

	pretty, err := json.MarshalIndent(b, "", "  ")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(pretty))
}
```

執行結果：

```text
{"title":"小王子","author":"聖修伯里","pages":96,"tags":["童話","經典"]}
{
  "title": "小王子",
  "author": "聖修伯里",
  "pages": 96,
  "tags": [
    "童話",
    "經典"
  ]
}
```

- 只有**匯出**（大寫開頭）的欄位會被編碼，小寫的 `secret` 被忽略了（第 8 章的匯出規則；`encoding/json` 是用第 11 章的 `reflect` 讀取欄位的）。
- `MarshalIndent(值, 每行前綴, 縮排)` 產生排版過、方便人閱讀的 JSON。

切片會變成 JSON 陣列，map 會變成 JSON 物件，而且 `encoding/json` 會把 map 的鍵**排序**後再輸出，所以結果是固定的。

### 解碼：`Unmarshal`

把 JSON 轉回 Go 的值叫做**解碼**（unmarshal）。要傳**指標**進去，`Unmarshal` 才能把結果填進你的變數：

```go
package main

import (
	"encoding/json"
	"fmt"
)

type Book struct {
	Title  string   `json:"title"`
	Author string   `json:"author"`
	Pages  int      `json:"pages"`
	Tags   []string `json:"tags"`
}

func main() {
	input := `{"title": "老人與海", "pages": 128, "price": 250, "tags": ["小說"]}`

	var b Book
	err := json.Unmarshal([]byte(input), &b)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Printf("%+v\n", b)
	fmt.Printf("作者是空字串? %t\n", b.Author == "")

	err = json.Unmarshal([]byte(`{"title": "壞掉的 JSON"`), &b)
	fmt.Println("錯誤:", err)
	err = json.Unmarshal([]byte(`{"pages": "很多"}`), &b)
	fmt.Println("錯誤:", err)
}
```

執行結果：

```text
{Title:老人與海 Author: Pages:128 Tags:[小說]}
作者是空字串? true
錯誤: unexpected end of JSON input
錯誤: json: cannot unmarshal string into Go struct field Book.pages of type int
```

- JSON 裡多出來的 `price`，struct 沒有對應欄位，直接被忽略。
- JSON 裡沒有的 `author`，欄位就保持零值。
- JSON 格式壞掉，或型別對不上（`pages` 是字串，欄位卻是 `int`），`Unmarshal` 會回傳錯誤。

### 不知道結構時：`map[string]any`

有時候事先不知道 JSON 長什麼樣子，可以解碼到 `map[string]any`，再用第 4 章的型別斷言取出值：

```go
package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	input := `{"name": "Andy", "age": 30, "langs": ["go", "sql"]}`

	var m map[string]any
	if err := json.Unmarshal([]byte(input), &m); err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	for _, key := range []string{"name", "age", "langs"} {
		fmt.Printf("%s: %v (%T)\n", key, m[key], m[key])
	}

	if age, ok := m["age"].(float64); ok {
		fmt.Println("明年", int(age)+1, "歲")
	}
}
```

執行結果：

```text
name: Andy (string)
age: 30 (float64)
langs: [go sql] ([]interface {})
明年 31 歲
```

要特別注意：解碼到 `any` 時，JSON 的數字**一律變成 `float64`**，即使原本是整數；陣列變成 `[]any`，物件變成 `map[string]any`。`%T` 印出的 `[]interface {}` 就是 `[]any`，因為 `any` 是 `interface{}` 的別名（第 11 章的型別別名）。能用 struct 的時候盡量用 struct，型別清楚得多。

### 資料流：`Encoder` 與 `Decoder`

`Marshal`／`Unmarshal` 處理的是一整塊 `[]byte`。如果資料來自或要寫到 `io.Reader`／`io.Writer`（檔案、網路連線），用 `json.NewEncoder` 和 `json.NewDecoder` 更直接：

```go
package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
)

type Event struct {
	ID   int    `json:"id"`
	Kind string `json:"kind"`
}

func main() {
	input := `{"id": 1, "kind": "login"}
{"id": 2, "kind": "click"}
{"id": 3, "kind": "logout"}`

	dec := json.NewDecoder(strings.NewReader(input))
	enc := json.NewEncoder(os.Stdout)
	for {
		var e Event
		err := dec.Decode(&e)
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Println("錯誤:", err)
			return
		}
		e.Kind = strings.ToUpper(e.Kind)
		enc.Encode(e)
	}

	enc.SetIndent("", "  ")
	enc.Encode(Event{ID: 99, Kind: "pretty"})
}
```

執行結果：

```text
{"id":1,"kind":"LOGIN"}
{"id":2,"kind":"CLICK"}
{"id":3,"kind":"LOGOUT"}
{
  "id": 99,
  "kind": "pretty"
}
```

- `Decoder` 從 Reader 一個一個讀出 JSON 值，讀完時回傳 `io.EOF`，和第 1 集的 Reader 一樣。這種「一行一個 JSON」的格式很常用在日誌檔。
- `Encoder` 把每個值編碼後寫進 Writer，**最後會自動加一個換行**。`SetIndent` 讓它輸出排版過的 JSON。
- 第 14 章寫 JSON API 時，就是用這兩個直接讀寫 HTTP 的請求和回應。

### Go 1.27：底層已經換成 v2

Go 1.27 正式加入了新版的 `encoding/json/v2`（下一集介紹），而我們這集用的 `encoding/json` 現在其實也是**用 v2 實作**的，只是預設設定成和以前完全相同的行為。所以：

- 你寫的程式不用改，輸出結果和以前一樣，解碼還變快了。
- 唯一可能看到的差異是**錯誤訊息的文字**和舊版不完全相同，所以程式不要依賴錯誤訊息的內容做判斷。
- 萬一真的遇到相容性問題，可以在編譯時設定 `GOEXPERIMENT=nojsonv2` 換回舊的實作。

舊的 `encoding/json` 會繼續被支援，不一定要改用 v2。不過官方文件建議新寫的程式優先考慮 v2，原因下一集會看到。

## 重點整理

- `json.Marshal` 把 Go 值編碼成 JSON，`MarshalIndent` 產生排版過的版本；只有匯出欄位會被編碼。
- `json.Unmarshal(data, &v)` 要傳指標；多的欄位被忽略，缺的欄位保持零值，格式或型別不符會回傳錯誤。
- 解碼到 `map[string]any` 時，數字一律是 `float64`；能用 struct 就用 struct。
- `json.NewDecoder(r).Decode(&v)` 從 Reader 讀、`json.NewEncoder(w).Encode(v)` 寫到 Writer。
- Go 1.27 起 `encoding/json` 底層由 v2 實作，行為不變，但錯誤訊息文字可能不同。
