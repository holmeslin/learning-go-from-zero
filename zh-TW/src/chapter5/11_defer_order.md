# `defer` 的執行順序與參數求值

## 本集目標

知道多個 `defer` 會以「後進先出」的順序執行，以及 `defer` 呼叫的參數在寫下 `defer` 的那一刻就決定好了。

## 正文

### 後進先出

一個函式裡可以有好幾個 `defer`。它們會像疊盤子一樣：最後放上去的盤子最先被拿走。

```go
package main

import "fmt"

func main() {
	defer fmt.Println("第一個 defer")
	defer fmt.Println("第二個 defer")
	defer fmt.Println("第三個 defer")
	fmt.Println("main 的最後一行")
}
```

執行結果：

```text
main 的最後一行
第三個 defer
第二個 defer
第一個 defer
```

這個順序叫做 LIFO（Last In, First Out，後進先出）。

為什麼要這樣設計？想想穿衣服：先穿襪子再穿鞋，脫的時候要先脫鞋再脫襪子。資源也一樣，後拿到的東西常常依賴先拿到的東西，所以要反過來釋放。

```go
package main

import "fmt"

func main() {
	fmt.Println("打開房門")
	defer fmt.Println("關上房門")

	fmt.Println("打開抽屜")
	defer fmt.Println("關上抽屜")

	fmt.Println("拿出筆記本")
}
```

執行結果：

```text
打開房門
打開抽屜
拿出筆記本
關上抽屜
關上房門
```

先關抽屜、再關房門，剛好是打開順序的反過來。

### 迴圈裡的 `defer`

在迴圈裡 `defer`，每一輪都會疊上一個，函式結束時一樣倒過來執行：

```go
package main

import "fmt"

func main() {
	for i := range 3 {
		defer fmt.Println("defer", i)
	}
	fmt.Println("迴圈結束")
}
```

執行結果：

```text
迴圈結束
defer 2
defer 1
defer 0
```

### 參數在 `defer` 當下就算好

這是 `defer` 最容易讓人意外的地方。看這段程式：

```go
package main

import "fmt"

func main() {
	count := 1
	defer fmt.Println("defer 看到的 count：", count)

	count = 100
	fmt.Println("現在的 count：", count)
}
```

執行結果：

```text
現在的 count： 100
defer 看到的 count： 1
```

雖然 `fmt.Println` 是最後才執行，但它的參數 `count` 在寫下 `defer` 的那一行就已經算好了，當時是 `1`。之後再怎麼改 `count`，都不會影響已經記下來的值。

你可以想成：`defer` 那一行把「要呼叫什麼函式」和「要傳什麼值」都抄在一張便條紙上，只是先不執行。函式結束時，照著便條紙上的內容執行。

上一段迴圈的例子也是同樣的道理：每一輪 `defer` 時，`i` 的值當下就被記下來了，所以印出 `2`、`1`、`0`，而不是三次同樣的數字。

## 重點整理

- 同一個函式裡的多個 `defer` 以後進先出（LIFO）的順序執行。
- 後取得的資源先釋放，正好符合 LIFO 的順序。
- `defer` 呼叫的參數在寫下 `defer` 的那一刻就求值並記下來了。
- 之後再修改變數，不會影響已經 `defer` 的呼叫拿到的值。
