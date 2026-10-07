# 閉包

## 本集目標

知道匿名函式可以使用、甚至修改外面的變數（閉包），並用它做出「會記住狀態」的函式。

## 正文

### 使用外面的變數

匿名函式寫在另一個函式裡面，所以它看得到外面的變數：

```go
package main

import "fmt"

func main() {
	greeting := "哈囉"
	say := func(name string) {
		fmt.Println(greeting + "，" + name)
	}
	say("小明")

	greeting = "早安"
	say("小美")
}
```

執行結果：

```text
哈囉，小明
早安，小美
```

`say` 裡面用到了外面的 `greeting`。注意第二次呼叫時印出「早安」：匿名函式抓住的是**變數本身**，不是當初的值，所以外面改了，裡面看到的也跟著變。

這種「把外面的變數一起帶著走」的函式，叫做**閉包**（closure）。

### 修改外面的變數

閉包不只能讀，還能改：

```go
package main

import "fmt"

func main() {
	total := 0
	addScore := func(n int) {
		total += n
	}
	addScore(10)
	addScore(25)
	fmt.Println(total)
}
```

執行結果：

```text
35
```

### 會記住狀態的函式

閉包最有趣的用法，是讓函式回傳一個閉包：

```go
package main

import "fmt"

func makeCounter() func() int {
	count := 0
	return func() int {
		count++
		return count
	}
}

func main() {
	next := makeCounter()
	fmt.Println(next())
	fmt.Println(next())
	fmt.Println(next())

	other := makeCounter()
	fmt.Println(other())
	fmt.Println(next())
}
```

執行結果：

```text
1
2
3
1
4
```

一步一步看：

- `makeCounter` 的回傳型別是 `func() int`，也就是「一個不收參數、回傳 `int` 的函式」。
- 每次呼叫 `makeCounter`，都會建立一個新的 `count` 變數，再回傳一個抓住這個 `count` 的匿名函式。
- `makeCounter` 已經結束了，但 `count` 沒有消失，因為閉包還在用它。每次呼叫 `next()`，同一個 `count` 就加 1。
- `other` 是另一次呼叫 `makeCounter` 得到的，它有**自己的** `count`，跟 `next` 互不影響。

這就像每個閉包都背著一個自己的小背包，裡面裝著它需要的變數。

### 閉包當成產生器

再看一個例子：做一個依序產生費氏數列的函式。

```go
package main

import "fmt"

func fibonacci() func() int {
	a, b := 0, 1
	return func() int {
		result := a
		a, b = b, a+b
		return result
	}
}

func main() {
	next := fibonacci()
	for range 8 {
		fmt.Print(next(), " ")
	}
	fmt.Println()
}
```

執行結果：

```text
0 1 1 2 3 5 8 13 
```

`a` 和 `b` 被閉包抓住，每次呼叫都從上次停下來的地方繼續。這裡用了第 2 章的多重賦值 `a, b = b, a+b`。

## 重點整理

- 閉包是用到外面變數的匿名函式，它抓住的是變數本身，不是複製一份值。
- 閉包可以讀取也可以修改外面的變數。
- 函式可以回傳閉包；被抓住的變數會一直存在，即使外層函式已經結束。
- 每次建立閉包都會有各自的變數，彼此互不影響。
