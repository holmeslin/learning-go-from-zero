# `new` 與 `new(expr)`

## 本集目標

用內建的 `new` 建立指標：`new(型別)` 得到指向零值的指標，`new(值)` 得到指向那個值的指標。

## 正文

上一集我們用 `&Person{...}` 一步建立 struct 的指標。但如果想要一個指向 `int` 的指標呢？`&10` 是不能寫的，只能先放進變數再取位址：

```go
package main

import "fmt"

func main() {
	n := 10
	p := &n
	fmt.Println(*p)
}
```

執行結果：

```text
10
```

多了一個只是為了取位址的變數 `n`。Go 內建的 `new` 可以省掉這一步。

### `new(型別)`：指向零值

`new` 後面的小括號裡放一個型別，它會準備好一塊放得下這個型別的記憶體，填上零值，然後把指標交給你：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	p := new(int)
	fmt.Println(*p)
	*p = 7
	fmt.Println(*p)

	q := new(Person)
	q.Name = "Andy"
	fmt.Printf("%+v\n", q)
}
```

執行結果：

```text
0
7
&{Name:Andy Age:0}
```

`new(int)` 得到一個 `*int`，指向的值是 `0`。`new(Person)` 得到一個 `*Person`，效果跟 `&Person{}` 一樣。對 struct 來說，大家比較常寫 `&Person{}`，因為可以順便填欄位。

### `new(值)`：指向一個指定的值

從 Go 1.26 開始，`new` 的小括號裡也可以放一個**值**（任何算得出結果的運算式），它會建立一個指標，指向這個值的一份複本：

```go
package main

import "fmt"

func main() {
	a := new(42)
	b := new("hello")
	c := new(len("abc") * 2)
	fmt.Println(*a, *b, *c)
	fmt.Printf("%T %T %T\n", a, b, c)
}
```

執行結果：

```text
42 hello 6
*int *string *int
```

指標的型別由值決定：`42` 是 `int`，所以 `new(42)` 是 `*int`；`"hello"` 是 `string`，所以 `new("hello")` 是 `*string`。如果想要別的型別，就先轉換，例如 `new(int64(5))` 得到 `*int64`。

### 什麼時候會用到？

有些 struct 會用指標欄位來表示「這個值可以不填」。例如年齡不一定知道：

```go
package main

import "fmt"

type Profile struct {
	Name string
	Age  *int
}

func main() {
	p := Profile{Name: "Andy", Age: new(20)}
	fmt.Println(p.Name, *p.Age)
}
```

執行結果：

```text
Andy 20
```

以前要先寫 `age := 20`，再寫 `Age: &age`。有了 `new(expr)`，一行就能寫完。至於「沒填」要怎麼表示，下一集介紹 `nil` 時就會看到。

## 重點整理

- `new(型別)` 建立一個指向該型別零值的指標，例如 `new(int)` 指向 `0`。
- 從 Go 1.26 起，`new(值)` 建立一個指向該值複本的指標，例如 `new(42)` 是 `*int`，指向 `42`。
- 指標型別由值的型別決定，需要別的型別就先轉換，例如 `new(int64(5))`。
- struct 的指標還是常寫成 `&型別{...}`；`new(值)` 適合在 literal 裡直接填指標欄位。
