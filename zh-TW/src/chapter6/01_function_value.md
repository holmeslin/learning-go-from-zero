# 函式是值

## 本集目標

知道函式也是一種值：可以存進變數、有自己的型別，也能放進 map 或切片裡。

## 正文

### 把函式存進變數

我們已經很熟悉把數字、字串存進變數。在 Go 裡，函式也可以：

```go
package main

import "fmt"

func double(n int) int {
	return n * 2
}

func main() {
	f := double
	fmt.Println(f(5))
	fmt.Println(double(5))
}
```

執行結果：

```text
10
10
```

注意 `f := double` 這一行，`double` 後面**沒有**小括號。有小括號 `double(5)` 是「呼叫函式，拿到結果」；沒有小括號 `double` 是「函式本身」。

`f` 現在裝著 `double` 這個函式，所以 `f(5)` 和 `double(5)` 效果一樣。

### 函式的型別

既然是值，就有型別。函式的型別由「參數型別」和「回傳型別」決定，寫法是把函式宣告的名字和參數名稱拿掉：

| 函式宣告 | 函式型別 |
| --- | --- |
| `func double(n int) int` | `func(int) int` |
| `func add(a, b int) int` | `func(int, int) int` |
| `func greet(name string)` | `func(string)` |
| `func divide(a, b int) (int, error)` | `func(int, int) (int, error)` |

只要參數和回傳型別一樣，就是同一種型別，可以放進同一個變數：

```go
package main

import "fmt"

func double(n int) int {
	return n * 2
}

func square(n int) int {
	return n * n
}

func main() {
	var op func(int) int
	op = double
	fmt.Println(op(4))

	op = square
	fmt.Println(op(4))
}
```

執行結果：

```text
8
16
```

同一個 `op(4)`，因為 `op` 裡裝的函式不同，結果也不同。

型別不同的函式就放不進去，例如 `func(int, int) int` 不能放進 `func(int) int` 的變數，編譯器會擋下來。

### 零值是 `nil`

函式型別的零值是 `nil`。呼叫一個 `nil` 的函式值會 panic，所以不確定有沒有裝東西時，先檢查：

```go
package main

import "fmt"

func main() {
	var op func(int) int
	if op == nil {
		fmt.Println("op 還沒有裝函式")
	}
}
```

執行結果：

```text
op 還沒有裝函式
```

函式值只能和 `nil` 比較，兩個函式值之間不能用 `==` 比較。

### 放進 map

函式是值，就能放進 map。下面做一個小計算機，用運算符號查出對應的函式：

```go
package main

import "fmt"

func add(a, b int) int {
	return a + b
}

func sub(a, b int) int {
	return a - b
}

func mul(a, b int) int {
	return a * b
}

func main() {
	ops := map[string]func(int, int) int{
		"+": add,
		"-": sub,
		"*": mul,
	}

	for _, sym := range []string{"+", "-", "*", "/"} {
		op, ok := ops[sym]
		if !ok {
			fmt.Println(sym, "不支援")
			continue
		}
		fmt.Println(7, sym, 3, "=", op(7, 3))
	}
}
```

執行結果：

```text
7 + 3 = 10
7 - 3 = 4
7 * 3 = 21
/ 不支援
```

不用寫一長串 `switch`，想支援新的運算，只要在 map 裡多加一行就好。

## 重點整理

- 函式名稱後面不加小括號，代表函式本身，可以存進變數。
- 函式的型別由參數與回傳型別決定，例如 `func(int) int`。
- 函式型別的零值是 `nil`，呼叫 `nil` 函式會 panic；函式值只能和 `nil` 比較。
- 函式值可以放進 map、切片等資料結構裡。
