# map 基礎

## 本集目標

用 map 建立「用鍵找值」的對照表，例如用名字查成績。

## 正文

切片用 0、1、2 這種數字索引找資料。可是很多時候，我們想用**名字**找資料：「小明考幾分？」「蘋果多少錢？」用切片的話，得先記住小明是第幾個，很不方便。這時就該用 **map**。

### 建立與查詢

```go
package main

import "fmt"

func main() {
	scores := map[string]int{
		"小明": 90,
		"小華": 75,
	}
	fmt.Println(scores["小明"])

	scores["小美"] = 88
	scores["小華"] = 80
	fmt.Println(scores)
	fmt.Println("共", len(scores), "人")
}
```

執行結果：

```text
90
map[小明:90 小美:88 小華:80]
共 3 人
```

- `map[string]int` 讀作「鍵是 `string`、值是 `int` 的 map」。
- 每一筆資料是一組 **鍵（key）: 值（value）**。用大括號建立時，如果分成好幾行寫，每行結尾都要有逗號，最後一行也是；寫在同一行時，例如 `map[string]int{"小明": 90}`，最後就不用逗號。
- `scores["小明"]` 用鍵查出值。
- `scores["小美"] = 88`：鍵不存在就**新增**一筆；`scores["小華"] = 80`：鍵已存在就**更新**它的值。
- `len(scores)` 是 map 裡有幾筆資料。

同一個鍵在 map 裡只會有一筆。用 `fmt.Println` 印出整個 map 時，`fmt` 會把鍵排序後再印，方便我們閱讀，但 map 本身並沒有順序，第 28 集會再談。

### 查不到的鍵

查一個不存在的鍵，不會出錯，而是得到值型別的**零值**：

```go
package main

import "fmt"

func main() {
	scores := map[string]int{"小明": 90}
	fmt.Println(scores["阿強"])
}
```

執行結果：

```text
0
```

「阿強」不在 map 裡，所以拿到 `int` 的零值 0。可是這樣就分不出「阿強考 0 分」還是「根本沒有阿強」了，下一集的 comma-ok 會解決這個問題。

### 用 `make` 建立空的 map

第 21 集的 `make` 也可以用來建立 map：

```go
package main

import "fmt"

func main() {
	prices := make(map[string]int)
	prices["蘋果"] = 30
	prices["香蕉"] = 15
	fmt.Println(prices)
}
```

執行結果：

```text
map[蘋果:30 香蕉:15]
```

`make(map[string]int)` 和 `map[string]int{}` 的效果一樣，都是一個可以放資料的空 map。

### 小心：`nil` map 不能寫入

只用 `var` 宣告、沒有建立的 map，它的零值是 `nil`。`nil` map 可以讀（查什麼都得到零值、`len` 是 0），但**不能寫入**：

```go,exit=2
package main

import "fmt"

func main() {
	var stock map[string]int
	fmt.Println(stock["蘋果"], len(stock))
	stock["蘋果"] = 10
	fmt.Println("這行不會執行")
}
```

執行結果（後面還有幾行除錯資訊，這裡省略）：

```text
0 0
panic: assignment to entry in nil map
```

前兩個值印得出來，寫入那一行就 panic 了。這跟切片不同：`nil` 切片可以直接 `append`，`nil` map 卻一定要先用 `make` 或 `{}` 建立才能放資料。

## 重點整理

- `map[K]V` 是用鍵 `K` 查值 `V` 的對照表，用 `map[K]V{鍵: 值, ...}` 或 `make(map[K]V)` 建立。
- `m[k]` 查值，`m[k] = v` 新增或更新，`len(m)` 是資料筆數；同一個鍵只會有一筆。
- 查不存在的鍵會得到值型別的零值，不會出錯。
- map 的零值是 `nil`：可以讀，但寫入會 panic，所以要先建立再使用。
