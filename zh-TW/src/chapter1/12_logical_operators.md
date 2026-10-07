# 邏輯運算子

## 本集目標

用 `&&`、`||`、`!` 把好幾個條件組合在一起。

## 正文

有時候一個條件不夠用。例如：「年滿 18 歲**而且**有駕照，才能開車」。這時就要用邏輯運算子把條件組合起來。

| 運算子 | 意思 | 什麼時候是 `true` |
| --- | --- | --- |
| `&&` | 而且 | 兩邊**都是** `true` |
| `\|\|` | 或者 | 兩邊**至少一個**是 `true` |
| `!` | 不是 | 把 `true` 變 `false`，`false` 變 `true` |

### `&&`：兩個都要成立

```go
package main

import "fmt"

func main() {
	age := 20
	hasLicense := false
	if age >= 18 && hasLicense {
		fmt.Println("可以開車")
	} else {
		fmt.Println("不能開車")
	}
}
```

執行結果：

```text
不能開車
```

`age >= 18` 是 `true`，但 `hasLicense` 是 `false`。`&&` 要兩邊都是 `true` 才成立，所以結果是「不能開車」。

注意 `hasLicense` 本身就是布林值，可以直接當作條件，不用寫成 `hasLicense == true`。

### `||`：有一個成立就好

```go
package main

import "fmt"

func main() {
	day := 6
	if day == 6 || day == 7 {
		fmt.Println("週末")
	} else {
		fmt.Println("平日")
	}
}
```

執行結果：

```text
週末
```

`day` 是 6，`day == 6` 成立，所以整個條件就成立了。`||` 是兩條直線，在鍵盤 Enter 鍵附近，按住 Shift 再按反斜線 `\` 那個鍵就能打出來。

### `!`：反過來

```go
package main

import "fmt"

func main() {
	isRaining := false
	if !isRaining {
		fmt.Println("出門不用帶傘")
	}
}
```

執行結果：

```text
出門不用帶傘
```

`isRaining` 是 `false`，`!isRaining` 就是 `true`。讀的時候可以讀成「如果**沒有**在下雨」。

### 檢查一個數在不在範圍內

`&&` 很常用來檢查「介於兩者之間」：

```go
package main

import "fmt"

func main() {
	score := 105
	if score >= 0 && score <= 100 {
		fmt.Println("分數正常")
	} else {
		fmt.Println("分數不合理")
	}
}
```

執行結果：

```text
分數不合理
```

數學上會寫成 0 ≤ score ≤ 100，但 Go 不能這樣連著寫，要拆成兩個比較，再用 `&&` 接起來。

## 重點整理

- `&&`（而且）：兩邊都是 `true` 才是 `true`。
- `||`（或者）：至少一邊是 `true` 就是 `true`。
- `!`（不是）：把 `true`、`false` 反過來。
- 布林變數可以直接當條件；檢查範圍要寫成 `a >= 0 && a <= 100`。
