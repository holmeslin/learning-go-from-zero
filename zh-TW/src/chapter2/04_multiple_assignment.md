# 多重賦值與交換

## 本集目標

在一行裡同時給好幾個變數賦值，並用它輕鬆交換兩個變數的值。

## 正文

### 一行宣告好幾個變數

`:=` 的左右兩邊都可以放好幾個東西，用逗號隔開，左邊第一個對右邊第一個，第二個對第二個：

```go
package main

import "fmt"

func main() {
	name, age := "小明", 12
	fmt.Println(name, age)
}
```

執行結果：

```text
小明 12
```

其實你已經看過這種寫法了：固定句型 `n, err := strconv.Atoi(line)` 左邊就有兩個變數。這個原理第 9 集會說明。

已經宣告過的變數，也可以用 `=` 一次重新賦值好幾個：

```go
package main

import "fmt"

func main() {
	x, y := 1, 2
	x, y = 10, 20
	fmt.Println(x, y)
}
```

執行結果：

```text
10 20
```

### 交換兩個變數

假設 `a` 是 1、`b` 是 2，我們想把它們對調。直覺的寫法是這樣：

```go
package main

import "fmt"

func main() {
	a, b := 1, 2
	a = b
	b = a
	fmt.Println(a, b)
}
```

執行結果：

```text
2 2
```

壞掉了！第一行 `a = b` 執行完，`a` 已經變成 2，原本的 1 不見了，第二行 `b = a` 就只能拿到 2。

傳統的解法是先找一個暫存變數把舊值存起來。但在 Go 裡，用多重賦值一行就搞定：

```go
package main

import "fmt"

func main() {
	a, b := 1, 2
	a, b = b, a
	fmt.Println(a, b)
}
```

執行結果：

```text
2 1
```

為什麼這樣就可以？因為 Go 會**先把右邊全部算完**（得到 2 和 1），**再一起**放進左邊的變數。所以不會有「改到一半，舊值就不見了」的問題。

### 數量要對上

左邊有幾個變數，右邊就要有幾個值，不然不能編譯：

```go,compile_fail
package main

import "fmt"

func main() {
	a, b := 1, 2, 3
	fmt.Println(a, b)
}
```

```text
assignment mismatch: 2 variables but 3 values
```

## 重點整理

- `a, b := 1, 2` 可以一次宣告好幾個變數；`a, b = 3, 4` 可以一次重新賦值。
- 多重賦值會先算完右邊的所有值，再一起放進左邊。
- 因此 `a, b = b, a` 可以直接交換兩個變數，不需要暫存變數。
- 左右兩邊的數量必須相同。
