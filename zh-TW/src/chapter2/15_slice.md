# 切片

## 本集目標

認識切片（slice）：Go 裡最常用來裝「一串值」的東西，長度可以變。

## 正文

上一集說到陣列的長度固定，用起來不太方便。Go 程式裡真正天天在用的是**切片**（slice）。

### 寫法：不寫長度

切片的型別寫成 `[]int`，和陣列只差在中括號裡**沒有數字**：

```go
package main

import "fmt"

func main() {
	scores := []int{90, 85, 77}
	fmt.Println(scores)
	fmt.Println(scores[0], len(scores))

	scores[1] = 100
	fmt.Println(scores)

	for i, v := range scores {
		fmt.Println(i, v)
	}
}
```

執行結果：

```text
[90 85 77]
90 3
[90 100 77]
0 90
1 100
2 77
```

用索引讀寫、用 `len` 取長度、用 `for range` 走訪，全部都跟陣列一樣。那切片到底哪裡不同？

### 切片是一扇「窗戶」

切片自己其實不存放元素。元素放在一個藏在背後的陣列裡，叫做**底層陣列**。切片只記住三件事：

- **從哪裡開始看**：指向底層陣列中的某個位置。
- **長度**（length）：這扇窗戶目前看得到幾個元素。
- **容量**（capacity）：從開始的位置算起，底層陣列總共還有幾格可以用。

你可以把底層陣列想成一排置物櫃，切片就是一扇窗戶，透過它看到其中連續的幾格：

```text
底層陣列： [ 90 | 85 | 77 ]
切片：      └─ 長度 3 ──┘
```

`[]int{90, 85, 77}` 這種寫法，會先建立一個裝著這三個值的底層陣列，再給我們一個看著它整排的切片。

這個「窗戶」的觀念非常重要，後面幾集（`append`、切片運算式、共用底層陣列）都建立在它上面。

### 空切片與零值

切片可以是空的：

```go
package main

import "fmt"

func main() {
	var names []string
	fmt.Println(names, len(names))

	empty := []string{}
	fmt.Println(empty, len(empty))
}
```

執行結果：

```text
[] 0
[] 0
```

`var names []string` 沒有給值，切片的零值叫做 `nil`，意思是「還沒有指向任何底層陣列」。`nil` 切片的長度是 0，用起來就像空切片，可以照樣 `len`、`for range`（迴圈一圈都不會跑）。`nil` 這個字第 3 章會再詳細說明。

### 讀寫範圍不能超過長度

跟陣列一樣，索引必須小於 `len`。切片的長度在執行時才知道，所以超出範圍不會在編譯時被抓到，而是執行時 panic：

```go,exit=2
package main

import "fmt"

func main() {
	scores := []int{90, 85, 77}
	i := 3
	fmt.Println(scores[i])
}
```

```text
panic: runtime error: index out of range [3] with length 3
```

（panic 訊息後面還會跟著幾行除錯資訊，這裡省略。）panic 就是程式出了無法繼續的錯誤，直接當掉，第 5 章會正式介紹。那要怎麼讓切片變長？下一集的 `append` 就是答案。

## 重點整理

- 切片型別寫成 `[]int`（中括號內沒有長度），用 `[]int{1, 2, 3}` 建立。
- 索引、`len`、`for range` 的用法和陣列相同。
- 切片是一扇看向「底層陣列」的窗戶，記住起點、長度、容量三件事。
- 切片的零值是 `nil`，長度為 0；索引超出長度會在執行時 panic。
