# 遞迴

## 本集目標

認識「遞迴」：函式在自己裡面呼叫自己。

## 正文

函式可以呼叫別的函式，那可不可以呼叫**自己**？可以，這叫做**遞迴**（recursion）。

### 倒數

先看一個簡單的例子：

```go
package main

import "fmt"

func countdown(n int) {
	if n == 0 {
		fmt.Println("發射！")
		return
	}
	fmt.Println(n)
	countdown(n - 1)
}

func main() {
	countdown(3)
}
```

執行結果：

```text
3
2
1
發射！
```

一步一步看：

1. `countdown(3)`：3 不是 0，印出 3，然後呼叫 `countdown(2)`。
2. `countdown(2)`：印出 2，呼叫 `countdown(1)`。
3. `countdown(1)`：印出 1，呼叫 `countdown(0)`。
4. `countdown(0)`：n 是 0，印出「發射！」然後 `return`，不再呼叫自己。

### 兩個必要的部分

寫遞迴時，一定要有這兩樣東西：

- **終止條件**：什麼時候停下來，不再呼叫自己。上面的 `if n == 0`。
- **往終點靠近**：每次呼叫自己時，問題都要變小一點。上面的 `n - 1`。

少了任何一個，函式就會無止盡地呼叫自己，直到記憶體用完、程式當掉。

### 階乘

數學上的階乘：5! = 5 × 4 × 3 × 2 × 1。換個角度想，5! 就是 5 × 4!，而 4! 又是 4 × 3!……一直到 1! 等於 1。這種「大問題可以用小一號的同樣問題來表示」的情況，很適合用遞迴：

```go
package main

import "fmt"

func factorial(n int) int {
	if n <= 1 {
		return 1
	}
	return n * factorial(n-1)
}

func main() {
	fmt.Println(factorial(5))
}
```

執行結果：

```text
120
```

`factorial(5)` 要等 `factorial(4)` 算好，`factorial(4)` 又要等 `factorial(3)`……一路等到 `factorial(1)` 直接回傳 1，答案再一層一層傳回來：1 → 2 → 6 → 24 → 120。

### 遞迴還是迴圈？

同樣的階乘，用 `for` 也寫得出來：

```go
package main

import "fmt"

func factorial(n int) int {
	result := 1
	for i := 2; i <= n; i++ {
		result *= i
	}
	return result
}

func main() {
	fmt.Println(factorial(5))
}
```

執行結果：

```text
120
```

在 Go 裡，簡單的重複工作通常用迴圈就好，比較直接，也不用擔心呼叫太多層。遞迴適合「問題本身就是一層包一層」的情況，例如之後會遇到的樹狀資料、資料夾裡面還有資料夾。現在先理解它的運作方式就夠了。

## 重點整理

- 遞迴是函式呼叫自己。
- 遞迴一定要有終止條件，而且每次呼叫都要讓問題變小，否則會無止盡地呼叫下去。
- 適合「大問題可以拆成小一號的同樣問題」的情況，例如階乘。
- 簡單的重複工作，Go 通常直接用迴圈。
