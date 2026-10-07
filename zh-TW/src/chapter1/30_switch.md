# `switch`

## 本集目標

用 `switch` 更整齊地寫出「依照不同的值做不同的事」。

## 正文

用 `if` / `else if` 判斷一個變數是哪個值，寫起來會有點囉唆：

```go,ignore
if day == 1 {
	...
} else if day == 2 {
	...
} else if day == 3 {
	...
}
```

`switch` 可以把這種情況寫得更清楚。

### 基本用法

```go
package main

import "fmt"

func main() {
	day := 3
	switch day {
	case 1:
		fmt.Println("星期一")
	case 2:
		fmt.Println("星期二")
	case 3:
		fmt.Println("星期三")
	default:
		fmt.Println("其他天")
	}
}
```

執行結果：

```text
星期三
```

`switch day` 會拿 `day` 的值，從上往下跟每個 `case` 後面的值比較。找到相等的，就執行那個 `case` 底下的程式碼。全部都不相等時，執行 `default` 底下的程式碼。`default` 可以省略。

### 不用寫 `break`

在 Go 的 `switch` 裡，執行完一個 `case` 就會**自動結束**整個 `switch`，不會繼續跑到下一個 `case`。

如果你在其他程式語言學過 `switch`，可能習慣每個 `case` 最後都要寫 `break`，在 Go 裡不需要。（想讓它繼續執行下一個 `case` 的寫法在附錄一會介紹。）

### 一個 `case` 放多個值

好幾個值要做同一件事時，可以寫在同一個 `case`，用逗號隔開：

```go
package main

import "fmt"

func main() {
	day := 6
	switch day {
	case 1, 2, 3, 4, 5:
		fmt.Println("平日")
	case 6, 7:
		fmt.Println("週末")
	default:
		fmt.Println("不是正確的星期")
	}
}
```

執行結果：

```text
週末
```

字串也可以用在 `switch`：

```go
package main

import "fmt"

func main() {
	command := "stop"
	switch command {
	case "start":
		fmt.Println("開始")
	case "stop", "quit":
		fmt.Println("停止")
	default:
		fmt.Println("看不懂的指令")
	}
}
```

執行結果：

```text
停止
```

### 沒有值的 `switch`

`switch` 後面也可以什麼都不寫。這時每個 `case` 後面要放一個條件，第一個成立的 `case` 會被執行：

```go
package main

import "fmt"

func main() {
	score := 75
	switch {
	case score >= 90:
		fmt.Println("優秀")
	case score >= 60:
		fmt.Println("及格")
	default:
		fmt.Println("不及格")
	}
}
```

執行結果：

```text
及格
```

這跟第 11 集的 `if` / `else if` / `else` 做的事完全一樣，條件一樣是從上往下檢查，所以順序一樣重要。當 `else if` 很多個的時候，寫成 `switch` 通常比較好讀。

## 重點整理

- `switch 值` 會從上往下找第一個相等的 `case` 執行；都不相等時執行 `default`。
- 執行完一個 `case` 就自動結束，不需要寫 `break`。
- 一個 `case` 可以用逗號放好幾個值。
- `switch` 後面不寫值時，每個 `case` 放條件，效果等於 `if` / `else if` / `else`。
