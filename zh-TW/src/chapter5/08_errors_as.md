# `errors.As` 與 `errors.AsType`

## 本集目標

用 `errors.As` 或 Go 1.26 新增的 `errors.AsType`，從包裝過的錯誤裡找出特定型別的錯誤，並讀取它的欄位。

## 正文

上一集留下一個問題：自訂錯誤被 `%w` 包起來之後，要怎麼把它拿出來？

`errors.Is` 問的是「裡面有沒有**這一個**錯誤」；這一集要問的是「裡面有沒有**這一種型別**的錯誤，有的話給我」。

### `errors.As`

```go
package main

import (
	"errors"
	"fmt"
)

type ValidationError struct {
	Field string
	Value int
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("欄位 %s 的值 %d 不合法", e.Field, e.Value)
}

func register(name string, age int) error {
	if age < 0 || age > 150 {
		err := &ValidationError{Field: "age", Value: age}
		return fmt.Errorf("註冊 %s：%w", name, err)
	}
	return nil
}

func main() {
	err := register("小美", 200)

	var ve *ValidationError
	if errors.As(err, &ve) {
		fmt.Println("出錯的欄位：", ve.Field)
		fmt.Println("填入的值：", ve.Value)
	}
}
```

執行結果：

```text
出錯的欄位： age
填入的值： 200
```

步驟是這樣：

1. 先宣告一個想要的型別的變數 `ve`，這裡是 `*ValidationError`。
2. 把 `ve` 的**位址** `&ve` 交給 `errors.As`。
3. `errors.As` 一層層拆開 `err`，找到第一個型別符合的錯誤，就把它存進 `ve`，並回傳 `true`；找不到回傳 `false`。

第 2 步最容易寫錯：`ve` 本身已經是指標了，還要再加 `&`，因為 `errors.As` 需要能修改 `ve` 這個變數（第 3 章學過，要讓函式改變數，就傳它的位址）。忘了加 `&` 的話，`go vet` 會提醒你。

### `errors.AsType`：更直接的寫法

Go 1.26 新增了 `errors.AsType`，不用先宣告變數，直接把找到的錯誤回傳給你：

```go
package main

import (
	"errors"
	"fmt"
)

type ValidationError struct {
	Field string
	Value int
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("欄位 %s 的值 %d 不合法", e.Field, e.Value)
}

func register(name string, age int) error {
	if age < 0 || age > 150 {
		err := &ValidationError{Field: "age", Value: age}
		return fmt.Errorf("註冊 %s：%w", name, err)
	}
	return nil
}

func main() {
	err := register("小美", 200)

	if ve, ok := errors.AsType[*ValidationError](err); ok {
		fmt.Println("出錯的欄位：", ve.Field)
		fmt.Println("填入的值：", ve.Value)
	}

	err = register("小明", 30)
	if _, ok := errors.AsType[*ValidationError](err); !ok {
		fmt.Println("沒有驗證錯誤")
	}
}
```

執行結果：

```text
出錯的欄位： age
填入的值： 200
沒有驗證錯誤
```

`errors.AsType[*ValidationError](err)` 裡，方括號裡放的是「要找的型別」；這種方括號的寫法是泛型，第 6 章會解釋。目前照著寫就好：把型別放在方括號裡、錯誤放在小括號裡。

它回傳兩個值，就像第 2 章的 comma-ok：

- 找到時：回傳那個錯誤和 `true`。
- 找不到時：回傳該型別的零值（這裡是 `nil` 指標）和 `false`。

搭配 `if` 的初始化敘述，`ve` 只活在 `if` 裡面，不會跑到外面造成混亂。新寫的程式建議用 `errors.AsType`；`errors.As` 在舊程式碼裡很常見，看得懂就好。

### `Is` 和 `As` 怎麼選？

| 想知道的事 | 用 |
| --- | --- |
| 是不是**某一個**特定的錯誤（哨兵錯誤） | `errors.Is` |
| 有沒有**某一種型別**的錯誤，而且要讀它的欄位 | `errors.AsType` 或 `errors.As` |

## 重點整理

- `errors.As(err, &target)` 會在 `err` 的包裝裡找第一個型別符合的錯誤，存進 `target` 並回傳 `true`。
- 傳給 `errors.As` 的是變數的位址，指標型別的變數也要再加 `&`。
- Go 1.26 起可以用 `errors.AsType[型別](err)`，直接回傳找到的錯誤和一個 `bool`。
- 比對特定錯誤值用 `errors.Is`，找特定錯誤型別用 `errors.AsType` 或 `errors.As`。
