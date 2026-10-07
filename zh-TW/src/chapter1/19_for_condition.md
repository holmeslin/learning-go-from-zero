# `for` 條件迴圈

## 本集目標

在 `for` 後面加上條件，讓迴圈在條件成立時繼續、不成立時停下來。

## 正文

上一集用 `for` + `if` + `break` 數到 3。這種「檢查某個條件，決定要不要繼續」的寫法很常見，所以 Go 讓我們可以直接把條件寫在 `for` 後面。

### 把條件寫在 `for` 後面

```go
package main

import "fmt"

func main() {
	count := 1
	for count <= 3 {
		fmt.Println("第", count, "次")
		count++
	}
	fmt.Println("結束")
}
```

執行結果：

```text
第 1 次
第 2 次
第 3 次
結束
```

`for count <= 3` 的意思是：**每一圈開始之前**先檢查 `count <= 3`。成立就執行大括號裡的程式碼；不成立就結束迴圈。

`count` 變成 4 的時候，`4 <= 3` 是 `false`，迴圈結束，接著印出「結束」。

### Go 沒有 `while`

如果你聽過其他程式語言，可能知道有一種叫 `while` 的迴圈，意思是「當條件成立時就一直重複」。Go 沒有 `while` 這個關鍵字，因為 `for 條件 { }` 做的就是一模一樣的事。Go 的迴圈全部都用 `for`，要記的東西比較少。

### 別忘了讓條件有機會變成 `false`

如果把 `count++` 忘掉了，`count` 永遠是 1，`count <= 3` 永遠成立，迴圈就變成停不下來的無限迴圈。寫條件迴圈時，要確認大括號裡有東西會讓條件最後變成 `false`。

### 條件一開始就不成立

條件是在每一圈**開始之前**檢查的，所以如果一開始就不成立，大括號裡的程式碼一次都不會執行：

```go
package main

import "fmt"

func main() {
	count := 10
	for count <= 3 {
		fmt.Println("第", count, "次")
		count++
	}
	fmt.Println("結束")
}
```

執行結果：

```text
結束
```

### 例子：存錢

每個月存 3000 元，要幾個月才能存到 10000 元？我們不知道要跑幾圈，但知道「什麼時候該停」：

```go
package main

import "fmt"

func main() {
	saving := 0
	months := 0
	for saving < 10000 {
		saving += 3000
		months++
	}
	fmt.Println("需要", months, "個月，共存了", saving, "元")
}
```

執行結果：

```text
需要 4 個月，共存了 12000 元
```

## 重點整理

- `for 條件 { ... }`：每一圈開始前檢查條件，成立就執行，不成立就結束迴圈。
- Go 沒有 `while`，`for 條件 { }` 就是其他語言的 `while`。
- 迴圈裡要有東西讓條件最後變成 `false`，否則會變成無限迴圈。
- 條件一開始就不成立時，迴圈一次都不會執行。
