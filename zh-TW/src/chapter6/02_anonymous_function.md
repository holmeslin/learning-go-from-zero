# 匿名函式

## 本集目標

寫出沒有名字的函式（匿名函式），把它存進變數，或寫好之後馬上呼叫。

## 正文

上一集我們把函式存進變數，但那些函式都得先在外面用 `func 名字(...)` 宣告好。如果一個函式只在某個地方用一次，特地取名字放在外面有點多餘。

### 沒有名字的函式

匿名函式的寫法跟一般函式幾乎一樣，只是 `func` 後面不寫名字，而且可以直接寫在其他函式裡面：

```go
package main

import "fmt"

func main() {
	double := func(n int) int {
		return n * 2
	}
	fmt.Println(double(5))
	fmt.Println(double(21))
}
```

執行結果：

```text
10
42
```

`func(n int) int { ... }` 這一整段就是一個函式值，我們把它存進變數 `double`，之後就能用 `double(...)` 呼叫。

### 寫好馬上呼叫

匿名函式寫完後，直接在最後面加上 `()` 就會立刻執行：

```go
package main

import "fmt"

func main() {
	func() {
		fmt.Println("我馬上就執行了")
	}()

	result := func(a, b int) int {
		return a + b
	}(3, 4)
	fmt.Println(result)
}
```

執行結果：

```text
我馬上就執行了
7
```

注意最後的 `()` 和 `(3, 4)`：前面的 `func(...) {...}` 是函式，後面的小括號是「呼叫它」，參數就寫在這組小括號裡。

### 回頭看 `defer func() { ... }()`

第 5 章學 `recover` 時，提過一個「之後才會解釋」的寫法：

```go
package main

import "fmt"

func divide(a, b int) int {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("接住了 panic：", r)
		}
	}()
	return a / b
}

func main() {
	fmt.Println(divide(10, 0))
}
```

執行結果：

```text
接住了 panic： runtime error: integer divide by zero
0
```

現在看得懂了：`defer` 後面接的是一個「匿名函式加上 `()`」，也就是延後呼叫這個匿名函式。效果和第 5 章的 `defer handlePanic()` 一樣，只是不用另外取名字。這個 `defer func() { ... }()` 的寫法在 Go 程式裡非常常見。

### 匿名函式也能放進 map

上一集的計算機，也可以把運算直接寫在 map 裡：

```go
package main

import "fmt"

func main() {
	ops := map[string]func(int, int) int{
		"+": func(a, b int) int { return a + b },
		"-": func(a, b int) int { return a - b },
	}
	fmt.Println(ops["+"](10, 4))
	fmt.Println(ops["-"](10, 4))
}
```

執行結果：

```text
14
6
```

很短的匿名函式可以寫成一行，`gofmt` 會保留這種寫法。

## 重點整理

- 匿名函式就是 `func` 後面不寫名字的函式，可以寫在其他函式裡面。
- 匿名函式是一個值，可以存進變數或放進 map。
- 在匿名函式最後加上 `(...)` 就會立刻呼叫它。
- `defer func() { ... }()` 是延後呼叫一個匿名函式，常搭配 `recover` 使用。
