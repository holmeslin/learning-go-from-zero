# `WithValue`

## 本集目標

學會用 `context.WithValue` 把少量資料附在 context 上，知道 key 為什麼要用自訂的未匯出型別，以及什麼資料適合放進去。

## 正文

### 把資料掛在 context 上

`context.WithValue(parent, key, val)` 會回傳一個新的 context，上面多掛了一筆「`key` 對應到 `val`」的資料。之後用 `ctx.Value(key)` 取出來：

```go
package main

import (
	"context"
	"fmt"
)

type ctxKey int

const requestIDKey ctxKey = 0

func handle(ctx context.Context) {
	id, ok := ctx.Value(requestIDKey).(string)
	if !ok {
		fmt.Println("沒有請求編號")
		return
	}
	fmt.Println("處理請求", id)
}

func main() {
	ctx := context.WithValue(context.Background(), requestIDKey, "req-42")
	handle(ctx)
	handle(context.Background())
}
```

執行結果：

```text
處理請求 req-42
沒有請求編號
```

- `ctx.Value` 的回傳型別是 `any`，所以要用第 4 章的型別斷言 `.(string)` 轉回來。
- 用 comma-ok 寫法：找不到這把 key 時 `Value` 回傳 `nil`，斷言失敗，`ok` 是 `false`，程式不會 panic。

`WithValue` 不會改動原本的 context，而是產生一個新的。查詢時，`Value` 會先看自己身上有沒有這把 key，沒有就往父 context 找，一路找到最上層。

### key 要用自訂型別

上面的 key 不是直接寫字串 `"requestID"`，而是特地定義了 `type ctxKey int`。為什麼？

context 會被一路傳過很多套件。如果大家都用字串當 key，你的套件用 `"id"` 存請求編號，另一個套件也用 `"id"` 存使用者編號，後放的就會蓋掉先放的，兩邊互相踩到。

`ctx.Value` 比對 key 時，**型別和值都要相同**才算同一把 key。每個套件都定義自己的型別，就算底層的值剛好一樣，也不會撞在一起：

```go
package main

import (
	"context"
	"fmt"
)

type keyA int
type keyB int

func main() {
	ctx := context.WithValue(context.Background(), keyA(0), "A 套件的資料")
	ctx = context.WithValue(ctx, keyB(0), "B 套件的資料")

	fmt.Println(ctx.Value(keyA(0)))
	fmt.Println(ctx.Value(keyB(0)))
	fmt.Println(ctx.Value(0))
}
```

執行結果：

```text
A 套件的資料
B 套件的資料
<nil>
```

`keyA(0)`、`keyB(0)` 和普通的整數 `0`，值都是 0，但型別不同，所以是三把不同的 key。

再把這個型別取成**小寫開頭、不匯出**的名字（第 8 章），其他套件就連這把 key 都做不出來，只能透過你提供的函式存取。

### 慣例：提供存取函式

實務上會把 key 藏起來，只匯出一組「放進去」和「拿出來」的函式。假設這是 `request` 套件：

```go,ignore
package request

import "context"

type ctxKey int

const idKey ctxKey = 0

func WithID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, idKey, id)
}

func IDFrom(ctx context.Context) (string, bool) {
	id, ok := ctx.Value(idKey).(string)
	return id, ok
}
```

使用的人只要寫 `request.WithID(ctx, "req-42")` 和 `request.IDFrom(ctx)`，完全不用知道 key 長什麼樣子，型別斷言也集中在一個地方。

### 什麼該放、什麼不該放

`WithValue` 很方便，但很容易被濫用。原則是：**只放「跟著這次請求走」的資料**，例如請求編號、登入的使用者、追蹤用的資訊。

不該放的東西：

- 函式正常需要的參數，例如要查的訂單編號。這些應該明明白白寫在參數列上，讓人一看函式簽名就知道它需要什麼。
- 資料庫連線、設定檔這類「整個程式共用」的東西。

另外，`Value` 要一層一層往上找，掛太多資料也會變慢。把它當成少量附註，而不是萬用的 map。

## 重點整理

- `context.WithValue(parent, key, val)` 回傳帶著資料的新 context，用 `ctx.Value(key)` 取出，找不到時回傳 `nil`。
- `Value` 回傳 `any`，要用 comma-ok 的型別斷言轉回原本的型別。
- key 用自訂的未匯出型別，例如 `type ctxKey int`，避免不同套件的 key 互相衝突；不要用字串等內建型別。
- 慣例是把 key 藏起來，對外提供存取函式。
- 只放請求範圍的資料，不要拿來代替函式參數。
