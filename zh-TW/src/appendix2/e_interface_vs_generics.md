# 介面 vs 泛型的取捨

## 本集目標

分辨什麼時候該用介面、什麼時候該用泛型，並了解 Go 1.27 的泛型方法對這個選擇有什麼影響。

## 正文

### 兩種「一份程式碼，多種型別」

介面（第 4 章）和泛型（第 6 章）都能讓一份程式碼處理多種型別，但方向不一樣：

- **介面**：關心「**能做什麼**」。不同型別各自實作同一組方法，**行為不同**；呼叫哪個實作，執行時才決定。
- **泛型**：關心「**對什麼型別做**」。**同一套做法**套用在不同型別上，寫程式時就決定型別，結果保有原本的型別。

一個簡單的判斷方式：如果你發現自己寫了好幾份一模一樣的程式碼，只差在型別，用泛型；如果每種型別要做的事情不一樣，用介面。

### 行為不同：用介面

```go
package main

import "fmt"

type Shape interface {
	Area() float64
}

type Rect struct{ W, H float64 }
type Circle struct{ R float64 }

func (r Rect) Area() float64   { return r.W * r.H }
func (c Circle) Area() float64 { return 3.14 * c.R * c.R }

func totalArea(shapes []Shape) float64 {
	total := 0.0
	for _, s := range shapes {
		total += s.Area()
	}
	return total
}

func main() {
	shapes := []Shape{Rect{W: 3, H: 4}, Circle{R: 1}, Rect{W: 1, H: 1}}
	fmt.Println(totalArea(shapes))
}
```

執行結果：

```text
16.14
```

矩形和圓形算面積的方法完全不同，而且**同一個切片**裡混著兩種型別。這是介面的強項，泛型做不到：`[]T` 裡的元素一定是同一種 `T`。

### 做法相同：用泛型

反過來，「從切片裡挑出符合條件的元素」對任何型別都一樣：

```go
package main

import "fmt"

func filter[T any](items []T, keep func(T) bool) []T {
	var result []T
	for _, v := range items {
		if keep(v) {
			result = append(result, v)
		}
	}
	return result
}

func main() {
	nums := filter([]int{3, 8, 1, 9}, func(n int) bool { return n > 2 })
	fmt.Println(nums, nums[0]+nums[1])

	words := filter([]string{"go", "sql", "pprof"}, func(s string) bool { return len(s) > 2 })
	fmt.Println(words)
}
```

執行結果：

```text
[3 8 9] 11
[sql pprof]
```

如果改用 `[]any` 寫，呼叫的人得先把 `[]int` 一個個轉成 `[]any`，拿回來還要做型別斷言才能相加，型別寫錯也要到執行時才發現。泛型版直接拿到 `[]int`，編譯器一路幫你檢查。

### 兩者一起用：介面當約束

約束（第 6 章）本身就是介面，所以「需要某個方法、又想保留原本型別」時，可以兩者合用：

```go
package main

import (
	"fmt"
	"strings"
)

type Celsius float64

func (c Celsius) String() string { return fmt.Sprintf("%.1f°C", float64(c)) }

func joinAll[T fmt.Stringer](items []T) string {
	parts := make([]string, 0, len(items))
	for _, v := range items {
		parts = append(parts, v.String())
	}
	return strings.Join(parts, "、")
}

func main() {
	temps := []Celsius{21.5, 25, 18}
	fmt.Println(joinAll(temps))
}
```

執行結果：

```text
21.5°C、25.0°C、18.0°C
```

如果參數寫成 `[]fmt.Stringer`，`[]Celsius` 是**不能**直接傳進去的（兩種切片的記憶體排列不同），得另外建一個新切片一個個放進去。用 `[T fmt.Stringer]` 就沒有這個麻煩。

### 效能不是主要考量

常聽到「泛型比介面快」的說法，但不一定：Go 的泛型實作會讓共用底層結構的型別共用同一份程式碼，裡面有時還是要查表呼叫方法。介面呼叫的成本在大多數程式裡也微不足道。**依照程式的意思選擇**，真的在意效能時，用 benchmark 和 `pprof` 量過再說。

### Go 1.27 的泛型方法

Go 1.27 起方法可以有自己的型別參數（第 6 章學過），例如 `func (s Stack[T]) Convert[U any](...)`。但記得那兩個限制：介面的方法不能有型別參數，泛型方法也不能拿來滿足介面的方法。

這對取捨的影響是：

- **泛型方法是「方便」，不是「抽象」**。它讓你把轉換、走訪這類輔助功能放在型別底下，用 `list.Map(f)` 呼叫，但它不會成為任何介面的一部分。
- **需要讓呼叫者換掉實作時，還是靠介面**，而介面裡的方法必須是普通（非泛型）方法。如果某個操作需要「每次呼叫換一種型別」又要放進介面，通常的做法是把型別參數放到介面本身，例如 `type Store[T any] interface { Get(id int) (T, error) }`，或是改成接收 `any` 的普通方法。
- 一個型別可以同時有普通方法去實作介面、再加幾個泛型方法當輔助，兩者並不衝突。

### 小結：怎麼選

| 情況 | 選擇 |
| --- | --- |
| 不同型別有不同的行為，或要放在同一個集合裡 | 介面 |
| 讓使用者（或測試）換掉實作，例如 `io.Writer`、資料庫存取層 | 介面 |
| 同一套演算法、容器，對很多型別都一樣 | 泛型 |
| 需要某些方法，又想保留原本型別 | 泛型 + 介面約束 |
| 想把泛型輔助功能放在型別底下 | 泛型方法（Go 1.27），但它進不了介面 |

拿不定主意時，先寫具體的型別。等出現第二、第三個重複，再看重複的是「行為」還是「型別」，就知道該往哪邊抽象了。

## 重點整理

- 介面抽象「能做什麼」，不同型別行為不同、執行時決定；泛型抽象「對什麼型別做」，同一套做法、編譯時決定並保留型別。
- 混合不同型別的集合、可替換的實作用介面；重複只差在型別的演算法和容器用泛型。
- 需要方法又要保留型別時，用介面當泛型的約束。
- Go 1.27 的泛型方法不能出現在介面裡、也不能實作介面方法，適合當輔助功能，抽象仍靠介面。
- 依照程式的意思選，不要為了想像中的效能差異選；先寫具體型別，重複出現了再抽象。
