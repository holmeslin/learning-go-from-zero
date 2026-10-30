# 方法集合：指標接收者與介面

## 本集目標

理解為什麼型別只有指標接收者方法時，要用指標才能放進介面，並看懂對應的編譯錯誤。

## 正文

第 3 章學過，呼叫方法時 Go 會自動幫你取址，所以值和指標都能呼叫指標接收者的方法。但放進介面時，這個方便就不成立了。

### 一個會失敗的例子

```go,compile_fail
package main

import "fmt"

type Incrementer interface {
	Inc()
}

type Counter struct {
	Count int
}

func (c *Counter) Inc() {
	c.Count++
}

func main() {
	c := Counter{}
	var i Incrementer = c
	i.Inc()
	fmt.Println(c.Count)
}
```

編譯錯誤：

```text
cannot use c (variable of struct type Counter) as Incrementer value in variable declaration: Counter does not implement Incrementer (method Inc has pointer receiver)
```

明明 `c.Inc()` 可以直接呼叫，為什麼 `Counter` 不算實作了 `Incrementer`？錯誤訊息的最後一段說得很清楚：`Inc` 是指標接收者。

### 方法集合

每個型別都有一份「方法清單」，叫做**方法集合**（method set）。判斷型別有沒有實作介面時，看的就是這份清單：

| 型別 | 方法集合包含 |
| --- | --- |
| `Counter` | 值接收者的方法 |
| `*Counter` | 值接收者的方法 **和** 指標接收者的方法 |

`Inc` 是指標接收者，所以只在 `*Counter` 的清單裡，不在 `Counter` 的清單裡。因此 `*Counter` 實作了 `Incrementer`，`Counter` 沒有。

### 改用指標就好

把 `&c` 放進介面：

```go
package main

import "fmt"

type Incrementer interface {
	Inc()
}

type Counter struct {
	Count int
}

func (c *Counter) Inc() {
	c.Count++
}

func main() {
	c := Counter{}
	var i Incrementer = &c
	i.Inc()
	i.Inc()
	fmt.Println(c.Count)
}
```

執行結果：

```text
2
```

`i` 裡面裝的是 `c` 的位址，透過 `i.Inc()` 改到的就是 `c` 本身。

### 為什麼要這樣規定？

想像一下，如果 Go 允許把 `Counter` 的值放進 `Incrementer`：存進去的會是值的**複本**，不是原本變數 `c`。在這個只有整數欄位的例子裡，就算能修改介面裡那份 `Count`，也不會改到原本的 `c.Count`。

第 3 章第 10 集提過，自動取址的條件是「要能取得位址」。介面裡的那份複本不能自動取址，所以不會因為放進介面，就替 `Counter` 補上指標接收者的方法。要使用 `Inc`，必須明確地傳指標進去。

反過來，如果介面要求的方法都是值接收者的方法，值和指標的方法集合都包含它們，所以兩者都能放進介面。這不代表值接收者「不會改資料」：如果欄位是切片、map 或指標，副本仍可能指向共用資料，方法也可能修改那些內容。

### 實際寫程式時

記住一個簡單的原則就好：**如果型別的方法用了指標接收者，就把指標放進介面**。通常建立的時候就直接用 `&Counter{}`：

```go
package main

import "fmt"

type Incrementer interface {
	Inc()
}

type Counter struct {
	Count int
}

func (c *Counter) Inc() {
	c.Count++
}

func addThree(i Incrementer) {
	i.Inc()
	i.Inc()
	i.Inc()
}

func main() {
	c := &Counter{}
	addThree(c)
	fmt.Println(c.Count)
}
```

執行結果：

```text
3
```

## 重點整理

- 判斷型別是否實作介面，看的是它的方法集合。
- `T` 的方法集合只有值接收者的方法；`*T` 的方法集合包含值接收者和指標接收者的方法。
- 型別只用指標接收者實作介面方法時，`*T` 實作了介面，`T` 沒有，編譯錯誤會寫 `method ... has pointer receiver`。
- 方法用了指標接收者，就把指標（例如 `&c`、`&Counter{}`）放進介面。
- 值接收者也可能修改欄位指向的共用資料；方法集合不是資料是否共用的保證。
