# 泛型方法

## 本集目標

用 Go 1.27 新增的泛型方法，讓方法宣告自己的型別參數，並知道它不能用在介面上的兩個限制。

## 正文

上一集的 `Stack[T]` 方法用的 `T`，是型別本身的型別參數。從 Go 1.27 開始，方法也可以**宣告自己的**型別參數，叫做泛型方法。

### 方法自己的型別參數

假設我們有一份購物清單，想把每個品項轉換成別的東西：有時候轉成長度（`int`），有時候轉成加了編號的字串。轉換結果的型別每次不同，所以讓方法自己帶一個型別參數 `U`：

```go
package main

import "fmt"

type ShoppingList struct {
	items []string
}

func (l ShoppingList) Map[U any](f func(string) U) []U {
	result := make([]U, 0, len(l.items))
	for _, item := range l.items {
		result = append(result, f(item))
	}
	return result
}

func main() {
	list := ShoppingList{items: []string{"牛奶", "吐司", "蘋果汁"}}

	lengths := list.Map[int](func(s string) int { return len([]rune(s)) })
	fmt.Println(lengths)

	labels := list.Map(func(s string) string { return "- " + s })
	fmt.Println(labels)
}
```

執行結果：

```text
[2 2 3]
[- 牛奶 - 吐司 - 蘋果汁]
```

寫法和泛型函式一樣：方法名稱後面接方括號 `[U any]`。

呼叫時可以寫 `list.Map[int](...)` 明確指定 `U`，也可以像第二次那樣省略，讓 Go 從傳進去的函式推論出 `U` 是 `string`。

在 Go 1.27 之前，這種事只能寫成一般的泛型函式 `Map(l, f)`；現在可以把它放在型別底下，用 `list.Map(f)` 呼叫，讀起來更自然。

### 泛型型別的泛型方法

型別本身有型別參數，方法也可以再加自己的：

```go
package main

import (
	"fmt"
	"strconv"
)

type Stack[T any] struct {
	items []T
}

func (s *Stack[T]) Push(v T) {
	s.items = append(s.items, v)
}

func (s Stack[T]) Convert[U any](f func(T) U) Stack[U] {
	var result Stack[U]
	for _, v := range s.items {
		result.Push(f(v))
	}
	return result
}

func main() {
	var nums Stack[int]
	nums.Push(10)
	nums.Push(20)

	texts := nums.Convert(func(n int) string {
		return "第 " + strconv.Itoa(n) + " 號"
	})
	fmt.Println(texts.items)
}
```

執行結果：

```text
[第 10 號 第 20 號]
```

`T` 來自 `Stack[T]`，在宣告型別時就決定了；`U` 是 `Convert` 自己的，每次呼叫可以不同。`strconv.Itoa` 是 `strconv.Atoi` 的反方向，把整數轉成文字。

### 限制一：介面的方法不能有型別參數

介面裡的方法不能宣告型別參數：

```go,compile_fail
package main

type Mapper interface {
	Map[U any](f func(string) U) []U
}

func main() {}
```

編譯錯誤：

```text
interface method must have no type parameters
```

### 限制二：泛型方法不能拿來實作介面

反過來，就算方法名稱對得上，泛型方法也不算實作了介面的方法：

```go,compile_fail
package main

import "fmt"

type Printer interface {
	Print(v int)
}

type Console struct{}

func (Console) Print[T any](v T) {
	fmt.Println(v)
}

func main() {
	var p Printer = Console{}
	p.Print(1)
}
```

編譯錯誤：

```text
Console does not implement Printer (wrong type for method Print)
		have Print[T any](T)
		want Print(int)
```

介面要的是 `Print(int)`，`Console` 有的是 `Print[T any](T)`，Go 認為兩者不同。

所以要記得：泛型方法適合用在「直接透過具體型別呼叫」的情況；需要透過介面使用的方法，就寫成一般的方法。

## 重點整理

- Go 1.27 起，方法可以宣告自己的型別參數，寫法是 `func (接收者) 方法名[U any](...)`。
- 呼叫時可以寫 `x.Method[int](...)` 指定，也可以讓 Go 推論。
- 泛型型別的方法可以同時使用型別的型別參數和方法自己的型別參數。
- 介面的方法不能有型別參數，泛型方法也不能用來實作介面的方法。
