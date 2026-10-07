# `slices.Collect` 與 `slices.Sorted`

## 本集目標

把迭代器交出的值收集成切片，並學會用 `slices.Sorted` 把 map 的鍵依序排好。

## 正文

### `slices.Collect`：迭代器變回切片

迭代器只會一個一個交出值，不會幫你存起來。想要一個切片時，用 `slices.Collect`：

```go
package main

import (
	"fmt"
	"iter"
	"slices"
)

func evens(n int) iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := 0; i <= n; i += 2 {
			if !yield(i) {
				return
			}
		}
	}
}

func main() {
	s := slices.Collect(evens(10))
	fmt.Println(s)
	fmt.Println("共", len(s), "個")
}
```

執行結果：

```text
[0 2 4 6 8 10]
共 6 個
```

`slices.Collect` 接收一個 `iter.Seq[E]`，把交出的值依序 `append` 進新切片再回傳。

### 把 map 的鍵收集起來

上一集的 `maps.Keys` 這時就派上用場了：

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	stock := map[string]int{"鉛筆": 12, "橡皮擦": 3, "尺": 7}
	names := slices.Collect(maps.Keys(stock))
	fmt.Println(len(names), "種商品")
}
```

執行結果：

```text
3 種商品
```

`names` 是 `[]string`，但裡面的順序和走訪 map 一樣不固定，所以這裡只印出長度。

### `slices.Sorted`：收集並排序

收集完通常還想排序。`slices.Sorted` 一次做完這兩件事：

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	score := map[string]int{"Carol": 77, "Alice": 90, "Bob": 85}
	for _, name := range slices.Sorted(maps.Keys(score)) {
		fmt.Println(name, score[name])
	}
}
```

執行結果：

```text
Alice 90
Bob 85
Carol 77
```

這次每次執行結果都一樣。「依照鍵的順序走訪 map」是非常常見的需求，`slices.Sorted(maps.Keys(m))` 這一行請記起來。

`slices.Sorted` 要求元素是可以比大小的型別（第 6 章的 `cmp.Ordered`）。如果要自訂排序規則，可以改用 `slices.SortedFunc`，它多收一個比較函式，用法和第 6 章的 `slices.SortFunc` 一樣。

### `maps.Collect`

反方向也有：`maps.Collect` 把 `iter.Seq2[K, V]` 收集成 map。搭配 `slices.All`，可以把切片變成「索引對應值」的 map：

```go
package main

import (
	"fmt"
	"maps"
	"slices"
)

func main() {
	colors := []string{"紅", "綠", "藍"}
	m := maps.Collect(slices.All(colors))
	fmt.Println(m[2])
	fmt.Println(len(m))
}
```

執行結果：

```text
藍
3
```

## 重點整理

- `slices.Collect(seq)` 把 `iter.Seq` 交出的值收集成切片。
- `slices.Sorted(seq)` 收集後再排序；`slices.SortedFunc` 可自訂比較函式。
- `slices.Sorted(maps.Keys(m))` 是依鍵的順序走訪 map 的常用寫法。
- `maps.Collect(seq2)` 把 `iter.Seq2` 收集成 map。
