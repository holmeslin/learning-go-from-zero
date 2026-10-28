# 無型別常數

## 本集目標

了解沒有寫型別的常數為什麼可以「到處用」，以及它的高精度與預設型別。

## 正文

第 2 章學 `const` 時，我們常常這樣寫：

```go,ignore
const limit = 100
```

這裡沒有寫型別，而且右邊的 `100` 也是**無型別常數**，所以 `limit` 保持無型別。它不是「沒有型別所以什麼都不是」，而是「型別先保留，等用到時再決定」。

不過，省略宣告上的型別，不保證得到無型別常數。若右邊已經有型別，就會沿用它。例如 `const n = int(1)` 的 `n` 是 `int` 常數；再寫 `const other = n`，`other` 也會是 `int` 常數。

### 同一個常數，可以配合不同型別

一般變數有固定型別，`int` 和 `float64` 不能直接混著算，要先轉換。無型別常數就不一樣：

```go
package main

import "fmt"

const limit = 100

func main() {
	var a int = limit
	var b float64 = limit
	var c int8 = limit
	fmt.Println(a, b, c)

	price := 19.5
	fmt.Println(price * limit)
}
```

執行結果：

```text
100 100 100
1950
```

`limit` 放進 `int`、`float64`、`int8` 都可以，跟 `float64` 的 `price` 相乘也不用轉換。因為它還沒有被綁定型別，Go 會在使用的地方幫它變成需要的型別，前提是值放得進目標型別。

如果寫成有型別的常數 `const limit int = 100`，它就和一般 `int` 一樣，`price * limit` 會編譯失敗。

### 預設型別

那如果使用的地方沒有指定型別呢？例如 `x := limit`。這時 Go 會用常數的**預設型別**：

| 常數長什麼樣子 | 預設型別 |
| --- | --- |
| 整數，例如 `100` | `int` |
| 小數或科學記號，例如 `2.5`、`1e6` | `float64` |
| 字元，例如 `'A'` | `rune` |
| 字串，例如 `"hi"` | `string` |
| `true`、`false` | `bool` |

```go
package main

import "fmt"

const (
	count = 100
	ratio = 2.5
	grade = 'A'
	title = "hi"
)

func main() {
	a := count
	b := ratio
	c := grade
	d := title
	fmt.Printf("%T %T %T %T\n", a, b, c, d)
}
```

執行結果：

```text
int float64 int32 string
```

`rune` 其實就是 `int32` 的別名，所以 `%T` 印出來是 `int32`。

### 高精度：中間結果可以超大

無型別常數在編譯時計算，精度比任何數字型別都高。計算過程中就算超過 `int64` 的範圍也沒關係，只要**最後用到的值**放得進目標型別就好：

```go
package main

import "fmt"

const huge = 10_000_000_000 * 10_000_000_000
const small = huge / 10_000_000_000 / 2_500_000_000

func main() {
	fmt.Println(small)
}
```

執行結果：

```text
4
```

上面的乘法得到 100,000,000,000,000,000,000，遠遠超過 `int64` 的上限，但它只是常數，沒有被存進任何變數。接著用兩次除法算出 4，最後放進 `int` 完全沒問題。

反過來，如果最後的值放不下，編譯器會直接告訴你：

```go,compile_fail
package main

import "fmt"

const huge = 10_000_000_000 * 10_000_000_000

func main() {
	fmt.Println(huge)
}
```

編譯錯誤：

```text
./main.go:8:14: cannot use huge (untyped int constant 100000000000000000000) as int value in argument to fmt.Println (overflows)
```

`fmt.Println` 需要一個實際的值，`huge` 得變成預設型別 `int`，但它放不下，所以編譯失敗。在編譯時就發現溢位，比執行時悄悄算錯好太多了。

## 重點整理

- 省略 `const` 的型別時，右邊也是無型別常數才會保持無型別；右邊已有型別就沿用它。無型別常數能配合不同型別，前提是值放得進去。
- 沒有指定型別時採用預設型別：整數 `int`、小數 `float64`、字元 `rune`、字串 `string`、布林 `bool`。
- 無型別常數在編譯時以高精度計算，中間結果可以超出一般型別範圍。
- 最後的值放不進目標型別時，會在編譯時報錯。
