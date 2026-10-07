# 型別（數字詳解）

## 本集目標

認識 `int` 和 `float64` 以外的數字型別，了解溢位和整數除法。

## 正文

上一集認識了 `int` 和 `float64`。其實 Go 的數字型別不只這兩個，差別在於「能裝多大的數字」和「能不能是負數」。

### 整數型別

| 型別 | 範圍 |
| --- | --- |
| `int8` | -128 ～ 127 |
| `int16` | -32768 ～ 32767 |
| `int32` | 約 -21 億 ～ 21 億 |
| `int64` | 約 -922 京 ～ 922 京 |
| `int` | 在現在常見的 64 位元電腦上，和 `int64` 一樣大 |

名稱後面的數字是「用幾個位元（bit）來存」。位元越多，能存的數字範圍越大，但也越佔記憶體。

另外還有前面加 `u` 的版本：`uint8`、`uint16`、`uint32`、`uint64`、`uint`。`u` 是 unsigned（沒有正負號）的意思，**不能存負數**，但正數的範圍大了一倍，例如 `uint8` 是 0 ～ 255。

**大多數時候用 `int` 就好。**只有在特別需要時（例如要和某些固定格式的資料配合）才會用其他的整數型別。

### 放不下的數字

寫在程式碼裡的數字如果超出範圍，Go 在編譯時就會擋下來：

```go,compile_fail
package main

import "fmt"

func main() {
	var small int8 = 200
	fmt.Println(small)
}
```

```text
./main.go:6:19: cannot use 200 (untyped int constant) as int8 value in variable declaration (overflows)
```

`overflows` 是**溢位**的意思：數字太大，裝不下了。

### 執行時的溢位會「繞回去」

但如果數字是在程式執行時才算出來超過範圍的，Go 不會報錯，而是會「繞一圈」回到另一端：

```go
package main

import "fmt"

func main() {
	var small int8 = 127
	small++
	fmt.Println(small)

	var count uint8 = 0
	count--
	fmt.Println(count)
}
```

執行結果：

```text
-128
255
```

`int8` 最大是 127，再加 1 就繞到最小的 -128。`uint8` 最小是 0，再減 1 就繞到最大的 255。就像汽車的里程表跑到 999999 之後會變回 000000。

這不會有任何錯誤訊息，所以要自己注意數字會不會變得太大。用 `int` 的話範圍非常大，平常很少碰到。

### 浮點數型別

浮點數有兩種：`float64` 和 `float32`。`float64` 比較精確，**一律用 `float64` 就好**：

```go
package main

import "fmt"

func main() {
	var a float64 = 1.0 / 3
	var b float32 = 1.0 / 3
	fmt.Println(a)
	fmt.Println(b)
}
```

執行結果：

```text
0.3333333333333333
0.33333334
```

`float32` 能記住的位數少很多。

另外，浮點數本來就無法完全精確地表示所有小數：

```go
package main

import "fmt"

func main() {
	x := 0.1
	y := 0.2
	fmt.Println(x + y)
}
```

執行結果：

```text
0.30000000000000004
```

這不是 Go 的錯，幾乎所有程式語言都一樣，因為電腦是用二進位來存小數的。所以**不要用浮點數來存金額**這種一分錢都不能差的資料，用整數存「分」或「元」比較安全。

### 整數除法

第 5 集提過，兩個整數相除，結果還是整數，小數部分直接丟掉（不是四捨五入）：

```go
package main

import "fmt"

func main() {
	a := 7
	b := 2
	fmt.Println(a / b)
	fmt.Println(-7 / 2)
	fmt.Println(7.0 / 2.0)
}
```

執行結果：

```text
3
-3
3.5
```

3.5 變成 3，-3.5 變成 -3，都是直接把小數點後面砍掉。浮點數相除才會得到 3.5。那如果手上的是兩個 `int` 變數，卻想得到 3.5 呢？這要用到第 27 集的型別轉換。

## 重點整理

- 整數型別有 `int8`、`int16`、`int32`、`int64`、`int`，以及不能存負數的 `uint` 系列；平常用 `int` 就好。
- 超出範圍叫溢位：寫死的數字會編譯錯誤，執行時算出來的會繞回另一端。
- 浮點數有 `float64` 和 `float32`，用 `float64` 就好；浮點數無法完全精確表示小數。
- 整數相除會直接捨去小數部分。
