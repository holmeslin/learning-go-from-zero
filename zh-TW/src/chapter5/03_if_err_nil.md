# `if err != nil` 慣例

## 本集目標

看懂第 1 章照抄的 `if err != nil` 固定句型，並在自己的函式裡用同樣的方式處理和傳遞錯誤。

## 正文

### 回頭看第 1 章的固定句型

第 1 章教讀取整數時，我們照抄了這段：

```go,ignore
n, err := strconv.Atoi(line)
if err != nil {
	fmt.Println("請輸入整數")
	return
}
```

現在每一個部分都看得懂了：

- `strconv.Atoi` 有兩個回傳值（第 2 章）：轉好的整數，和一個 `error`。
- `error` 是介面（第 5 章第 1 集），沒出錯時是 `nil`。
- `if err != nil` 就是在問：「有出錯嗎？」有的話，印訊息然後 `return`，提早結束（第 2 章的 early `return`）。
- 走到 `if` 後面，就能放心使用 `n`，因為出錯的情況已經離開了。

這個「先檢查錯誤、有錯就離開、沒錯繼續往下」的寫法，在 Go 程式裡到處都是。

### 先處理錯誤，正常流程靠左

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	inputs := []string{"42", "七"}
	for _, s := range inputs {
		n, err := strconv.Atoi(s)
		if err != nil {
			fmt.Println("轉換失敗：", err)
			continue
		}
		fmt.Println("兩倍是", n*2)
	}
}
```

執行結果：

```text
兩倍是 84
轉換失敗： strconv.Atoi: parsing "七": invalid syntax
```

注意程式的形狀：錯誤處理放在 `if` 裡面，處理完就離開（這裡用 `continue` 跳到下一輪）；正常的流程不用包在 `else` 裡，一路貼著左邊往下寫。這樣讀程式時，眼睛順著左邊往下看就是「一切順利時會發生什麼」。

### 把錯誤往上交

如果你寫的函式呼叫了會出錯的函式，最常見的處理方式是：自己也回傳 `error`，把錯誤交給呼叫你的人。

```go
package main

import (
	"fmt"
	"strconv"
)

func parseAge(s string) (int, error) {
	age, err := strconv.Atoi(s)
	if err != nil {
		return 0, err
	}
	return age, nil
}

func main() {
	age, err := parseAge("18")
	if err != nil {
		fmt.Println("錯誤：", err)
		return
	}
	fmt.Println("年齡：", age)

	_, err = parseAge("十八")
	if err != nil {
		fmt.Println("錯誤：", err)
		return
	}
}
```

執行結果：

```text
年齡： 18
錯誤： strconv.Atoi: parsing "十八": invalid syntax
```

`parseAge` 自己不印任何東西，只把錯誤原封不動地交回去，由 `main` 決定要怎麼跟使用者說。

### 用 `if` 的初始化敘述縮短

如果只需要錯誤、不需要其他回傳值，可以搭配第 2 章學過的 `if` 初始化敘述：

```go
package main

import (
	"fmt"
	"strconv"
)

func main() {
	if _, err := strconv.Atoi("3.14"); err != nil {
		fmt.Println("不是整數")
	}
}
```

執行結果：

```text
不是整數
```

這裡的 `err` 只活在這個 `if` 裡，不會影響外面。

### 不要忽略錯誤

用 `_` 把錯誤丟掉，程式能編譯，但出錯時你完全不會知道。除非你非常確定不會出錯，否則每一個 `error` 都要檢查。

## 重點整理

- `if err != nil` 是在檢查「有沒有出錯」，有錯就處理並提早離開。
- 錯誤處理放進 `if`，正常流程貼著左邊往下寫，不用 `else`。
- 自己的函式可以把收到的錯誤當作回傳值往上交，讓呼叫者決定怎麼處理。
- 只需要錯誤時，可以寫成 `if _, err := f(); err != nil { ... }`。
