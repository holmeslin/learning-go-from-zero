# nil 介面陷阱

## 本集目標

認識 Go 最常見的介面陷阱：裝了 `nil` 指標的介面不等於 `nil`，並學會避開它。

## 正文

第 4 集說過：**只有當型別和值兩格都是空的，介面才等於 `nil`。** 這一集來看看這句話會造成什麼問題。

### 一個看起來沒問題的程式

假設我們寫一個函式，依照名字找形狀，找不到就回傳 `nil`：

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Rect struct {
	Width  float64
	Height float64
}

func (r *Rect) Area() float64 {
	return r.Width * r.Height
}

func findRect(name string) *Rect {
	if name == "big" {
		return &Rect{Width: 10, Height: 10}
	}
	return nil
}

func find(name string) Shape {
	r := findRect(name)
	return r
}

func main() {
	s := find("small")
	if s == nil {
		fmt.Println("找不到")
		return
	}
	fmt.Println("找到了")
	fmt.Printf("%T %v\n", s, s)
}
```

執行結果：

```text
找到了
*main.Rect <nil>
```

`findRect("small")` 明明回傳了 `nil`，`find` 也把它原封不動地回傳，為什麼 `s == nil` 是 `false`？

### 兩格裡有一格不是空的

問題出在 `return r` 這一行。`find` 的回傳型別是 `Shape`，所以 `r` 會被放進一個 `Shape` 介面值裡。放進去的時候：

| | 動態型別 | 動態值 |
| --- | --- | --- |
| `r` 放進介面後 | `*Rect` | `nil` |
| 真正的 `nil` 介面 | （空） | （空） |

動態值雖然是 `nil`，但動態型別那一格寫著 `*Rect`，不是空的。所以這個介面**不等於** `nil`。`%T` 印出的 `*main.Rect` 就是證據。

如果接著呼叫 `s.Area()`，`Area` 裡的 `r` 是 `nil` 指標，`r.Width` 會 panic。原本想用 `s == nil` 擋掉的情況，完全沒擋住。

### 解法：要回傳 `nil` 時，直接寫 `nil`

回傳型別是介面的函式，想表達「沒有」時，就直接 `return nil`，不要先放進某個指標變數再回傳：

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Rect struct {
	Width  float64
	Height float64
}

func (r *Rect) Area() float64 {
	return r.Width * r.Height
}

func findRect(name string) *Rect {
	if name == "big" {
		return &Rect{Width: 10, Height: 10}
	}
	return nil
}

func find(name string) Shape {
	r := findRect(name)
	if r == nil {
		return nil
	}
	return r
}

func main() {
	for _, name := range []string{"big", "small"} {
		s := find(name)
		if s == nil {
			fmt.Println(name, "找不到")
			continue
		}
		fmt.Println(name, "面積", s.Area())
	}
}
```

執行結果：

```text
big 面積 100
small 找不到
```

這次 `find` 在 `r` 是 `nil` 時直接 `return nil`。這個 `nil` 是介面的 `nil`，兩格都是空的，`s == nil` 就是 `true` 了。

關鍵是：`r == nil` 這個比較是在**放進介面之前**、用 `*Rect` 型別做的，所以結果正確。

### 為什麼要特別記住這個？

第 5 章會學到，Go 的錯誤處理用的 `error` 就是一個介面，而且到處都會寫 `if err != nil`。這個陷阱在處理錯誤時最常出現，所以現在先把它弄懂。

記住一個原則：**回傳型別是介面時，「沒有」就寫 `return nil`，不要回傳一個可能是 `nil` 的指標變數。**

## 重點整理

- 介面只有在動態型別和動態值都是空的時候才等於 `nil`。
- 把 `nil` 指標放進介面，動態型別仍然有值，所以介面 `!= nil`。
- 用 `%T` 可以看出介面裡裝了什麼型別，幫助找出這類問題。
- 回傳型別是介面時，要表達「沒有」就直接 `return nil`；先用具體型別檢查 `nil`，再決定要不要回傳。
