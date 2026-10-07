# 提早結束

## 本集目標

了解迴圈裡的 `break`、`return` 怎麼讓迭代器停下來，以及為什麼迭代器在 `yield` 回傳 `false` 之後一定要停。

## 正文

### `break` 時發生什麼事

我們在迭代器裡多印一些訊息，看看 `break` 的時候，迭代器那邊看到了什麼：

```go
package main

import (
	"fmt"
	"iter"
)

func numbers() iter.Seq[int] {
	return func(yield func(int) bool) {
		for i := 1; i <= 5; i++ {
			fmt.Println("交出", i)
			if !yield(i) {
				fmt.Println("迴圈不要了，停止")
				return
			}
		}
		fmt.Println("全部交完了")
	}
}

func main() {
	for n := range numbers() {
		fmt.Println("拿到", n)
		if n == 2 {
			break
		}
	}
	fmt.Println("迴圈結束")
}
```

執行結果：

```text
交出 1
拿到 1
交出 2
拿到 2
迴圈不要了，停止
迴圈結束
```

迴圈身體執行到 `break` 時，Go 讓那次的 `yield(2)` 回傳 `false`。迭代器看到 `false`，印出訊息後 `return`，迴圈才真正結束。如果沒有 `break`，每次 `yield` 都回傳 `true`，最後會印出「全部交完了」。

在迴圈裡寫 `return` 也一樣：`yield` 會回傳 `false`，迭代器停下來之後，外面的函式才回傳。

### 不停下來會怎樣

如果迭代器忽略 `yield` 的回傳值，在 `break` 之後還繼續呼叫 `yield`，會發生什麼事？

```go,exit=2
package main

import (
	"fmt"
	"iter"
)

func stubborn() iter.Seq[int] {
	return func(yield func(int) bool) {
		yield(1)
		yield(2)
		yield(3)
	}
}

func main() {
	for n := range stubborn() {
		fmt.Println(n)
		break
	}
}
```

執行結果（只列出前幾行）：

```text
1
panic: runtime error: range function continued iteration after function for loop body returned false
```

程式直接 `panic` 了。迴圈已經 `break`，Go 不可能再回頭執行迴圈身體，所以只能用 `panic` 告訴你：這個迭代器寫錯了。

第 1 集的 `oneTwoThree` 也沒檢查 `yield` 的回傳值，只要沒人 `break` 就不會出事，但那只是運氣好。寫迭代器時請一律寫成這樣：

```go,ignore
if !yield(v) {
	return
}
```

### 停下來之前可以收拾

迭代器 `return` 之前還有機會做收尾工作，例如印出訊息或釋放資源。第 5 章學過的 `defer` 在這裡很好用，不管是正常走完還是提早結束，都會執行：

```go
package main

import (
	"fmt"
	"iter"
)

func lines() iter.Seq[string] {
	return func(yield func(string) bool) {
		fmt.Println("打開檔案")
		defer fmt.Println("關閉檔案")
		for _, s := range []string{"第一行", "第二行", "第三行"} {
			if !yield(s) {
				return
			}
		}
	}
}

func main() {
	for s := range lines() {
		fmt.Println(s)
		if s == "第二行" {
			break
		}
	}
}
```

執行結果：

```text
打開檔案
第一行
第二行
關閉檔案
```

這裡沒有真的打開檔案，只是用印出的文字模擬。重點是 `break` 之後，「關閉檔案」依然會被執行。

## 重點整理

- 迴圈裡 `break` 或 `return` 時，當次的 `yield` 會回傳 `false`。
- 迭代器看到 `yield` 回傳 `false` 必須立刻停止；繼續呼叫 `yield` 會 `panic`。
- 固定寫法是 `if !yield(v) { return }`。
- 迭代器裡可以用 `defer` 做收尾，提早結束時也會執行。
