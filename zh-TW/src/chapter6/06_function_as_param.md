# 函式當參數

## 本集目標

寫出接收函式當參數的函式，把「要做什麼」交給呼叫者決定。

## 正文

函式是值，值可以當參數傳，所以函式也可以當參數傳給另一個函式。

### 一個問題

假設我們想從一串分數裡，挑出「及格的」；另一個地方又想挑出「滿分的」；再一個地方想挑「不及格的」。如果每種都寫一個函式，它們長得幾乎一模一樣，只有 `if` 的條件不同。

那就把「條件」變成參數吧。

### 把條件當參數

```go
package main

import "fmt"

func filter(nums []int, keep func(int) bool) []int {
	var result []int
	for _, n := range nums {
		if keep(n) {
			result = append(result, n)
		}
	}
	return result
}

func isPassing(score int) bool {
	return score >= 60
}

func main() {
	scores := []int{45, 60, 88, 100, 59, 100}

	fmt.Println(filter(scores, isPassing))

	fmt.Println(filter(scores, func(s int) bool {
		return s == 100
	}))

	fmt.Println(filter(scores, func(s int) bool { return s < 60 }))
}
```

執行結果：

```text
[60 88 100 100]
[100 100]
[45 59]
```

`filter` 的第二個參數 `keep` 的型別是 `func(int) bool`：一個收一個 `int`、回傳 `bool` 的函式。`filter` 負責走訪和收集，至於「要不要留下」，交給 `keep` 決定。

呼叫的時候可以傳：

- 有名字的函式，例如 `isPassing`（不加小括號）。
- 現場寫的匿名函式，短的可以寫成一行。

### 搭配閉包

傳進去的匿名函式也可以是閉包，用到外面的變數：

```go
package main

import "fmt"

func filter(nums []int, keep func(int) bool) []int {
	var result []int
	for _, n := range nums {
		if keep(n) {
			result = append(result, n)
		}
	}
	return result
}

func main() {
	scores := []int{45, 60, 88, 100, 59, 73}
	threshold := 70

	high := filter(scores, func(s int) bool {
		return s >= threshold
	})
	fmt.Println(high)
}
```

執行結果：

```text
[88 100 73]
```

門檻 `threshold` 不用變成 `filter` 的參數，閉包會自己帶進去。

### 對每個元素做轉換

另一個常見的形狀是「對每個元素做同一件事」：

```go
package main

import "fmt"

func apply(nums []int, f func(int) int) []int {
	result := make([]int, 0, len(nums))
	for _, n := range nums {
		result = append(result, f(n))
	}
	return result
}

func main() {
	nums := []int{1, 2, 3}
	fmt.Println(apply(nums, func(n int) int { return n * 10 }))
	fmt.Println(apply(nums, func(n int) int { return n * n }))
}
```

執行結果：

```text
[10 20 30]
[1 4 9]
```

### 用型別名稱讓參數更好讀

函式型別寫起來有點長，可以用第 3 章的自訂型別幫它取名字：

```go
package main

import "fmt"

type Predicate func(int) bool

func count(nums []int, match Predicate) int {
	n := 0
	for _, x := range nums {
		if match(x) {
			n++
		}
	}
	return n
}

func main() {
	isEven := func(n int) bool { return n%2 == 0 }
	fmt.Println(count([]int{1, 2, 3, 4, 6}, isEven))
}
```

執行結果：

```text
3
```

`Predicate`（判斷條件）這個名字，比一串 `func(int) bool` 更能說明參數的用途。

## 重點整理

- 函式可以當參數傳給另一個函式，參數型別寫成函式型別，例如 `func(int) bool`。
- 可以傳有名字的函式（不加小括號），也可以現場寫匿名函式。
- 把「會變的部分」變成函式參數，就能讓同一個函式應付很多種需求。
- 可以用 `type 名稱 func(...) ...` 幫函式型別取名字，讓程式更好讀。
