# 型別推論

## 本集目標

知道 Go 什麼時候能自動推出型別參數、什麼時候要自己寫，包含 Go 1.27 擴充的「轉換成函式型別」時的推論。

## 正文

前面幾集呼叫泛型函式時，大多沒有寫方括號，Go 自己就知道型別參數是什麼。這個功能叫做**型別推論**。這一集整理它的規則。

### 從參數推論

最常見的情況：從傳進去的值推出型別參數。

```go
package main

import "fmt"

func pair[T any](a, b T) []T {
	return []T{a, b}
}

func main() {
	fmt.Println(pair(1, 2))
	fmt.Println(pair("左", "右"))
	fmt.Println(pair[float64](1, 2))
}
```

執行結果：

```text
[1 2]
[左 右]
[1 2]
```

`pair(1, 2)` 中，`1` 和 `2` 是整數，Go 推出 `T` 是 `int`。第三行明確寫了 `[float64]`，`T` 就是 `float64`，`1`、`2` 會當成 `float64`，回傳的是 `[]float64`。

### 推不出來就要自己寫

如果型別參數沒有出現在參數裡，Go 就沒有線索可以推：

```go,compile_fail
package main

import "fmt"

func zero[T any]() T {
	var z T
	return z
}

func main() {
	fmt.Println(zero())
}
```

編譯錯誤：

```text
in call to zero, cannot infer T
```

這時要自己寫：`zero[int]()`、`zero[string]()`。第 5 章的 `errors.AsType[*ValidationError](err)` 也是這樣：參數 `err` 只是 `error`，看不出你想找哪一種型別，所以一定要寫。

型別參數有好幾個時，可以只寫前面幾個，後面的讓 Go 推：

```go
package main

import (
	"fmt"
	"strconv"
)

func convert[U, T any](s []T, f func(T) U) []U {
	result := make([]U, 0, len(s))
	for _, v := range s {
		result = append(result, f(v))
	}
	return result
}

func main() {
	nums := []int{1, 2, 3}
	fmt.Println(convert[string](nums, strconv.Itoa))
}
```

執行結果：

```text
[1 2 3]
```

`convert[string]` 指定了 `U`，`T` 則從 `nums` 推出是 `int`。印出來看起來和數字一樣，但其實是 `[]string`。

### 泛型函式當成值

第 1 集學過函式可以存進變數。泛型函式要當成值時，必須先確定型別參數，因為「還沒決定型別」的函式不是一個完整的值：

```go,compile_fail
package main

import "fmt"

func double[T int | float64](x T) T {
	return x * 2
}

func main() {
	f := double
	fmt.Println(f(21))
}
```

編譯錯誤：

```text
cannot use generic function double without instantiation
```

一種做法是自己寫出型別參數：`f := double[int]`。另一種做法是讓 Go 從「要放進去的地方」推論：如果變數已經寫明了函式型別，Go 就能比對出型別參數。

```go
package main

import "fmt"

func double[T int | float64](x T) T {
	return x * 2
}

func apply(nums []float64, f func(float64) float64) []float64 {
	result := make([]float64, 0, len(nums))
	for _, n := range nums {
		result = append(result, f(n))
	}
	return result
}

func main() {
	var f func(int) int = double
	fmt.Println(f(21))

	fmt.Println(apply([]float64{1.5, 2}, double))

	g := (func(float64) float64)(double)
	fmt.Println(g(0.25))
}
```

執行結果：

```text
42
[3 4]
0.5
```

三種情況都沒寫方括號：

- `var f func(int) int = double`：變數的型別是 `func(int) int`，Go 推出 `T` 是 `int`。
- `apply(..., double)`：參數 `f` 的型別是 `func(float64) float64`，Go 推出 `T` 是 `float64`。
- `(func(float64) float64)(double)`：把泛型函式**轉換**成函式型別。這是 Go 1.27 新加的：之後凡是把泛型函式賦值給、或轉換成相符的函式型別，都能推論。在 Go 1.26 以前，轉換的寫法會出現上面那個「without instantiation」的錯誤，必須寫成 `double[float64]`。

### 該不該寫方括號？

能推論就不寫，程式比較乾淨。只有在推不出來、或你想要的型別和推論結果不同時（例如上面的 `pair[float64]`），才明確寫出來。

## 重點整理

- Go 會從傳入的參數推論型別參數，大多數呼叫不用寫方括號。
- 型別參數沒出現在參數裡時推不出來，要自己寫，例如 `zero[int]()`。
- 可以只寫前面的型別參數，其餘交給推論。
- 泛型函式當成值使用時，Go 可以從目標的函式型別推論型別參數；Go 1.27 起連轉換成函式型別也可以。
