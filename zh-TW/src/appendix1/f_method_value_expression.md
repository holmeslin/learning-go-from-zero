# 方法值與方法運算式

## 本集目標

把方法當成函式值來用：`t.M` 是方法值，`T.M` 是方法運算式。

## 正文

第 6 章學過「函式是值」，可以存進變數、當參數傳遞。方法也可以，只是有兩種取法。

### 方法值：`t.M`

在變數後面寫方法名稱、**不加括號**，得到的就是**方法值**。它是一個函式，而且已經「綁好」了接收者：

```go
package main

import "fmt"

type Greeter struct {
	Name string
}

func (g Greeter) Hello(to string) {
	fmt.Println(g.Name, "向", to, "打招呼")
}

func main() {
	andy := Greeter{Name: "Andy"}
	say := andy.Hello
	say("Bob")
	say("Cindy")
}
```

執行結果：

```text
Andy 向 Bob 打招呼
Andy 向 Cindy 打招呼
```

`say` 的型別是 `func(string)`，呼叫時不用再提供 `andy`，因為它已經記住了。

方法值最實用的地方，是可以直接傳給需要函式的地方：

```go
package main

import "fmt"

type Counter struct {
	total int
}

func (c *Counter) Add(n int) {
	c.total += n
}

func each(nums []int, f func(int)) {
	for _, n := range nums {
		f(n)
	}
}

func main() {
	var c Counter
	each([]int{1, 2, 3, 4}, c.Add)
	fmt.Println(c.total)
}
```

執行結果：

```text
10
```

`c.Add` 是指標接收者的方法，Go 會自動取 `&c` 綁進方法值，所以每次呼叫都修改到同一個 `c`。

### 小心：值接收者會在取值當下複製

如果方法是**值接收者**，方法值綁的是接收者在「取方法值那一刻」的副本：

```go
package main

import "fmt"

type Greeter struct {
	Name string
}

func (g Greeter) Hello(to string) {
	fmt.Println(g.Name, "向", to, "打招呼")
}

func main() {
	g := Greeter{Name: "Andy"}
	say := g.Hello
	g.Name = "Bob"
	say("Cindy")
}
```

執行結果：

```text
Andy 向 Cindy 打招呼
```

之後再改 `g.Name`，已經取出來的 `say` 不受影響。

### 方法運算式：`T.M`

在**型別**後面寫方法名稱，得到的是**方法運算式**。它沒有綁接收者，所以接收者會變成第一個參數：

```go
package main

import "fmt"

type Greeter struct {
	Name string
}

func (g Greeter) Hello(to string) {
	fmt.Println(g.Name, "向", to, "打招呼")
}

func main() {
	hello := Greeter.Hello
	hello(Greeter{Name: "Andy"}, "Bob")
	hello(Greeter{Name: "Dora"}, "Eric")
}
```

執行結果：

```text
Andy 向 Bob 打招呼
Dora 向 Eric 打招呼
```

`hello` 的型別是 `func(Greeter, string)`。每次呼叫都要自己把接收者傳進去。

指標接收者的方法，型別要寫成 `(*T)`，小括號不能省：

```go
package main

import "fmt"

type Counter struct {
	total int
}

func (c *Counter) Add(n int) {
	c.total += n
}

func main() {
	add := (*Counter).Add
	var c Counter
	add(&c, 5)
	add(&c, 7)
	fmt.Println(c.total)
}
```

執行結果：

```text
12
```

### 怎麼分辨？

看點號前面是什麼：

| 寫法 | 點號前面 | 接收者 | 例子的型別 |
| --- | --- | --- | --- |
| 方法值 | 變數 `t` | 已綁好 | `func(string)` |
| 方法運算式 | 型別 `T` | 變成第一個參數 | `func(Greeter, string)` |

實務上方法值用得比較多；方法運算式偶爾用在「同一個操作要套用到很多不同接收者」的時候。

## 重點整理

- `t.M`（不加括號）是方法值：一個已經綁好接收者 `t` 的函式。
- 值接收者的方法值，會在取值當下複製接收者；指標接收者則綁住同一個變數。
- `T.M` 是方法運算式：接收者變成第一個參數；指標接收者寫成 `(*T).M`。
- 兩者都能存進變數，或傳給需要函式的參數。
