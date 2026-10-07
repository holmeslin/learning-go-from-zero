# 可變參數 `...`

## 本集目標

寫出可以接收任意數量參數的函式，並學會用 `切片...` 把切片攤開傳進去。

## 正文

`fmt.Println` 可以傳一個參數，也可以傳五個參數。我們自己寫的函式，參數數量都是固定的。這一集來學 `fmt.Println` 是怎麼做到的。

### 宣告可變參數

在最後一個參數的型別前面加上 `...`，這個參數就能接收任意數量的值：

```go
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	fmt.Println(sum())
	fmt.Println(sum(5))
	fmt.Println(sum(1, 2, 3, 4))
}
```

執行結果：

```text
0
5
10
```

在函式裡面，`nums` 就是一個 `[]int` 切片，可以用 `len`、`for range`，跟一般切片一樣。沒有傳任何參數時，`nums` 是 `nil` 切片，長度 0。

### 和一般參數混用

可變參數只能有一個，而且必須放在**最後面**：

```go
package main

import "fmt"

func greetAll(greeting string, names ...string) {
	for _, name := range names {
		fmt.Println(greeting + "，" + name)
	}
}

func main() {
	greetAll("你好", "小明", "小美", "阿哲")
}
```

執行結果：

```text
你好，小明
你好，小美
你好，阿哲
```

第一個參數 `"你好"` 給了 `greeting`，剩下的全部進到 `names`。

### 把切片攤開傳進去

如果手上已經有一個切片，想傳給可變參數，直接傳是不行的，`sum` 要的是一個一個的 `int`，不是一個 `[]int`。這時在切片後面加上 `...`，把它「攤開」：

```go
package main

import "fmt"

func sum(nums ...int) int {
	total := 0
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	scores := []int{80, 95, 70}
	fmt.Println(sum(scores...))
}
```

執行結果：

```text
245
```

注意 `...` 的位置：

- 宣告時寫在型別前面：`nums ...int`。
- 呼叫時寫在切片後面：`scores...`。

### 你早就用過了

第 2 章的 `append` 就是可變參數函式，所以可以一次加好幾個元素：`append(s, 1, 2, 3)`。要把一個切片整個接到另一個切片後面，也是用攤開的寫法：

```go
package main

import "fmt"

func main() {
	a := []int{1, 2}
	b := []int{3, 4, 5}
	a = append(a, b...)
	fmt.Println(a)
}
```

執行結果：

```text
[1 2 3 4 5]
```

## 重點整理

- 在最後一個參數的型別前加 `...`（例如 `nums ...int`），就能接收任意數量的參數。
- 在函式裡，可變參數就是一個切片。
- 可變參數只能有一個，而且要放在最後。
- 呼叫時在切片後面加 `...`（例如 `sum(scores...)`），就能把切片攤開傳入。
