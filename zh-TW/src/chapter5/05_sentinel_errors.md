# 哨兵錯誤

## 本集目標

把常用的錯誤宣告成套件層級的變數（哨兵錯誤），讓呼叫者能分辨「是哪一種錯」。

## 正文

### 只看文字不夠用

假設我們寫一個查詢庫存的函式，它可能因為「找不到商品」或「庫存不足」而失敗。呼叫的人可能想對這兩種情況做不同的事，例如找不到就建議別的商品、庫存不足就提示補貨。

如果每次都用 `errors.New` 現做錯誤，呼叫者只能比對訊息文字，萬一哪天訊息改了一個字，程式就壞了。

### 宣告成變數

做法是：把錯誤事先做好，存在 `func` 外面的變數裡，大家都用同一個：

```go
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("找不到商品")
var ErrOutOfStock = errors.New("庫存不足")

func buy(stock map[string]int, item string) error {
	n, ok := stock[item]
	if !ok {
		return ErrNotFound
	}
	if n == 0 {
		return ErrOutOfStock
	}
	stock[item] = n - 1
	return nil
}

func main() {
	stock := map[string]int{"蘋果": 1, "香蕉": 0}

	for _, item := range []string{"蘋果", "香蕉", "西瓜"} {
		err := buy(stock, item)
		if err == ErrNotFound {
			fmt.Println(item + "：沒賣這個，要不要看看別的？")
		} else if err == ErrOutOfStock {
			fmt.Println(item + "：賣完了，請等補貨")
		} else {
			fmt.Println(item + "：購買成功")
		}
	}
}
```

執行結果：

```text
蘋果：購買成功
香蕉：賣完了，請等補貨
西瓜：沒賣這個，要不要看看別的？
```

像 `ErrNotFound`、`ErrOutOfStock` 這種預先做好、讓大家拿來比對的錯誤，叫做**哨兵錯誤**（sentinel error）。就像站崗的哨兵，看到它就知道發生了什麼事。

### 命名慣例

哨兵錯誤的名字習慣以 `Err` 開頭，例如 `ErrNotFound`。標準函式庫也有很多，例如 `io.EOF` 代表「讀到結尾了」，第 1 章用過的 `bufio.Scanner` 在內部就是靠它判斷輸入結束。`io.EOF` 是少數不以 `Err` 開頭的例外。

### 用 `==` 比對的問題

上面用 `err == ErrNotFound` 比對，在錯誤沒被包裝時沒問題。但上一集學了用 `%w` 包裝錯誤，包裝之後的錯誤是一個**新的**錯誤，用 `==` 就比不到了：

```go
package main

import (
	"errors"
	"fmt"
)

var ErrNotFound = errors.New("找不到商品")

func main() {
	err := fmt.Errorf("購買西瓜：%w", ErrNotFound)
	fmt.Println(err)
	fmt.Println(err == ErrNotFound)
}
```

執行結果：

```text
購買西瓜：找不到商品
false
```

明明裡面包著 `ErrNotFound`，`==` 卻說不相等。下一集的 `errors.Is` 就是來解決這個問題的。

## 重點整理

- 哨兵錯誤是預先宣告在套件層級的錯誤變數，讓呼叫者能分辨錯誤的種類。
- 名稱習慣以 `Err` 開頭，例如 `ErrNotFound`。
- 沒包裝過的錯誤可以用 `==` 和哨兵錯誤比對。
- 錯誤被 `%w` 包裝後，`==` 就比不到了。
