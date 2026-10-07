# 內建 `min` `max` `clear`

## 本集目標

認識三個方便的內建函式：找最小值的 `min`、找最大值的 `max`，以及清空切片或 map 的 `clear`。

## 正文

`len`、`cap`、`append`、`copy`、`make`、`delete` 這些不用 `import` 就能使用的函式，叫做**內建函式**。這一集再認識三個。

### `min` 和 `max`

```go
package main

import "fmt"

func main() {
	fmt.Println(min(3, 1, 2))
	fmt.Println(max(3, 1, 2))
	fmt.Println(max(2.5, 7.1))
	fmt.Println(min("banana", "apple", "cherry"))
}
```

執行結果：

```text
1
3
7.1
apple
```

- `min` 回傳最小的值，`max` 回傳最大的值，參數可以給一個以上。
- 整數、小數、字串都可以用。字串比的是字典順序，所以 `"apple"` 最小。
- 所有參數的型別要一樣，不能把 `int` 跟 `string` 混在一起比。

以前要找兩個數字中比較大的，得自己寫 `if`；現在一行 `max(a, b)` 就好。

### 找出切片裡的最大值

`min` 和 `max` 不能直接把整個切片丟進去，但可以搭配迴圈：

```go
package main

import "fmt"

func main() {
	scores := []int{72, 95, 68, 88}
	best := scores[0]
	worst := scores[0]
	for _, s := range scores {
		best = max(best, s)
		worst = min(worst, s)
	}
	fmt.Println("最高", best, "最低", worst)
}
```

執行結果：

```text
最高 95 最低 68
```

另一個常見用法是把數字限制在某個範圍內，例如把成績限制在 0 到 100 之間：`min(max(score, 0), 100)`。

### `clear`

`clear` 用來清空，但用在切片和 map 上的效果**不一樣**：

```go
package main

import "fmt"

func main() {
	nums := []int{1, 2, 3}
	clear(nums)
	fmt.Println(nums, len(nums))

	scores := map[string]int{"小明": 90, "小華": 75}
	clear(scores)
	fmt.Println(scores, len(scores))
}
```

執行結果：

```text
[0 0 0] 3
map[] 0
```

- 用在**切片**：把每個元素都設成零值，但**長度不變**，元素還在，只是都變成 0 了。
- 用在 **map**：刪除所有的鍵值，map 變成空的，長度變成 0。

如果你想要的是「長度變成 0 的切片」，不是用 `clear`，而是用第 17 集的切片運算式 `nums = nums[:0]`。

這三個內建函式是 Go 1.21 才加入的，所以在比較舊的程式碼或網路文章裡，你可能會看到別人自己寫迴圈來做同樣的事。

## 重點整理

- `min(...)`、`max(...)` 回傳參數中的最小、最大值，可用於整數、小數和字串，參數型別要一致。
- 找切片的最大／最小值，可以在迴圈裡寫 `best = max(best, v)`。
- `clear(切片)` 把所有元素設成零值，長度不變。
- `clear(map)` 刪除所有鍵值，map 變成空的。
