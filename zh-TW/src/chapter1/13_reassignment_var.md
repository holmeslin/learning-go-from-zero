# 重新賦值與 `var`

## 本集目標

學會修改變數的值，分清楚 `=` 和 `:=`，並認識另一種建立變數的方式 `var`。

## 正文

### 用 `=` 改變變數的值

變數之所以叫「變」數，就是因為裡面的值可以改。建立之後，用一個等號 `=` 就能放進新的值：

```go
package main

import "fmt"

func main() {
	score := 60
	fmt.Println(score)
	score = 85
	fmt.Println(score)
}
```

執行結果：

```text
60
85
```

把新的值放進已經存在的變數，叫做**重新賦值**。舊的值 60 會被換掉。

新的值也可以用變數自己算出來：

```go
package main

import "fmt"

func main() {
	money := 100
	money = money - 30
	fmt.Println(money)
}
```

執行結果：

```text
70
```

`money = money - 30` 在數學上看起來很奇怪，但在程式裡要這樣讀：**先算右邊**（`money - 30` 是 70），**再把結果放進左邊**的 `money`。`=` 不是「等於」，而是「放進去」。

### `:=` 和 `=` 的差別

- `:=`：**建立**一個新變數，並放入值。
- `=`：把新的值放進一個**已經存在**的變數。

所以同一個變數不能 `:=` 兩次：

```go,compile_fail
package main

import "fmt"

func main() {
	score := 60
	score := 85
	fmt.Println(score)
}
```

```text
./main.go:7:8: no new variables on left side of :=
```

錯誤訊息的意思是「`:=` 左邊沒有新的變數」。`score` 已經建立過了，要改值請用 `=`。

反過來，對還沒建立的變數用 `=` 也不行，會得到上一集看過的 `undefined` 錯誤。

### 用 `var` 建立變數

建立變數還有另一種寫法：

```go
package main

import "fmt"

func main() {
	var count int
	fmt.Println(count)
	count = 3
	fmt.Println(count)
}
```

執行結果：

```text
0
3
```

`var count int` 的意思是：建立一個叫 `count` 的變數，它裝的是 `int`（整數）。這樣寫的時候可以先不給值，Go 會自動放一個 0 進去。`int` 這種「資料的種類」叫做**型別**，第 24 集會正式介紹；「自動放進去的值」叫做零值，第 26 集會介紹。

如果一開始就知道要放什麼值，大多數時候用 `:=` 比較簡潔。`var` 適合用在「先建立，等一下才決定值」的情況。

### 建立了變數就一定要用

Go 有一條很嚴格的規矩：在函式裡建立了變數卻沒有用到，程式會**無法編譯**。

```go,compile_fail
package main

import "fmt"

func main() {
	name := "小明"
	age := 18
	fmt.Println(name)
}
```

```text
./main.go:7:2: declared and not used: age
```

`age` 建立了，但從來沒被使用。只寫 `age = 20` 也不算使用，必須真的讀取它的值，例如把它印出來或拿去計算。

這條規矩一開始可能覺得煩，但它能幫你抓出「打錯變數名稱」或「忘記刪掉的程式碼」這類錯誤。

## 重點整理

- `=` 把新的值放進已經存在的變數；先算右邊，再放進左邊。
- `:=` 建立新變數；同一個變數不能 `:=` 兩次。
- `var 名稱 型別` 也能建立變數，沒給值時會自動是 0 這類的預設值。
- 建立了變數卻沒有使用，程式會無法編譯（`declared and not used`）。
