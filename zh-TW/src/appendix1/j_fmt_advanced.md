# `fmt` 進階格式

## 本集目標

用 `fmt.Printf` 控制寬度與對齊，並學會幾個除錯時很好用的格式動詞。

## 正文

第 2 章學過 `%d`、`%s`、`%f`、`%v`、`%T` 這些基本動詞。這集再多學一些，讓輸出更整齊，除錯也更方便。

### 寬度與對齊

在 `%` 和動詞之間寫數字，就是**最小寬度**。不夠寬時預設在左邊補空格（靠右對齊）；寫成負數，也就是加個 `-`，就改成靠左對齊：

```go
package main

import "fmt"

func main() {
	fmt.Printf("[%5d]\n", 42)
	fmt.Printf("[%-5d]\n", 42)
	fmt.Printf("[%05d]\n", 42)
	fmt.Printf("[%8s]\n", "Go")
	fmt.Printf("[%-8s]\n", "Go")
}
```

執行結果：

```text
[   42]
[42   ]
[00042]
[      Go]
[Go      ]
```

`%05d` 的 `0` 表示用 `0` 而不是空格來補，常用在編號，例如 `00042`。

搭配迴圈就能印出整齊的表格：

```go
package main

import "fmt"

func main() {
	names := []string{"Andy", "Bob", "Cindy"}
	scores := []float64{92.5, 8, 77.25}
	for i, name := range names {
		fmt.Printf("%-6s|%7.2f\n", name, scores[i])
	}
}
```

執行結果：

```text
Andy  |  92.50
Bob   |   8.00
Cindy |  77.25
```

`%7.2f` 是「總寬度 7、小數 2 位」。寬度和精度可以一起用。

小提醒：寬度是用「字元數」計算的，中文字在終端機裡通常佔兩格，所以中英混合的表格可能還是會歪掉。

### `%v`、`%+v`、`%#v`：看清楚 struct

印 struct 時，這三個動詞一個比一個詳細：

```go
package main

import "fmt"

type Point struct {
	X, Y int
}

func main() {
	p := Point{X: 3, Y: 4}
	fmt.Printf("%v\n", p)
	fmt.Printf("%+v\n", p)
	fmt.Printf("%#v\n", p)

	s := []string{"a", "b"}
	fmt.Printf("%#v\n", s)
}
```

執行結果：

```text
{3 4}
{X:3 Y:4}
main.Point{X:3, Y:4}
[]string{"a", "b"}
```

- `%v`：只有值。
- `%+v`：加上欄位名稱，除錯時最常用。
- `%#v`：印成 Go 程式碼的樣子，連型別都寫出來。字串會加上引號，空字串也看得清楚。

### `%q`：帶引號的字串

```go
package main

import "fmt"

func main() {
	fmt.Printf("%q\n", "hello")
	fmt.Printf("%q\n", "")
	fmt.Printf("%q\n", "a\tb")
}
```

執行結果：

```text
"hello"
""
"a\tb"
```

字串前後有沒有多餘的空白、是不是空字串、有沒有藏著 Tab，用 `%q` 一眼就看出來。

### 數字的不同面貌：`%x`、`%o`、`%b`、`%e`

```go
package main

import "fmt"

func main() {
	n := 255
	fmt.Printf("%x %X %o %b\n", n, n, n, n)
	fmt.Printf("%#x %#o\n", n, n)
	fmt.Printf("%08b\n", 5)
	fmt.Printf("%x\n", "Go")

	big := 123456789.0
	fmt.Printf("%e\n", big)
	fmt.Printf("%.2e\n", big)
}
```

執行結果：

```text
ff FF 377 11111111
0xff 0377
00000101
476f
1.234568e+08
1.23e+08
```

- `%x` / `%X`：十六進位，小寫或大寫。用在字串上，會印出每個 byte 的十六進位。
- `%o`：八進位；`%b`：二進位。
- 加上 `#` 會帶前綴，例如 `0xff`。
- `%e`：科學記號，`%.2e` 控制小數位數。

### `%p`：指標的位址

```go
package main

import "fmt"

func main() {
	x := 10
	p := &x
	fmt.Printf("%p\n", p)
}
```

執行結果（位址每次執行都可能不同）：

```text
0x14000010138
```

`%p` 印出指標指向的記憶體位址。實務上很少需要真的看位址的數字，但想確認「兩個指標是不是指向同一個東西」時，可以把它們印出來比對。

### `%%`：印出百分號

`%` 在格式字串裡有特殊意義，想印出 `%` 本身就寫兩個：

```go
package main

import "fmt"

func main() {
	fmt.Printf("完成 %d%%\n", 80)
}
```

執行結果：

```text
完成 80%
```

### `fmt.Sprintf`

以上所有格式，都能用在 `fmt.Sprintf`。它不會印出來，而是把結果當成字串回傳，方便存起來再用：

```go
package main

import "fmt"

func main() {
	id := fmt.Sprintf("A%04d", 7)
	fmt.Println(id)
}
```

執行結果：

```text
A0007
```

## 重點整理

- `%5d` 設定最小寬度並靠右對齊，`%-5d` 靠左，`%05d` 用 `0` 補齊，`%7.2f` 同時設定寬度與小數位數。
- `%+v` 會加欄位名稱，`%#v` 印成 Go 程式碼的樣子，`%q` 印出帶引號的字串。
- `%x`、`%o`、`%b` 分別是十六、八、二進位，`%e` 是科學記號，`%p` 是指標位址。
- `%%` 印出百分號；`fmt.Sprintf` 用同樣的格式產生字串。
