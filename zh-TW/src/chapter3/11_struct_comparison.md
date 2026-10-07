# struct 比較

## 本集目標

用 `==` 比較兩個 struct，知道哪些 struct 不能比較，以及 struct 可以當 map 的 key。

## 正文

### 用 `==` 比較 struct

兩個同型別的 struct，可以直接用 `==` 和 `!=` 比較：

```go
package main

import "fmt"

type Point struct {
	X int
	Y int
}

func main() {
	a := Point{X: 1, Y: 2}
	b := Point{X: 1, Y: 2}
	c := Point{X: 3, Y: 2}
	fmt.Println(a == b)
	fmt.Println(a == c)
	fmt.Println(a != c)
}
```

執行結果：

```text
true
false
true
```

規則很直覺：**所有欄位都相等**，兩個 struct 才相等。`a` 和 `b` 的 `X`、`Y` 都一樣，所以 `a == b` 是 `true`；`a` 和 `c` 的 `X` 不同，所以是 `false`。

拿零值比較也很常用，例如 `p == Point{}` 可以檢查 `p` 是不是還沒設定過。

### 比較指標，比的是位址

如果比較的是兩個指標，比的是「是不是指向同一個地方」，不是裡面的內容：

```go
package main

import "fmt"

type Point struct {
	X int
	Y int
}

func main() {
	p := &Point{X: 1, Y: 2}
	q := &Point{X: 1, Y: 2}
	r := p
	fmt.Println(p == q)
	fmt.Println(p == r)
	fmt.Println(*p == *q)
}
```

執行結果：

```text
false
true
true
```

`p` 和 `q` 內容一樣，但各自指向不同的 struct，所以 `p == q` 是 `false`。想比內容，就要先解參考：`*p == *q`。

### 有些 struct 不能比較

第 2 章提過，切片和 map 不能用 `==` 互相比較。只要 struct 裡有這種欄位，整個 struct 就不能比較：

```go,compile_fail
package main

import "fmt"

type Team struct {
	Name    string
	Members []string
}

func main() {
	a := Team{Name: "A"}
	b := Team{Name: "A"}
	fmt.Println(a == b)
}
```

編譯錯誤：

```text
invalid operation: a == b (struct containing []string cannot be compared)
```

這是在編譯時就會擋下來的錯誤，不用擔心程式跑到一半才出事。這種情況只能自己寫函式，一個一個欄位比較。

### struct 當 map 的 key

可以比較的 struct，就能當 map 的 key。例如用座標當 key，記錄棋盤上每一格放了什麼：

```go
package main

import "fmt"

type Point struct {
	X int
	Y int
}

func main() {
	board := map[Point]string{}
	board[Point{X: 0, Y: 0}] = "黑"
	board[Point{X: 1, Y: 2}] = "白"

	fmt.Println(board[Point{X: 1, Y: 2}])
	if _, ok := board[Point{X: 5, Y: 5}]; !ok {
		fmt.Println("(5, 5) 是空的")
	}
}
```

執行結果：

```text
白
(5, 5) 是空的
```

不用再把座標拼成 `"1,2"` 這種字串當 key，程式清楚很多。

## 重點整理

- 同型別的 struct 可以用 `==`、`!=` 比較，所有欄位都相等才算相等。
- 比較兩個指標，比的是位址；想比內容要先解參考。
- 含有切片、map 欄位的 struct 不能比較，編譯時就會報錯。
- 可以比較的 struct 能當 map 的 key。
