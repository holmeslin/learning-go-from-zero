# 指向 struct 的指標

## 本集目標

用指標讓函式修改 struct，並知道透過指標讀欄位時不用寫 `*`。

## 正文

struct 也是值。把 struct 傳給函式時，一樣會整個複製一份：

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

`b := a` 複製了整個 struct，`a` 和 `b` 是兩份各自獨立的資料。`q := p` 只複製了位址，`p`、`q` 都指向 `a`。

## 重點整理

- struct 是值，傳給函式或賦值給另一個變數時會整個複製。
- 想讓函式修改 struct，參數用 `*型別`，呼叫時傳 `&變數`。
- 透過指標存取欄位可以直接寫 `p.欄位`，Go 會自動解參考。
- `&型別{...}` 可以直接建立 struct 並取得它的指標；`fmt` 印出來前面會有 `&`。
