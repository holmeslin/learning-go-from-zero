# 指向 struct 的指標

## 本集目標

用指標讓函式改掉原本 struct 的欄位，並知道透過指標讀欄位時不用寫 `*`。

## 正文

struct 也是值。把 struct 傳給函式時，會複製每個欄位的值：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func birthday(p Person) {
	p.Age++
}

func main() {
	andy := Person{Name: "Andy", Age: 20}
	birthday(andy)
	fmt.Println(andy.Age)
}
```

執行結果：

```text
20
```

生日過了，年齡卻沒變。`birthday` 改的是複本。

### 傳 struct 的指標

照上一集的做法，參數改成 `*Person`，呼叫時傳 `&andy`：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func birthday(p *Person) {
	p.Age++
}

func main() {
	andy := Person{Name: "Andy", Age: 20}
	birthday(&andy)
	fmt.Println(andy.Age)
}
```

執行結果：

```text
21
```

注意函式裡寫的是 `p.Age++`，不是 `(*p).Age++`。照理說要先用 `*p` 找到 struct，再取 `.Age`。但這樣寫太麻煩了，所以 Go 讓你直接在指標後面寫 `.欄位`，它會自動幫你解參考。`p.Age` 和 `(*p).Age` 完全一樣，大家都寫 `p.Age`。

### 直接取 literal 的位址

如果一開始就打算用指標，可以在 struct literal 前面加 `&`：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	p := &Person{Name: "Betty", Age: 25}
	p.Age = 26
	fmt.Println(p.Name, p.Age)
	fmt.Printf("%+v\n", p)
}
```

執行結果：

```text
Betty 26
&{Name:Betty Age:26}
```

`p` 的型別是 `*Person`。用 `fmt` 印 struct 的指標時，前面會多一個 `&`，提醒你這是指標。

`&` 通常只能放在變數前面，不能寫 `&10` 這種東西。struct literal 是特別允許的例外，這個寫法非常常見。

### 複製 vs 共用

兩個變數拿到同一個指標，改其中一個，另一個也看得到：

```go
package main

import "fmt"

type Person struct {
	Name string
	Age  int
}

func main() {
	a := Person{Name: "Andy", Age: 20}
	b := a
	b.Age = 99
	fmt.Println(a.Age, b.Age)

	p := &a
	q := p
	q.Age = 50
	fmt.Println(a.Age, p.Age, q.Age)
}
```

執行結果：

```text
20 99
50 50 50
```

`b := a` 複製了每個欄位的值。這裡的欄位是字串和整數，所以改 `b.Age` 不會改到 `a.Age`。`q := p` 只複製了位址，`p`、`q` 都指向 `a`。

這不是**深複製**：如果欄位是切片、map 或指標，複製的是切片的描述資料、map 值或位址，不會連底層資料一起複製。兩份 struct 仍可能共用那些資料；例如透過副本修改切片元素，原本的 struct 也看得到。

## 重點整理

- struct 是值，傳給函式或賦值時會複製各欄位的值，不是深複製；切片、map、指標欄位仍可能共用底層資料。
- 想讓函式改掉原本 struct 的欄位，參數用 `*型別`，呼叫時傳 `&變數`。
- 透過指標存取欄位可以直接寫 `p.欄位`，Go 會自動解參考。
- `&型別{...}` 可以直接建立 struct 並取得它的指標；`fmt` 印出來前面會有 `&`。
