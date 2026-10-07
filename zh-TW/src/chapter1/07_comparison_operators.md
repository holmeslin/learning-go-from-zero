# 比較運算子

## 本集目標

用比較運算子比較兩個值，並認識比較的結果：`true` 和 `false`。

## 正文

除了算數學，程式也很常需要「比大小」：分數有沒有及格？密碼對不對？這就要用到比較運算子。

| 運算子 | 意思 |
| --- | --- |
| `==` | 等於 |
| `!=` | 不等於 |
| `<` | 小於 |
| `>` | 大於 |
| `<=` | 小於或等於 |
| `>=` | 大於或等於 |

### 比較的結果是 `true` 或 `false`

```go
package main

import "fmt"

func main() {
	fmt.Println(5 > 3)
	fmt.Println(5 < 3)
	fmt.Println(5 == 5)
	fmt.Println(5 != 5)
	fmt.Println(5 >= 5)
}
```

執行結果：

```text
true
false
true
false
true
```

比較算出來的結果只有兩種：`true`（成立、真的）或 `false`（不成立、假的）。這種只有真假兩種可能的值，叫做**布林值**。

布林值也能存進變數：

```go
package main

import "fmt"

func main() {
	score := 75
	passed := score >= 60
	fmt.Println("及格了嗎？", passed)
}
```

執行結果：

```text
及格了嗎？ true
```

### `==` 和 `=` 不一樣

比較「等不等於」要寫**兩個**等號 `==`。一個等號 `=` 在 Go 裡有別的用途（第 13 集會介紹），用錯的話程式會無法編譯。

### 字串也能比較

`==` 和 `!=` 也能用來比較兩段字串是不是一模一樣：

```go
package main

import "fmt"

func main() {
	password := "go123"
	fmt.Println(password == "go123")
	fmt.Println(password == "Go123")
}
```

執行結果：

```text
true
false
```

大小寫不同就算不一樣，`g` 和 `G` 是不同的字。

## 重點整理

- 比較運算子有 `==`、`!=`、`<`、`>`、`<=`、`>=`。
- 比較的結果是布林值：`true` 或 `false`，也可以存進變數。
- 比較相等要用兩個等號 `==`。
- 字串也能用 `==`、`!=` 比較，大小寫不同就不相等。
