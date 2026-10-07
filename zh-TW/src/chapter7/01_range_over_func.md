# range over func

## 本集目標

知道 `for range` 除了切片和 map 之外，還能走訪一個「函式」，並看懂這種函式長什麼樣子。

## 正文

### 先看一個例子

```go
package main

import "fmt"

func oneTwoThree(yield func(int) bool) {
	yield(1)
	yield(2)
	yield(3)
}

func main() {
	for n := range oneTwoThree {
		fmt.Println("拿到", n)
	}
}
```

執行結果：

```text
拿到 1
拿到 2
拿到 3
```

`range` 後面放的不是切片，而是函式 `oneTwoThree` 本身（注意沒有加小括號，我們把函式當成值交給 `range`）。

### 背後發生了什麼事

`oneTwoThree` 有一個參數叫 `yield`，它的型別是 `func(int) bool`，也就是「收一個 `int`、回傳 `bool` 的函式」。

當 Go 執行 `for n := range oneTwoThree` 時，會做這幾件事：

1. 把迴圈的身體（大括號裡的程式碼）包裝成一個函式，當作 `yield` 傳給 `oneTwoThree`。
2. `oneTwoThree` 每呼叫一次 `yield(值)`，迴圈身體就執行一次，`n` 就是那個值。
3. `oneTwoThree` 執行完畢回傳，迴圈就結束。

所以 `yield` 這個名字很貼切：英文有「交出」的意思，函式每交出一個值，迴圈就處理一個。`yield` 只是慣用的參數名稱，不是關鍵字，但大家都這樣取，我們也照做。

### 用迴圈交出值

交出的值不一定要一個一個寫死。下面的函式交出 1 到 5 的平方：

```go
package main

import "fmt"

func squares(yield func(int) bool) {
	for i := 1; i <= 5; i++ {
		if !yield(i * i) {
			return
		}
	}
}

func main() {
	for n := range squares {
		fmt.Println(n)
	}
}
```

執行結果：

```text
1
4
9
16
25
```

這次我們檢查了 `yield` 的回傳值：`yield` 回傳 `false` 時就 `return`。這代表「迴圈那邊不想再要了」，例如迴圈裡寫了 `break`。第 4 集會詳細說明為什麼一定要這樣寫；從現在開始，我們寫的每個迭代器都會照這個樣子檢查。

### 能被 range 的函式形狀

`for range` 接受三種形狀的函式：

| 函式形狀 | `for range` 的寫法 |
| --- | --- |
| `func(yield func() bool)` | `for range f { ... }` |
| `func(yield func(V) bool)` | `for v := range f { ... }` |
| `func(yield func(K, V) bool)` | `for k, v := range f { ... }` |

`V`、`K` 代表任何型別。最常用的是第二種，一次交出一個值；第三種一次交出兩個值，第 3 集會用到。

## 重點整理

- `for range` 可以走訪形狀像 `func(yield func(V) bool)` 的函式，這種函式就是迭代器。
- 迭代器每呼叫一次 `yield(值)`，迴圈身體就執行一次；迭代器回傳時迴圈結束。
- `yield` 回傳 `false` 代表迴圈不想再繼續了，迭代器應該立刻 `return`。
- 交出零個、一個、兩個值的形狀都可以被 `range`。
