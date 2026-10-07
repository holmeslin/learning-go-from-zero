# 迴圈變數與閉包

## 本集目標

知道在迴圈裡建立閉包時，每一次迭代都有自己的一份迴圈變數，所以每個閉包會記住各自那一輪的值。

## 正文

上一集學到：閉包抓住的是**變數本身**，不是當下的值。那如果在迴圈裡建立閉包，抓住迴圈變數，會發生什麼事？

### 每一輪各有一份

```go
package main

import "fmt"

func main() {
	var printers []func()
	for i := range 3 {
		printers = append(printers, func() {
			fmt.Println("我是第", i, "個")
		})
	}

	for _, p := range printers {
		p()
	}
}
```

執行結果：

```text
我是第 0 個
我是第 1 個
我是第 2 個
```

我們先在迴圈裡做了三個閉包，存進 `[]func()` 切片，等迴圈全部跑完才一個一個呼叫。每個閉包印出的都是它被建立那一輪的 `i`。

原因是：Go 的 `for` 迴圈**每一次迭代都會建立一個新的迴圈變數**。第一輪的 `i` 和第二輪的 `i` 雖然名字一樣，其實是不同的變數，每個閉包抓住的是自己那一輪的 `i`。

### 三段式 `for` 和走訪切片也一樣

不只是 `for range` 整數，三段式 `for` 和 `for range` 走訪切片都是這樣：

```go
package main

import "fmt"

func main() {
	var actions []func()

	for i := 0; i < 2; i++ {
		actions = append(actions, func() {
			fmt.Println("i =", i)
		})
	}

	fruits := []string{"蘋果", "香蕉"}
	for _, f := range fruits {
		actions = append(actions, func() {
			fmt.Println("水果：", f)
		})
	}

	for _, a := range actions {
		a()
	}
}
```

執行結果：

```text
i = 0
i = 1
水果： 蘋果
水果： 香蕉
```

### 迴圈外的變數就是同一份

要注意的是，「每輪一份」只適用於 `for` 那一行宣告的迴圈變數。如果閉包抓的是迴圈外面宣告的變數，大家抓到的就是同一個：

```go
package main

import "fmt"

func main() {
	var printers []func()
	n := 0
	for range 3 {
		n++
		printers = append(printers, func() {
			fmt.Println("n =", n)
		})
	}

	for _, p := range printers {
		p()
	}
}
```

執行結果：

```text
n = 3
n = 3
n = 3
```

`n` 只有一個，三個閉包都抓住它。等到呼叫時，`n` 已經是 3 了，所以三次都印出 3。這就是上一集「抓住變數本身」的規則，並不是什麼特例。

### 舊文章的提醒

這個「每輪一份」的行為是 Go 1.22 開始的。舊版 Go（1.21 以前）整個迴圈共用同一個迴圈變數，所以網路上的舊文章可能還在警告「閉包會全部拿到最後一個值」，並教你先寫 `i := i` 複製一份。在現在的 Go 裡不需要這樣做。

## 重點整理

- `for` 迴圈每一次迭代都會建立新的迴圈變數。
- 在迴圈裡建立的閉包，會記住各自那一輪的迴圈變數。
- 三段式 `for`、`for range` 整數、`for range` 切片都適用。
- 閉包抓的若是迴圈外宣告的變數，所有閉包共用同一個。
