# struct tag 初探

## 本集目標

看懂 struct 欄位後面那串 `` `json:"name"` ``，並用 `encoding/json` 體驗 `omitempty` 與 `omitzero`。

## 正文

讀別人的 Go 程式碼時，你很快會看到這種寫法：

```go,ignore
type User struct {
	Name string `json:"name"`
}
```

欄位型別後面那串用反引號包起來的東西，就是 **struct tag**。

### tag 只是一段字串

對 Go 語言本身來說，tag 就只是附在欄位上的一段 raw string，不會改變欄位的型別，也不會改變程式的行為。它的意義完全由**讀取它的套件**決定。

慣例格式是 `key:"value"`，多組之間用空格分開：

```go,ignore
type User struct {
	Name string `json:"name" db:"user_name"`
}
```

這個欄位帶了兩組資訊：`json` 這把鑰匙給 `encoding/json` 看，`db` 這把給資料庫相關的套件看。各個套件只讀自己那把鑰匙，其他的不理。

要注意格式很嚴格：冒號前後不能有空格，值一定要用雙引號。寫錯了編譯器不會報錯，只是套件讀不到，`go vet` 則會幫你檢查出常見的格式錯誤。

### 用 `encoding/json` 看 tag 的效果

`encoding/json` 可以把 struct 轉成 JSON 文字。JSON 是網路服務之間最常用的資料格式，第 12 章會深入介紹，這裡只用 `json.Marshal` 看看 tag 的作用：

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string
	Email string `json:"email"`
	Age   int    `json:"age"`
}

func main() {
	u := User{Name: "Andy", Email: "andy@example.com", Age: 30}
	data, err := json.Marshal(u)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))
}
```

執行結果：

```text
{"Name":"Andy","email":"andy@example.com","age":30}
```

`json.Marshal` 回傳 `[]byte` 和 `error`，我們用 `string(data)` 轉成字串印出來。

沒有 tag 的 `Name`，JSON 裡的名稱就直接用欄位名 `Name`。有 tag 的 `Email` 和 `Age`，就改用 tag 裡寫的 `email` 和 `age`。JSON 慣例多半用小寫，而 Go 的欄位必須大寫開頭才是匯出的，`encoding/json` 才看得到，tag 正好解決這個落差。

### `omitempty`：空的就不要輸出

在名稱後面加逗號和選項，可以調整行為。`omitempty` 表示「值是空的就整個省略」：

```go
package main

import (
	"encoding/json"
	"fmt"
)

type User struct {
	Name  string `json:"name"`
	Email string `json:"email,omitempty"`
	Age   int    `json:"age,omitempty"`
}

func main() {
	u := User{Name: "Bob"}
	data, err := json.Marshal(u)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))
}
```

執行結果：

```text
{"name":"Bob"}
```

`Email` 是空字串、`Age` 是 0，都被省略了。`omitempty` 認定的「空」是：`false`、`0`、空字串、`nil`，以及長度為 0 的切片和 map。

### `omitzero`：零值就不要輸出

`omitempty` 有個盲點：它不認得 struct。就算 struct 每個欄位都是零值，它也不算「空」，照樣輸出。Go 1.24 加入了 `omitzero`，只要欄位是**零值**就省略，struct 也適用：

```go
package main

import (
	"encoding/json"
	"fmt"
)

type Address struct {
	City string `json:"city"`
}

type User struct {
	Name string  `json:"name"`
	Home Address `json:"home,omitempty"`
	Work Address `json:"work,omitzero"`
}

func main() {
	u := User{Name: "Cindy"}
	data, err := json.Marshal(u)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(string(data))
}
```

執行結果：

```text
{"name":"Cindy","home":{"city":""}}
```

`Home` 和 `Work` 都是零值的 `Address`。用 `omitempty` 的 `Home` 還是被輸出了，用 `omitzero` 的 `Work` 則被省略。

如果型別有 `IsZero() bool` 方法，`omitzero` 會改用這個方法判斷是不是零值。

### 下一步

這集只是讓你看懂 tag 在做什麼。JSON 的讀取、更多選項，以及新的 `encoding/json/v2`，第 12 章會深入介紹。

## 重點整理

- struct tag 是寫在欄位後面、用反引號包起來的字串，慣例格式是 `key:"value"`。
- tag 本身不影響程式行為，由 `encoding/json` 等套件讀取並決定意義。
- `json:"name"` 指定 JSON 裡的名稱；沒寫 tag 就用欄位名稱。
- `omitempty` 省略空值，但不認得 struct；Go 1.24 起的 `omitzero` 省略零值，struct 也適用。
