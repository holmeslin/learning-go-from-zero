# 型別約束

## 本集目標

用型別約束限制型別參數可以是哪些型別，讓泛型函式裡能使用 `+`、`<` 這類運算。

## 正文

### `any` 什麼都不能做

上一集的型別參數都用 `any`。`any` 表示什麼型別都可以，但代價是：在函式裡，Go 不知道 `T` 到底是什麼，所以幾乎什麼運算都不讓你做。試試看寫一個加總函式：

```go,compile_fail
package main

import "fmt"

func sum[T any](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	fmt.Println(sum([]int{1, 2, 3}))
}
```

編譯錯誤：

```text
invalid operation: operator + not defined on total (variable of type T constrained by any)
```

Go 說：`T` 受到 `any` 約束，而不是每種型別都能用 `+`（例如 `bool` 或 struct 就不行），所以不能加。

### 用 `|` 列出允許的型別

約束可以寫成用 `|` 分開的型別清單，意思是「`T` 只能是這幾種之一」：

```go
package main

import "fmt"

func sum[T int | float64](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	fmt.Println(sum([]int{1, 2, 3}))
	fmt.Println(sum([]float64{1.5, 2.25}))
}
```

執行結果：

```text
6
3.75
```

`int` 和 `float64` 都能用 `+`，所以 Go 允許在函式裡寫 `total += n`。`var total T` 宣告一個 `T` 型別的變數，初始值是零值，`int` 和 `float64` 的零值都是 0。

如果傳入清單以外的型別，編譯器會擋下來：

```go,compile_fail
package main

import "fmt"

func sum[T int | float64](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}

func main() {
	fmt.Println(sum([]string{"a", "b"}))
}
```

編譯錯誤：

```text
string does not satisfy int | float64 (string missing in int | float64)
```

### 把約束取名字

約束其實就是一個**介面**。型別清單寫長了，可以宣告成有名字的介面，重複使用：

```go
package main

import "fmt"

type Number interface {
	int | int64 | float64
}

func sum[T Number](nums []T) T {
	var total T
	for _, n := range nums {
		total += n
	}
	return total
}

func average[T Number](nums []T) float64 {
	return float64(sum(nums)) / float64(len(nums))
}

func main() {
	fmt.Println(sum([]int64{10, 20, 30}))
	fmt.Println(average([]int{1, 2, 3, 4}))
}
```

執行結果：

```text
60
2.5
```

`Number` 是一個介面，但它裡面放的不是方法，而是型別清單。這種介面**只能拿來當約束**，不能用來宣告一般變數。

### 約束也可以是一般介面

第 4 章學過的、裝著方法的介面，也可以當約束，表示「`T` 必須有這些方法」：

```go
package main

import "fmt"

type Celsius float64

func (c Celsius) String() string {
	return fmt.Sprintf("%.1f°C", float64(c))
}

func joinAll[T fmt.Stringer](items []T) string {
	result := ""
	for i, item := range items {
		if i > 0 {
			result += ", "
		}
		result += item.String()
	}
	return result
}

func main() {
	temps := []Celsius{18.5, 22, 30.25}
	fmt.Println(joinAll(temps))
}
```

執行結果：

```text
18.5°C, 22.0°C, 30.2°C
```

約束是 `fmt.Stringer`，所以在函式裡可以呼叫 `item.String()`。

`any` 其實也是一個介面（沒有任何方法的介面），所以每個型別都滿足它。

## 重點整理

- 型別約束決定型別參數可以是哪些型別，也決定函式裡能對它做哪些運算。
- `any` 允許任何型別，但幾乎不能做運算。
- 用 `|` 列出型別（例如 `int | float64`），就能使用這些型別都支援的運算。
- 約束其實是介面，可以宣告成有名字的介面重複使用；含型別清單的介面只能當約束。
- 有方法的一般介面也能當約束，表示型別參數必須有這些方法。
