# `append`、`len`、`cap`

## 本集目標

用 `append` 在切片尾端加入元素，並用 `len` 和 `cap` 觀察切片的長度與容量。

## 正文

### `append`：加到最後面

```go
package main

import "fmt"

func main() {
	var names []string
	names = append(names, "小明")
	names = append(names, "小華")
	names = append(names, "小美", "阿強")
	fmt.Println(names, len(names))
}
```

執行結果：

```text
[小明 小華 小美 阿強] 4
```

`append(切片, 值...)` 會把值加到切片尾端，一次可以加一個或好幾個。

最重要的是要**把結果接回來**：`names = append(names, ...)`。`append` 不是「修改」原本的切片，而是**回傳**一個新的切片。忘了接回來，就等於白做（而且 Go 會拒絕編譯，因為 `append` 的結果沒有被使用）。

從 `nil` 切片開始 `append` 完全沒問題，這是 Go 裡建立切片最常見的方式之一。

### `cap`：容量

上一集說切片有長度和容量。長度用 `len` 看，容量用 `cap` 看：

```go
package main

import "fmt"

func main() {
	var nums []int
	for i := range 6 {
		nums = append(nums, i)
		fmt.Println("len", len(nums), "cap", cap(nums))
	}
}
```

執行結果：

```text
len 1 cap 4
len 2 cap 4
len 3 cap 4
len 4 cap 4
len 5 cap 8
len 6 cap 8
```

- **長度**：切片目前裝了幾個元素。
- **容量**：底層陣列有幾格可以用（從切片的起點算起）。

### `append` 背後發生了什麼

底層陣列跟上一集的陣列一樣，大小是固定的。所以 `append` 會這樣做：

1. **容量還夠**（`len < cap`）：直接把新值放進底層陣列的下一格，長度加 1。
2. **容量不夠**（`len == cap`）：配置一個**更大的新陣列**，把舊的元素全部複製過去，再放入新值。回傳的切片就指向這個新陣列了。

上面的輸出可以看到，容量不是每次加 1，而是一次多要好幾格（一開始就拿了 4 格，滿了之後變成 8 格）。這是因為每次換新陣列都要複製全部元素，Go 會一次多要一些空間，減少搬家的次數。確切每次會變多大，由 Go 自己決定，而且可能隨版本調整，我們不需要記，也不應該依賴它。

這也是為什麼一定要寫 `names = append(names, ...)`：容量不夠時，新切片指向的是另一個陣列，不接回來就拿不到。

## 重點整理

- `s = append(s, 值...)` 在切片尾端加入一個或多個值，結果一定要接回來。
- `len(s)` 是目前元素個數，`cap(s)` 是底層陣列從起點算起可用的格數。
- 容量夠時，`append` 直接寫進底層陣列；不夠時，會配置更大的新陣列並複製過去。
- 容量成長的確切數字由 Go 決定，不要依賴它。
