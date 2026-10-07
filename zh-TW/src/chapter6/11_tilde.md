# `~` 底層型別

## 本集目標

知道約束裡的 `~int` 是什麼意思，讓泛型函式也能接受以 `int` 為底層型別的自訂型別。

## 正文

### 自訂型別被擋下來了

第 3 章學過自訂型別，例如 `type Score int`。`Score` 和 `int` 是不同的型別，只是「底層」都是 `int`。

如果約束只寫 `int`，`Score` 就不符合：

```go,compile_fail
package main

import "fmt"

type Score int

func double[T int | float64](x T) T {
	return x * 2
}

func main() {
	var s Score = 40
	fmt.Println(double(s))
}
```

編譯錯誤：

```text
Score does not satisfy int | float64 (possibly missing ~ for int in int | float64)
```

錯誤訊息很貼心，直接提示你：是不是少寫了 `~`？

### 加上 `~`

在型別前面加上 `~`，意思是「底層型別是它的所有型別」。`~int` 包含 `int` 本身，也包含 `Score`、以及任何 `type 某某 int` 宣告出來的型別：

```go
package main

import "fmt"

type Score int

type Meter float64

func double[T ~int | ~float64](x T) T {
	return x * 2
}

func main() {
	var s Score = 40
	var m Meter = 1.5
	fmt.Println(double(s))
	fmt.Println(double(m))
	fmt.Println(double(7))
}
```

執行結果：

```text
80
3
14
```

回傳值的型別也跟著是 `Score`、`Meter`，不會變回 `int` 或 `float64`，所以自訂型別的方法都還能用。

### 自訂型別的方法還在

```go
package main

import "fmt"

type Score int

func (s Score) String() string {
	return fmt.Sprintf("%d 分", int(s))
}

type Integer interface {
	~int | ~int64
}

func total[T Integer](nums []T) T {
	var sum T
	for _, n := range nums {
		sum += n
	}
	return sum
}

func main() {
	scores := []Score{80, 95, 70}
	fmt.Println(total(scores))
}
```

執行結果：

```text
245 分
```

`total` 回傳的是 `Score`，`fmt.Println` 會呼叫它的 `String()` 方法，印出「245 分」。

### `cmp.Ordered` 也是用 `~`

上一集的 `cmp.Ordered`，定義裡寫的就是 `~int | ~int8 | ... | ~float64 | ~string` 這樣的清單。所以自訂型別一樣能用：

```go
package main

import (
	"cmp"
	"fmt"
)

type Score int

func largest[T cmp.Ordered](s []T) T {
	m := s[0]
	for _, v := range s {
		if v > m {
			m = v
		}
	}
	return m
}

func main() {
	fmt.Println(largest([]Score{80, 95, 70}))
}
```

執行結果：

```text
95
```

自己寫數字類的約束時，習慣上都會加 `~`，讓自訂型別也能用。

## 重點整理

- 約束寫 `int` 只接受 `int` 本身，不接受 `type Score int` 這類自訂型別。
- `~int` 代表「底層型別是 `int` 的所有型別」，包含 `int` 和以它為底層的自訂型別。
- 用 `~` 時，泛型函式回傳的仍是原本的自訂型別，方法都還在。
- `cmp.Ordered` 裡的型別都有加 `~`；自己寫數字約束時也建議加上。
