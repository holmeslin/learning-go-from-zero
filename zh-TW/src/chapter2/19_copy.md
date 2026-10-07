# `copy`

## 本集目標

用內建的 `copy` 把切片的元素複製一份，做出不共用底層陣列的複本。

## 正文

上一集看到，`b := a` 或 `b := a[1:3]` 都只是多一扇窗戶，改 `b` 會改到 `a`。如果我們想要一份**真正獨立**的複本，就要把元素一個一個複製到另一個底層陣列裡。內建函式 `copy` 就是做這件事的。

### 基本用法

```go
package main

import "fmt"

func main() {
	src := []int{1, 2, 3}
	dst := []int{0, 0, 0}

	n := copy(dst, src)
	fmt.Println("複製了", n, "個")

	dst[0] = 99
	fmt.Println("src:", src)
	fmt.Println("dst:", dst)
}
```

執行結果：

```text
複製了 3 個
src: [1 2 3]
dst: [99 2 3]
```

- `copy(目的地, 來源)`：注意順序，**目的地在前**，跟賦值 `dst = src` 的方向一樣。
- `copy` 會回傳實際複製了幾個元素。
- `dst` 有自己的底層陣列，所以改 `dst[0]` 不會影響 `src`。

這裡先手動準備了一個長度 3 的 `dst`，第 21 集會學到用 `make` 更方便地建立指定長度的切片。

### 複製的數量

`copy` **不會**幫目的地變長。它只複製「兩者長度中比較短的那個」那麼多個元素：

```go
package main

import "fmt"

func main() {
	src := []int{1, 2, 3, 4, 5}

	small := []int{0, 0}
	n := copy(small, src)
	fmt.Println(n, small)

	big := []int{0, 0, 0, 0, 0, 0, 0}
	n = copy(big, src)
	fmt.Println(n, big)

	var empty []int
	n = copy(empty, src)
	fmt.Println(n, empty)
}
```

執行結果：

```text
2 [1 2]
5 [1 2 3 4 5 0 0]
0 []
```

最後一個例子最常出錯：目的地是空的（長度 0），`copy` 一個都不會複製。**目的地要先有足夠的長度**，光有容量也不行。

### 用 `append` 做複本

另一種常見寫法，是從 `nil` 切片開始，一個一個 `append` 進去：

```go
package main

import "fmt"

func main() {
	src := []int{1, 2, 3}

	var clone []int
	for _, v := range src {
		clone = append(clone, v)
	}

	clone[0] = 99
	fmt.Println("src:", src)
	fmt.Println("clone:", clone)
}
```

執行結果：

```text
src: [1 2 3]
clone: [99 2 3]
```

`clone` 從 `nil` 開始長大，`append` 會幫它配置自己的底層陣列，和 `src` 互不相干。

## 重點整理

- `copy(dst, src)` 把 `src` 的元素複製到 `dst`，目的地寫在前面，回傳複製的個數。
- 複製的個數是 `len(dst)` 和 `len(src)` 中較小的那個；`copy` 不會讓 `dst` 變長。
- 複製後兩個切片有各自的底層陣列，修改互不影響。
- 從 `nil` 切片開始逐一 `append`，也能做出獨立的複本。
