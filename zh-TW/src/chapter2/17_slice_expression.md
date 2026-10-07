# 切片運算式 `s[a:b]`

## 本集目標

用 `s[a:b]` 從切片（或陣列）中取出一段，得到一扇新的窗戶。

## 正文

### 取出一段

```go
package main

import "fmt"

func main() {
	letters := []string{"a", "b", "c", "d", "e"}
	part := letters[1:4]
	fmt.Println(part)
}
```

執行結果：

```text
[b c d]
```

`letters[1:4]` 的意思是：從索引 1 開始，到索引 4 **之前**為止。所以拿到索引 1、2、3 這三個元素。

「包含開頭、不包含結尾」一開始可能有點彆扭，但它有個好處：**長度剛好是 `b - a`**。`[1:4]` 就是 4 - 1 = 3 個元素。

### 省略開頭或結尾

```go
package main

import "fmt"

func main() {
	letters := []string{"a", "b", "c", "d", "e"}
	fmt.Println(letters[:2])
	fmt.Println(letters[3:])
	fmt.Println(letters[:])
}
```

執行結果：

```text
[a b]
[d e]
[a b c d e]
```

- `[:2]`：省略開頭，等於 `[0:2]`，取前 2 個。
- `[3:]`：省略結尾，等於 `[3:len(letters)]`，從索引 3 取到最後。
- `[:]`：兩個都省略，就是整段。

### 新切片的長度與容量

切片運算式**不會複製元素**，它只是做出一扇新的窗戶，看向**同一個底層陣列**的另一段：

```go
package main

import "fmt"

func main() {
	nums := []int{10, 20, 30, 40, 50}
	part := nums[1:3]
	fmt.Println(part, "len", len(part), "cap", cap(part))
}
```

執行結果：

```text
[20 30] len 2 cap 4
```

```text
底層陣列： [ 10 | 20 | 30 | 40 | 50 ]
part：           └ 長度 2 ┘
                 └──── 容量 4 ────┘
```

`part` 的起點在索引 1，看得到 2 個元素，所以長度是 2。容量則是從起點一路算到底層陣列的尾端：20、30、40、50，共 4 格。

這個「共用同一個底層陣列」的特性有好處也有陷阱，下一集會專門來看。

### 陣列也能切

切片運算式也可以用在陣列上，結果是一個看著那個陣列的切片：

```go
package main

import "fmt"

func main() {
	arr := [5]int{1, 2, 3, 4, 5}
	s := arr[1:4]
	fmt.Println(s, len(s), cap(s))
}
```

執行結果：

```text
[2 3 4] 3 4
```

### 範圍要合法

`a` 和 `b` 不能是負數，`a` 不能大於 `b`，`b` 不能超過容量，否則會 panic（索引寫死的話，有些情況編譯時就會被擋下）。

## 重點整理

- `s[a:b]` 取出索引 `a` 到 `b` 之前的元素，長度是 `b - a`。
- `s[:b]` 從頭開始、`s[a:]` 取到最後、`s[:]` 取整段。
- 切片運算式不複製元素，新切片與原本的共用同一個底層陣列；容量從新起點算到底層陣列尾端。
- 陣列也可以用 `arr[a:b]` 切出切片。
