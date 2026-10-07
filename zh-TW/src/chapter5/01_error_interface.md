# `error` 是介面

## 本集目標

知道 `error` 其實是一個只有 `Error() string` 方法的介面，並自己寫一個能當成 `error` 使用的型別。

## 正文

第 1 章用 `strconv.Atoi` 時，我們拿到一個叫 `err` 的變數，當時只說「有問題的時候它不是 `nil`」。現在學過介面了，終於可以揭開它的真面目。

### `error` 的定義

`error` 是 Go 內建的型別，它的定義只有短短幾行：

```go,ignore
type error interface {
	Error() string
}
```

就是一個介面，裡面只有一個方法 `Error()`，回傳一段文字，用來說明「發生了什麼錯」。

第 4 章學過，Go 的介面是隱式實作：任何型別只要有 `Error() string` 這個方法，就自動算是 `error`。

### 自己做一個 `error`

```go
package main

import "fmt"

type TooColdError struct {
	Temp int
}

func (e TooColdError) Error() string {
	return fmt.Sprintf("溫度 %d 度太冷了", e.Temp)
}

func main() {
	var err error = TooColdError{Temp: -5}
	fmt.Println(err.Error())
	fmt.Println(err)
}
```

執行結果：

```text
溫度 -5 度太冷了
溫度 -5 度太冷了
```

`TooColdError` 有 `Error() string` 方法，所以可以放進 `error` 型別的變數。

注意第二行：直接把 `err` 交給 `fmt.Println`，印出來的也是 `Error()` 回傳的文字。這跟第 4 章的 `fmt.Stringer` 很像，`fmt` 看到值是 `error`，就會呼叫它的 `Error()` 方法來印。

### `nil` 代表「沒有錯誤」

`error` 是介面，所以它的零值是 `nil`。Go 的約定是：

- `err == nil`：一切正常。
- `err != nil`：出錯了，可以呼叫 `Error()` 看原因。

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	_, err := strconv.Atoi("123")
	fmt.Println(err == nil)

	_, err = strconv.Atoi("abc")
	fmt.Println(err == nil)
	fmt.Println(err)
}
```

執行結果：

```text
true
false
strconv.Atoi: parsing "abc": invalid syntax
```

`"123"` 能轉成整數，`err` 是 `nil`；`"abc"` 不行，`err` 裡就裝了一個錯誤，印出來是一段英文說明。

## 重點整理

- `error` 是內建的介面，只有一個方法：`Error() string`。
- 任何有 `Error() string` 方法的型別都能當成 `error` 使用。
- `fmt.Println` 印 `error` 時，會印出 `Error()` 回傳的文字。
- `error` 的零值是 `nil`，代表沒有錯誤。
