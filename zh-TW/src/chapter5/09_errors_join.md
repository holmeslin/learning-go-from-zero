# `errors.Join`

## 本集目標

用 `errors.Join` 把好幾個錯誤合併成一個，一次回報所有問題。

## 正文

### 一次說完所有問題

想像你在填一張註冊表單，送出後網站說「名字不能空白」；你改好再送，它又說「年齡不合法」；再改，又說「email 格式錯誤」。很煩對吧？比較好的做法是一次把所有問題都列出來。

到目前為止，函式只能回傳一個 `error`。`errors.Join` 可以把多個錯誤合成一個。

### 基本用法

```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	err1 := errors.New("名字不能空白")
	err2 := errors.New("年齡不合法")
	err := errors.Join(err1, err2)
	fmt.Println(err)
}
```

執行結果：

```text
名字不能空白
年齡不合法
```

合併後的錯誤印出來時，每個錯誤各占一行。

### 收集錯誤

`errors.Join` 會自動略過值是 `nil` 的錯誤。利用這一點，我們可以為每個檢查準備一個 `error` 變數，有問題才填進去，最後全部交給 `errors.Join`：

```go
package main

import (
	"errors"
	"fmt"
	"strings"
)

var ErrEmptyName = errors.New("名字不能空白")
var ErrBadAge = errors.New("年齡要在 0 到 150 之間")
var ErrBadEmail = errors.New("email 必須包含 @")

func validate(name string, age int, email string) error {
	var nameErr, ageErr, emailErr error
	if name == "" {
		nameErr = ErrEmptyName
	}
	if age < 0 || age > 150 {
		ageErr = ErrBadAge
	}
	if !strings.Contains(email, "@") {
		emailErr = ErrBadEmail
	}
	return errors.Join(nameErr, ageErr, emailErr)
}

func main() {
	err := validate("", 200, "andy.example.com")
	fmt.Println(err)
	fmt.Println("---")
	fmt.Println(errors.Is(err, ErrBadAge))
	fmt.Println(errors.Is(err, ErrEmptyName))

	fmt.Println("---")
	err = validate("Andy", 20, "andy@example.com")
	fmt.Println(err == nil)
}
```

執行結果：

```text
名字不能空白
年齡要在 0 到 150 之間
email 必須包含 @
---
true
true
---
true
```

這裡有兩件值得注意的事：

- 合併後的錯誤可以用 `errors.Is` 找到裡面**任何一個**錯誤，`errors.As` 和 `errors.AsType` 也一樣。
- 所有傳進去的錯誤都是 `nil` 時，`errors.Join` 回傳 `nil`。所以第二次驗證全部通過時，`err == nil` 是 `true`，呼叫者照樣用 `if err != nil` 檢查就好。

## 重點整理

- `errors.Join(err1, err2)` 把多個錯誤合成一個（要放幾個都可以），印出時每個錯誤一行。
- `nil` 的錯誤會被略過，所以可以把「可能是 `nil`」的錯誤直接全部交給它。
- `errors.Is`、`errors.As`、`errors.AsType` 都能在合併的錯誤裡找到其中任何一個。
- 傳入的錯誤全是 `nil` 時，`errors.Join` 回傳 `nil`。
