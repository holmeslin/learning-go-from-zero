# 值接收者 vs 指標接收者

## 本集目標

分辨值接收者和指標接收者，知道想在方法裡改掉原本 struct 的欄位時要用指標接收者，以及 Go 在呼叫時幫你做的自動轉換。

## 正文

上一集的方法都只「讀」資料。如果方法要「改」資料呢？

### 值接收者改的是副本的欄位

```go
package main

import "fmt"

type Counter struct {
	Count int
}

func (c Counter) Inc() {
	c.Count++
}

func main() {
	var c Counter
	c.Inc()
	c.Inc()
	fmt.Println(c.Count)
}
```

執行結果：

```text
0
```

呼叫了兩次 `Inc`，結果還是 0。原因跟第 4 集一樣：`(c Counter)` 這種接收者叫做**值接收者**，呼叫方法時，Go 會把 `c` **複製**一份交給方法，方法改的是複本。

這裡的 `Count` 是整數，所以改副本的欄位不會改到原本的欄位。但值複製不會一路複製欄位指向的資料。如果 struct 有切片、map 或指標欄位，值接收者仍可以修改共用的切片元素、map 項目或指標指向的值。第 5 集提過的共用情況，在方法裡也一樣。

### 指標接收者

把接收者改成指標 `(c *Counter)`，就叫做**指標接收者**：

```go
package main

import "fmt"

type Counter struct {
	Count int
}

func (c *Counter) Inc() {
	c.Count++
}

func main() {
	var c Counter
	c.Inc()
	c.Inc()
	fmt.Println(c.Count)
}
```

執行結果：

```text
2
```

這次方法拿到的是 `c` 的位址，`c.Count++` 透過指標改到了原本的 `c`（第 5 集學過，透過指標存取欄位不用寫 `*`）。

### Go 幫你自動取址

你可能注意到了：`Inc` 要的是 `*Counter`，但我們呼叫時寫的是 `c.Inc()`，`c` 明明是 `Counter`，不是指標。

這是 Go 幫的忙。當變數 `c` 呼叫指標接收者的方法時，Go 會自動把 `c.Inc()` 當成 `(&c).Inc()`。所以你不用自己寫 `&`。

反過來也一樣。如果手上是指標，呼叫值接收者的方法時，Go 會自動解參考：

```go
package main

import "fmt"

type Counter struct {
	Count int
}

func (c *Counter) Inc() {
	c.Count++
}

func (c Counter) Show() {
	fmt.Println("目前是", c.Count)
}

func main() {
	var c Counter
	c.Inc()  // 自動變成 (&c).Inc()
	c.Show() // 值接收者，直接呼叫

	p := &Counter{Count: 10}
	p.Inc()  // 指標接收者，直接呼叫
	p.Show() // 自動變成 (*p).Show()
}
```

執行結果：

```text
目前是 1
目前是 11
```

所以不管手上是值還是指標，寫法都是 `x.方法()`，Go 會自動處理。

自動取址有一個條件：Go 要能取得那個值的位址，也就是要是變數這種「有地方存放」的東西。第 4 章學介面時，會遇到這個條件不成立的情況。

### 該用哪一種？

幾個簡單的判斷原則：

- 方法要**改掉原本 struct 的欄位** → 用指標接收者。若只是修改欄位指向的共用資料，值接收者也可能做得到。
- struct 很大，不想每次呼叫都複製一份 → 用指標接收者。
- 其他情況（小型、只讀的資料，例如 `Celsius`）→ 值接收者就好。

另外有個慣例：**同一個型別的方法，最好統一用同一種接收者**。只要有一個方法需要指標接收者，通常其他方法也一起用指標接收者，這樣讀程式的人比較不會混亂。上面的範例混用只是為了示範。

## 重點整理

- 值接收者 `(c Counter)` 拿到的是複本，改副本的欄位不會改到原本的欄位，但仍可能修改欄位指向的共用資料。
- 指標接收者 `(c *Counter)` 拿到的是位址，可以修改原本的值。
- 用變數呼叫指標接收者方法時，Go 自動取址；用指標呼叫值接收者方法時，Go 自動解參考。
- 要改掉原本 struct 的欄位就用指標接收者，同一個型別的方法盡量統一接收者種類。
