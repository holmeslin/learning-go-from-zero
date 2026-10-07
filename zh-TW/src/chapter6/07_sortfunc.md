# `slices.SortFunc` 與 `cmp.Compare`

## 本集目標

用 `slices.SortFunc` 搭配比較函式，依照自己的規則排序切片，並用 `cmp.Compare` 寫出比較函式。

## 正文

上一集學了把函式當參數。標準函式庫裡最常用到這個技巧的地方之一，就是排序。

### 排序需要「比較規則」

要把一群學生排序，第一個問題是：依什麼排？分數？名字？分數一樣的時候呢？排序的步驟大家都一樣，只有「兩個東西誰該排前面」這個規則不同，所以標準函式庫讓你把規則用函式傳進去。

`slices.SortFunc(s, cmp)` 會依照比較函式 `cmp` 排序切片 `s`。比較函式收兩個元素 `a`、`b`，回傳一個 `int`：

| 回傳值 | 意思 |
| --- | --- |
| 負數 | `a` 要排在 `b` 前面 |
| 0 | 兩個一樣，誰前誰後都可以 |
| 正數 | `a` 要排在 `b` 後面 |

### 依分數排序

```go
package main

import (
	"fmt"
	"slices"
)

type Student struct {
	Name  string
	Score int
}

func main() {
	students := []Student{
		{"小明", 82},
		{"小美", 95},
		{"阿哲", 67},
	}

	slices.SortFunc(students, func(a, b Student) int {
		return a.Score - b.Score
	})
	fmt.Println(students)
}
```

執行結果：

```text
[{阿哲 67} {小明 82} {小美 95}]
```

`a.Score - b.Score`：`a` 的分數比較低時是負數，`a` 就排前面，所以結果是由小到大。`SortFunc` 會直接修改傳進去的切片，不會回傳新的。

### `cmp.Compare`：不用自己相減

用減法有兩個問題：字串不能相減；數字很大時相減可能溢位。`cmp` 套件的 `cmp.Compare(a, b)` 幫你做好這件事：`a < b` 回傳 -1，相等回傳 0，`a > b` 回傳 1。數字和字串都能用。

```go
package main

import (
	"cmp"
	"fmt"
	"slices"
)

type Student struct {
	Name  string
	Score int
}

func main() {
	students := []Student{
		{"Mia", 82},
		{"Andy", 95},
		{"Leo", 67},
	}

	slices.SortFunc(students, func(a, b Student) int {
		return cmp.Compare(a.Name, b.Name)
	})
	fmt.Println(students)

	slices.SortFunc(students, func(a, b Student) int {
		return cmp.Compare(b.Score, a.Score)
	})
	fmt.Println(students)
}
```

執行結果：

```text
[{Andy 95} {Leo 67} {Mia 82}]
[{Andy 95} {Mia 82} {Leo 67}]
```

第一次依名字由 A 到 Z 排序。第二次想要分數**由高到低**，只要把 `a`、`b` 對調，寫成 `cmp.Compare(b.Score, a.Score)` 就好。

字串比較是依照字元編碼的順序，英文會依字母排；中文就不是依筆畫或注音，所以這裡改用英文名字示範。

### 先比分數，一樣再比名字

分數一樣時，可以再用名字決定順序：

```go
package main

import (
	"cmp"
	"fmt"
	"slices"
)

type Student struct {
	Name  string
	Score int
}

func main() {
	students := []Student{
		{"Mia", 90},
		{"Andy", 75},
		{"Leo", 90},
		{"Ben", 75},
	}

	slices.SortFunc(students, func(a, b Student) int {
		if c := cmp.Compare(b.Score, a.Score); c != 0 {
			return c
		}
		return cmp.Compare(a.Name, b.Name)
	})
	fmt.Println(students)
}
```

執行結果：

```text
[{Leo 90} {Mia 90} {Andy 75} {Ben 75}]
```

先比分數（高到低），結果不是 0 就直接回傳；分數相同時才比名字（A 到 Z）。

## 重點整理

- `slices.SortFunc(s, cmp)` 依照比較函式 `cmp` 就地排序切片 `s`。
- 比較函式回傳負數表示 `a` 排前面、0 表示一樣、正數表示 `a` 排後面。
- `cmp.Compare(a, b)` 回傳 -1、0、1，數字和字串都能用；把 `a`、`b` 對調就是反向排序。
- 多個排序條件時，先比第一個條件，結果不是 0 才回傳，否則再比下一個。
