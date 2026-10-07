# `uuid`

## 本集目標

用 Go 1.27 新加入的 `uuid` 套件產生與解析 UUID，知道 `New` 和 `NewV7` 的差別，並把 UUID 用在 JSON 裡。

## 正文

### UUID 是什麼

資料庫裡的每筆訂單、每個使用者都需要一個獨一無二的編號。用 1、2、3 往上數很直覺，但如果有好幾台伺服器同時建立資料，就得互相協調「下一個號碼是多少」，很麻煩。

**UUID**（Universally Unique Identifier，通用唯一識別碼）換個思路：每個編號是 128 個 bit 的隨機數字，大到兩台電腦各自隨便產生，撞號的機率小到可以忽略，完全不用協調。它通常寫成 32 個十六進位數字、用 `-` 分成五段：

```text
f81d4fae-7dec-11d0-a765-00a0c91e6bf6
```

以前 Go 要產生 UUID 得用第三方套件，Go 1.27 起標準庫內建了 `uuid` 套件。

### 匯入路徑就是 `"uuid"`

這個套件直接放在標準庫的最上層，所以匯入路徑就是 `"uuid"`，和 `"fmt"`、`"time"` 一樣，前面沒有其他目錄：

```go
package main

import (
	"fmt"
	"uuid"
)

func main() {
	id := uuid.New()
	fmt.Println(id)
	fmt.Println(uuid.New())
}
```

執行結果（某一次）：

```text
526be4a1-689b-4239-bde4-691cc6f9595e
48e281bf-2365-4fd7-b741-733cf571e147
```

`uuid.New()` 每次都產生一個**新的**、不同的 UUID，所以你執行的結果一定和上面不一樣，每次執行也都不一樣。

- `uuid.New()` 回傳的型別是 `uuid.UUID`，底層是 `[16]byte`（16 個 byte 正好 128 個 bit）。
- 它有 `String` 方法，所以 `fmt.Println` 會印出熟悉的 `xxxxxxxx-xxxx-...` 格式。
- 隨機的部分用的是密碼學等級的安全亂數產生器（不是上一集的 `math/rand/v2`），可以安心當成不可預測的編號。

### `NewV4` 與 `NewV7`

UUID 有好幾個「版本」，差別在 128 個 bit 怎麼產生：

- `uuid.NewV4()`：版本 4，幾乎全部是隨機數字。目前 `uuid.New()` 就等於 `NewV4()`。
- `uuid.NewV7()`：版本 7，前 48 個 bit 是產生當下的時間（毫秒），後面才是隨機數字。

版本 7 的好處是**越晚產生的排在越後面**。拿來當資料庫的主鍵時，新資料總是加在尾端，資料庫的索引會比較有效率：

```go
package main

import (
	"fmt"
	"uuid"
)

func main() {
	a := uuid.NewV7()
	b := uuid.NewV7()
	fmt.Println(a)
	fmt.Println(b)
	fmt.Println("a 排在 b 前面?", a.Compare(b) < 0)
}
```

執行結果（某一次）：

```text
01a1154b-d67c-773f-af17-0bf5896f74aa
01a1154b-d67c-7804-ada4-9fade4566b36
a 排在 b 前面? true
```

兩個 UUID 開頭幾乎一樣，因為是在同一毫秒內產生的；第三段的開頭 `7` 代表版本 7。`Compare` 回傳負數、0、正數，表示小於、等於、大於，和第 6 章的 `cmp.Compare` 一樣。

### 解析：`Parse`

從資料庫、網址或 JSON 拿到的 UUID 是字串，要用 `uuid.Parse` 轉回 `uuid.UUID`。輸入固定，結果就固定：

```go
package main

import (
	"fmt"
	"uuid"
)

func main() {
	inputs := []string{
		"f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
		"{F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6}",
		"urn:uuid:f81d4fae-7dec-11d0-a765-00a0c91e6bf6",
		"hello",
	}
	first := uuid.MustParse(inputs[0])
	for _, s := range inputs {
		id, err := uuid.Parse(s)
		if err != nil {
			fmt.Printf("%q → 錯誤: %v\n", s, err)
			continue
		}
		fmt.Println(id, id == first)
	}

	fmt.Println(uuid.Nil())
	var zero uuid.UUID
	fmt.Println(zero == uuid.Nil())
}
```

執行結果：

```text
f81d4fae-7dec-11d0-a765-00a0c91e6bf6 true
f81d4fae-7dec-11d0-a765-00a0c91e6bf6 true
f81d4fae-7dec-11d0-a765-00a0c91e6bf6 true
"hello" → 錯誤: invalid uuid
00000000-0000-0000-0000-000000000000
true
```

- `Parse` 接受好幾種常見寫法：一般格式、大括號包起來、`urn:uuid:` 開頭，大小寫都可以；印出來一律是標準的小寫格式。
- 格式不對會回傳錯誤，這種來自外部的字串一定要檢查。
- `uuid.MustParse` 解析失敗會直接 `panic`，只適合用在寫死在程式裡、確定正確的字串。
- `uuid.UUID` 是陣列，可以直接用 `==` 比較，也能當 map 的鍵。
- `uuid.Nil()` 是全部為 0 的 UUID，也就是 `uuid.UUID` 的零值，常用來表示「還沒有編號」。

### 放進 JSON

`uuid.UUID` 有 `MarshalText` 和 `UnmarshalText` 方法，`encoding/json`（v1 和 v2 都是）看到這兩個方法，就會把它編碼成字串：

```go
package main

import (
	"encoding/json/v2"
	"fmt"
	"uuid"
)

type Order struct {
	ID   uuid.UUID `json:"id"`
	Item string    `json:"item"`
}

func main() {
	o := Order{ID: uuid.MustParse("f81d4fae-7dec-11d0-a765-00a0c91e6bf6"), Item: "筆記本"}
	data, err := json.Marshal(o)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))

	var back Order
	if err := json.Unmarshal(data, &back); err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(back.ID == o.ID)

	err = json.Unmarshal([]byte(`{"id":"not-a-uuid","item":"?"}`), &back)
	fmt.Println("格式錯誤時:", err != nil)
}
```

執行結果：

```text
{"id":"f81d4fae-7dec-11d0-a765-00a0c91e6bf6","item":"筆記本"}
true
格式錯誤時: true
```

如果沒有這兩個方法，`[16]byte` 會被編成一串數字或 Base64，很難閱讀。解碼時遇到不合法的 UUID 字串，`Unmarshal` 也會回傳錯誤，等於免費幫你做了格式檢查。

## 重點整理

- Go 1.27 新增標準庫 `uuid` 套件，匯入路徑就是 `"uuid"`；`uuid.UUID` 的底層是 `[16]byte`。
- `uuid.New()`（目前等於 `NewV4`）每次產生不同的隨機 UUID；`NewV7` 開頭含時間，越晚產生的排越後面。
- `uuid.Parse` 把字串轉成 UUID 並檢查格式；`MustParse` 失敗會 `panic`，只用在寫死的字串。
- UUID 可以用 `==` 比較、當 map 的鍵；`uuid.Nil()` 是零值；放進 JSON 時會自動編碼成字串。
