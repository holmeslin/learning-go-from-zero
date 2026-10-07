# `slices.All` `slices.Values` `maps.Keys`

## 本集目標

認識標準庫 `slices` 和 `maps` 套件裡會回傳迭代器的函式。

## 正文

第 6 章用過 `slices` 和 `maps` 套件的一些函式。這兩個套件裡還有一批函式，回傳的是 `iter.Seq` 或 `iter.Seq2`。它們本身不做什麼大事，主要用途是把切片或 map「變成迭代器」，好交給其他吃迭代器的函式（下一集就會看到）。

### `slices.All` 與 `slices.Values`

```go
package main

import (
	"fmt"
	"slices"
)

func main() {
	fruits := []string{"蘋果", "香蕉", "芒果"}

	for i, f := range slices.All(fruits) {
		fmt.Println(i, f)
	}
	for f := range slices.Values(fruits) {
		fmt.Println(f)
	}
}
```

執行結果：

```text
0 蘋果
1 香蕉
2 芒果
蘋果
香蕉
芒果
```

- `slices.All(s)` 回傳 `iter.Seq2[int, E]`，交出索引和值，就像 `for i, v := range s`。
- `slices.Values(s)` 回傳 `iter.Seq[E]`，只交出值。

這裡的 `E` 是切片元素的型別，這個例子是 `string`。單純走訪切片時，直接 `range fruits` 就好，不必繞一圈；這兩個函式要等到「需要一個迭代器」的場合才會發揮作用。

### `slices.Backward`

從後面往前走訪：

```go
package main

import (
	"fmt"
	"slices"
)

func main() {
	steps := []string{"穿襪子", "穿鞋子", "綁鞋帶"}
	fmt.Println("脫鞋的順序：")
	for i, s := range slices.Backward(steps) {
		fmt.Println(i, s)
	}
}
```

執行結果：

```text
脫鞋的順序：
2 綁鞋帶
1 穿鞋子
0 穿襪子
```

`slices.Backward` 和 `slices.All` 一樣交出索引和值，只是順序相反。以前要寫 `for i := len(s) - 1; i >= 0; i--`，現在一行就清楚。

### `maps.Keys`、`maps.Values` 與 `maps.All`

```go
package main

import (
	"fmt"
	"maps"
)

func main() {
	price := map[string]int{"紅茶": 30, "綠茶": 25, "奶茶": 45}

	for name := range maps.Keys(price) {
		fmt.Println(name)
	}

	total := 0
	for p := range maps.Values(price) {
		total += p
	}
	fmt.Println("全部點一杯要", total, "元")

	for name, p := range maps.All(price) {
		fmt.Println(name, p)
	}
}
```

執行結果（某一次）：

```text
紅茶
綠茶
奶茶
全部點一杯要 100 元
紅茶 30
綠茶 25
奶茶 45
```

- `maps.Keys(m)` 回傳 `iter.Seq[K]`，只交出鍵。
- `maps.Values(m)` 回傳 `iter.Seq[V]`，只交出值。
- `maps.All(m)` 回傳 `iter.Seq2[K, V]`，交出鍵和值。

和直接走訪 map 一樣，**順序是不固定的**，你執行的結果順序很可能和上面不同，每次執行也可能不一樣。只有加總出來的 100 元是固定的。想要固定順序，下一集會教你怎麼排序。

## 重點整理

- `slices.All` 交出索引和值，`slices.Values` 只交出值，`slices.Backward` 從後往前交出索引和值。
- `maps.Keys`、`maps.Values`、`maps.All` 分別交出鍵、值、鍵和值，順序不固定。
- 單純走訪時直接 `range` 切片或 map 即可；這些函式是在需要迭代器的場合使用。
