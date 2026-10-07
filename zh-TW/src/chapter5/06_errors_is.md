# `errors.Is`

## 本集目標

用 `errors.Is` 判斷一個錯誤「裡面」是不是包著某個哨兵錯誤，即使它被 `%w` 包裝過好幾層。

## 正文

上一集最後看到：錯誤用 `%w` 包裝後，`==` 就認不出來了。`errors.Is` 會幫我們把包裝一層一層拆開來找。

### 基本用法

```go
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("找不到商品")

func main() {
	err := fmt.Errorf("購買西瓜：%w", ErrNotFound)
	fmt.Println(err == ErrNotFound)
	fmt.Println(errors.Is(err, ErrNotFound))
}
```

執行結果：

```text
false
true
```

`errors.Is(err, target)` 會先看 `err` 本身是不是 `target`；不是的話，就拆開一層包裝，看裡面那個是不是；再不是就繼續往裡拆，直到找到或拆不下去為止。

### 包了好幾層也找得到

```go
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("找不到商品")
var ErrOutOfStock = errors.New("庫存不足")

func findItem(stock map[string]int, item string) (int, error) {
	n, ok := stock[item]
	if !ok {
		return 0, ErrNotFound
	}
	return n, nil
}

func buy(stock map[string]int, item string) error {
	n, err := findItem(stock, item)
	if err != nil {
		return fmt.Errorf("購買 %s：%w", item, err)
	}
	if n == 0 {
		return fmt.Errorf("購買 %s：%w", item, ErrOutOfStock)
	}
	return nil
}

func checkout(stock map[string]int, items []string) error {
	for _, item := range items {
		if err := buy(stock, item); err != nil {
			return fmt.Errorf("結帳失敗：%w", err)
		}
	}
	return nil
}

func main() {
	stock := map[string]int{"蘋果": 3, "香蕉": 0}

	err := checkout(stock, []string{"蘋果", "西瓜"})
	fmt.Println(err)
	if errors.Is(err, ErrNotFound) {
		fmt.Println("提示：有商品不存在")
	}

	err = checkout(stock, []string{"香蕉"})
	fmt.Println(err)
	if errors.Is(err, ErrOutOfStock) {
		fmt.Println("提示：有商品賣完了")
	}
}
```

執行結果：

```text
結帳失敗：購買 西瓜：找不到商品
提示：有商品不存在
結帳失敗：購買 香蕉：庫存不足
提示：有商品賣完了
```

`ErrNotFound` 被包了兩層，`errors.Is` 一樣找得到。每一層函式都可以放心加上說明，不用擔心呼叫者認不出原本的錯誤。

### `%v` 包裝就找不到

上一集說過 `%w` 和 `%v` 印出的文字一樣，差別就在這裡：

```go
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("找不到商品")

func main() {
	wrapped := fmt.Errorf("購買西瓜：%w", ErrNotFound)
	copied := fmt.Errorf("購買西瓜：%v", ErrNotFound)
	fmt.Println(errors.Is(wrapped, ErrNotFound))
	fmt.Println(errors.Is(copied, ErrNotFound))
}
```

執行結果：

```text
true
false
```

用 `%v` 只抄了文字，原本的錯誤沒有被保留，`errors.Is` 當然找不到。

### 該用哪一個？

和哨兵錯誤比對時，**一律用 `errors.Is`**。就算現在的錯誤沒被包裝，以後也可能被包裝，用 `errors.Is` 永遠不會出錯。

## 重點整理

- `errors.Is(err, target)` 判斷 `err` 本身或它包著的錯誤裡，有沒有 `target`。
- 不管包了幾層 `%w`，`errors.Is` 都會一路拆開去找。
- 用 `%v` 包裝不會保留原本的錯誤，`errors.Is` 會找不到。
- 和哨兵錯誤比對時，用 `errors.Is` 取代 `==`。
