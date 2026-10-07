# `errors.New`

## 本集目標

用 `errors.New` 快速做出一個錯誤，並讓自己的函式回傳 `error`。

## 正文

上一集我們自己定義了一個型別來當錯誤。但很多時候，錯誤只需要一句說明文字，專門寫一個型別有點麻煩。

### 一行做出錯誤

標準函式庫的 `errors` 套件有個 `New` 函式，給它一段文字，它就回傳一個 `error`：

```go
package main

import (
	"errors"
	"fmt"
)

func main() {
	err := errors.New("找不到這位同學")
	fmt.Println(err)
}
```

執行結果：

```text
找不到這位同學
```

### 讓函式回傳 `error`

錯誤真正的用途，是讓函式告訴呼叫它的人「我沒辦法完成工作」。第 2 章學過多個回傳值，Go 的習慣是把 `error` 放在**最後一個**回傳值：

```go
package main

import (
	"errors"
	"fmt"
)

func divide(a, b int) (int, error) {
	if b == 0 {
		return 0, errors.New("除數不能是 0")
	}
	return a / b, nil
}

func main() {
	result, err := divide(10, 2)
	fmt.Println(result, err)

	result, err = divide(10, 0)
	fmt.Println(result, err)
}
```

執行結果：

```text
5 <nil>
0 除數不能是 0
```

`divide` 有兩種結束方式：

- 出錯時，回傳一個「沒意義的值」（這裡用 `0`）加上一個錯誤。
- 成功時，回傳真正的結果，錯誤的位置放 `nil`。

`fmt.Println` 遇到值是 `nil` 的 `error`，會印出 `<nil>`。

### 錯誤訊息怎麼寫

Go 社群有個慣例：錯誤訊息用小寫英文開頭、結尾不加句號，例如 `errors.New("division by zero")`。因為錯誤常常會被串到別的訊息後面，句號放在中間會很怪。我們的範例用中文，就注意結尾不要加句號。

## 重點整理

- `errors.New("說明")` 會建立一個以這段文字為訊息的 `error`。
- 會出錯的函式，習慣把 `error` 當成最後一個回傳值。
- 成功時回傳 `nil` 當作錯誤；失敗時回傳錯誤，其他回傳值放零值。
- 錯誤訊息結尾不加句號。
