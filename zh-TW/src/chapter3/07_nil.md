# `nil`

## 本集目標

知道指標的零值是 `nil`，學會檢查 `nil`，並看看對 `nil` 解參考會發生什麼事。

## 正文

每個型別都有零值。指標也不例外，它的零值叫做 `nil`，意思是「沒有指向任何東西」。

### 指標的零值

```go
package main

import "fmt"

func main() {
	var p *int
	fmt.Println(p)
	fmt.Println(p == nil)

	x := 5
	p = &x
	fmt.Println(p == nil)
}
```

執行結果：

```text
<nil>
true
false
```

`var p *int` 宣告了指標卻沒給它位址，所以 `p` 是 `nil`。`fmt.Println` 印 `nil` 指標時會印出 `<nil>`。指標可以用 `==`、`!=` 和 `nil` 比較。

### 對 `nil` 解參考會 panic

`nil` 指標沒有指向任何值，如果硬要用 `*p` 去讀，程式會當場停下來：

```go,exit=2
package main

import "fmt"

func main() {
	var p *int
	fmt.Println("準備讀取")
	fmt.Println(*p)
	fmt.Println("這行不會執行")
}
```

執行結果：

```text
準備讀取
panic: runtime error: invalid memory address or nil pointer dereference
```

`panic: ...` 下面還會有幾行，標出出錯的檔案和行號，這裡省略。這種程式突然停止的狀況叫做 **panic**，程式會以結束碼 2 結束，第 5 章會正式介紹。現在只要記住：**對 `nil` 指標解參考、或透過 `nil` 的 struct 指標讀寫欄位，都會 panic**。

### 用之前先檢查

只要指標有可能是 `nil`，使用前就先檢查。延續上一集的 `Profile`，我們用 `nil` 表示「年齡沒填」：

```go
package main

import "fmt"

type Profile struct {
	Name string
	Age  *int
}

func show(p Profile) {
	if p.Age == nil {
		fmt.Println(p.Name, "沒有填年齡")
		return
	}
	fmt.Println(p.Name, "今年", *p.Age, "歲")
}

func main() {
	show(Profile{Name: "Andy", Age: new(20)})
	show(Profile{Name: "Betty"})
}
```

執行結果：

```text
Andy 今年 20 歲
Betty 沒有填年齡
```

`Betty` 的 `Age` 沒寫，所以是零值 `nil`。`show` 先檢查 `nil`，就不會 panic 了。

### 其他也會是 `nil` 的東西

`nil` 不只屬於指標。第 2 章學過，宣告了卻沒初始化的切片和 map 也是 `nil`：

```go
package main

import "fmt"

func main() {
	var s []int
	var m map[string]int
	fmt.Println(s == nil, m == nil)
	fmt.Println(len(s), len(m))
}
```

執行結果：

```text
true true
0 0
```

`nil` 切片和 `nil` map 可以安全地讀取長度、用 `for range` 走訪（一次都不會跑），但對 `nil` map 寫入會 panic。之後學到的介面，零值也是 `nil`。

## 重點整理

- 指標的零值是 `nil`，表示沒有指向任何東西；`fmt` 印出來是 `<nil>`。
- 可以用 `p == nil`、`p != nil` 檢查指標。
- 對 `nil` 指標解參考會 panic，程式以結束碼 2 結束。
- 指標可能是 `nil` 時，使用前先檢查；切片、map 的零值也是 `nil`。
