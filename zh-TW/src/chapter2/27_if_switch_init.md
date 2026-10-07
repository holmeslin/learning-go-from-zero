# `if` / `switch` 的初始化敘述

## 本集目標

在 `if` 和 `switch` 的條件前面，先寫一行「初始化敘述」，讓變數只活在需要它的地方。

## 正文

### 把變數宣告塞進 `if`

上一集的寫法是先查、再判斷：

```go,ignore
price, ok := prices[fruit]
if ok {
	fmt.Println(fruit, "一個", price, "元")
}
```

Go 允許把第一行搬進 `if` 裡面，用分號 `;` 隔開：

```go
package main

import "fmt"

func main() {
	prices := map[string]int{"蘋果": 30, "香蕉": 15}

	if price, ok := prices["蘋果"]; ok {
		fmt.Println("蘋果一個", price, "元")
	}

	if _, ok := prices["芭樂"]; !ok {
		fmt.Println("沒有賣芭樂")
	}
}
```

執行結果：

```text
蘋果一個 30 元
沒有賣芭樂
```

`if 初始化敘述; 條件 { ... }`：先執行分號前面的敘述，再判斷分號後面的條件。這是 Go 程式裡非常常見的寫法，尤其是 `if v, ok := m[k]; ok { ... }`。

### 變數只活在 `if` 裡

第 1 章學過作用域：變數只在宣告它的大括號裡有效。在初始化敘述裡宣告的變數，作用域就是**整個 `if`**，包含後面的 `else if` 和 `else`，但出了 `if` 就不見了：

```go
package main

import "fmt"

func main() {
	stock := map[string]int{"蘋果": 0, "香蕉": 12}

	if n, ok := stock["蘋果"]; !ok {
		fmt.Println("沒有這項商品")
	} else if n == 0 {
		fmt.Println("蘋果賣完了")
	} else {
		fmt.Println("蘋果還有", n, "個")
	}
}
```

執行結果：

```text
蘋果賣完了
```

`n` 和 `ok` 在三個分支裡都能用。但如果在 `if` 結束後寫 `fmt.Println(n)`，就會無法編譯，因為 `n` 已經不存在了。

好處是：這些只為了判斷而存在的變數不會「流出去」，不會跟後面的程式碼撞名，讀程式的人也一看就知道它們只在這裡使用。

反過來說，如果後面的程式還要用到那個變數，就**不要**塞進初始化敘述。例如固定句型 `n, err := strconv.Atoi(line)` 之後還要用 `n`，所以它是分開寫的。

### `switch` 也可以

`switch` 一樣可以在前面加初始化敘述：

```go
package main

import "fmt"

func main() {
	scores := map[string]int{"小明": 92, "小華": 67}

	switch s := scores["小明"]; {
	case s >= 90:
		fmt.Println("優等")
	case s >= 60:
		fmt.Println("及格")
	default:
		fmt.Println("不及格")
	}
}
```

執行結果：

```text
優等
```

注意分號後面什麼都沒寫，這就是第 1 章學過、不帶值的 `switch`，每個 `case` 自己寫條件。`s` 一樣只在這個 `switch` 裡有效。

分號後面也可以接要比對的值：

```go
package main

import "fmt"

func main() {
	words := map[int]string{1: "一", 2: "二", 3: "三"}

	switch n := len(words); n {
	case 0:
		fmt.Println("空的")
	case 3:
		fmt.Println("剛好三筆")
	default:
		fmt.Println("有", n, "筆")
	}
}
```

執行結果：

```text
剛好三筆
```

## 重點整理

- `if 初始化敘述; 條件 { ... }`：先執行初始化敘述，再判斷條件。
- 最常見的寫法是 `if v, ok := m[k]; ok { ... }`。
- 初始化敘述宣告的變數，只在整個 `if`（含 `else if`、`else`）或 `switch` 裡有效。
- `switch` 也能寫初始化敘述，分號後可以接要比對的值，也可以留空、讓每個 `case` 寫條件。
- 之後還要用到的變數，就不要寫在初始化敘述裡。
