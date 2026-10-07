# 零值

## 本集目標

知道用 `var` 建立變數卻沒給值時，每種型別會自動得到什麼值。

## 正文

第 13 集說過，`var count int` 沒給值的話，`count` 會自動是 0。那其他型別呢？

### 每種型別都有零值

在 Go 裡，變數**一定**會有值，不會有「還沒放東西」的狀態。建立時沒給值，Go 就會放進該型別的**零值**：

```go
package main

import "fmt"

func main() {
	var count int
	var price float64
	var name string
	var done bool
	fmt.Println("count:", count)
	fmt.Println("price:", price)
	fmt.Println("name:", name)
	fmt.Println("done:", done)
}
```

執行結果：

```text
count: 0
price: 0
name: 
done: false
```

| 型別 | 零值 |
| --- | --- |
| 所有整數型別（`int`、`int8`、`uint`……） | `0` |
| `float64`、`float32` | `0` |
| `string` | `""`（空字串，裡面一個字都沒有） |
| `bool` | `false` |

`name:` 後面什麼都沒印出來，因為空字串本來就沒有內容。要確認一個字串是不是空的，可以和 `""` 比較：

```go
package main

import "fmt"

func main() {
	var name string
	fmt.Println(name == "")
}
```

執行結果：

```text
true
```

### 零值很好用

因為有零值，很多時候我們不用特地寫初始值。例如計數或加總，從 0 開始剛好就是我們要的：

```go
package main

import "fmt"

func main() {
	var sum int
	for i := 1; i <= 5; i++ {
		sum += i
	}
	fmt.Println(sum)
}
```

執行結果：

```text
15
```

`var sum int` 和 `sum := 0` 的效果一樣。用哪一種都可以；用 `var` 的寫法，會讓讀程式的人知道「這裡就是從零值開始」。

後面的章節會一直看到零值，Go 很多東西都設計成「零值就能直接用」。

## 重點整理

- Go 的變數一定有值；用 `var` 建立卻沒給值時，會自動得到零值。
- 數字型別的零值是 `0`，`string` 是 `""`（空字串），`bool` 是 `false`。
- 計數、加總這種從 0 開始的變數，可以直接利用零值。
