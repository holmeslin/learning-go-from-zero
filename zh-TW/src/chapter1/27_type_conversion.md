# 型別轉換

## 本集目標

用 `float64(x)`、`int(x)` 這類寫法，把一種數字型別轉成另一種。

## 正文

### 不同型別不能直接一起算

算平均時，常常會遇到這種情況：

```go,compile_fail
package main

import "fmt"

func main() {
	total := 10.5
	count := 3
	fmt.Println(total / count)
}
```

```text
./main.go:8:14: invalid operation: total / count (mismatched types float64 and int)
```

`total` 是 `float64`，`count` 是 `int`，型別不一樣（mismatched types），Go 不允許它們直接相除。就算都是整數也一樣，`int` 和 `int64` 也不能直接相加。

有些語言會自動幫你轉，但 Go 堅持要你**自己寫清楚**，這樣就不會在不知不覺中遺失資料。

### `型別(值)`：轉換

把型別名稱當成小括號放在值的前面，就能轉換：

```go
package main

import "fmt"

func main() {
	total := 10.5
	count := 3
	fmt.Println(total / float64(count))
}
```

執行結果：

```text
3.5
```

`float64(count)` 會得到一個 `float64` 的 3，這樣兩邊型別相同，就可以相除了。注意 `count` 本身還是 `int`，轉換只是產生一個新的值，不會改變原本的變數。

### 兩個整數相除，想得到小數

上一集的問題：兩個 `int` 相除只會得到整數。只要先把它們轉成 `float64` 再除就好：

```go
package main

import "fmt"

func main() {
	sum := 7
	n := 2
	fmt.Println(sum / n)
	fmt.Println(float64(sum) / float64(n))
}
```

執行結果：

```text
3
3.5
```

要注意的是轉換的**時機**：`float64(sum / n)` 會先做整數除法得到 3，再轉成 3.0，小數早就不見了。要在除**之前**就轉。

### 浮點數轉整數：直接砍掉小數

`int(x)` 可以把浮點數轉成整數，小數部分會直接砍掉，不會四捨五入：

```go
package main

import "fmt"

func main() {
	price := 99.9
	fmt.Println(int(price))

	temp := -3.7
	fmt.Println(int(temp))
}
```

執行結果：

```text
99
-3
```

99.9 變成 99，-3.7 變成 -3，都是往 0 的方向砍。

### 整數型別之間也要轉

```go
package main

import "fmt"

func main() {
	var a int = 100
	var b int64 = 200
	fmt.Println(int64(a) + b)
}
```

執行結果：

```text
300
```

把大範圍的型別轉成小範圍的型別時（例如 `int` 轉 `int8`），放不下的話會像第 25 集說的一樣繞回去，所以要確定數字放得下再轉。

### 這跟 `strconv.Atoi` 不一樣

`int(...)`、`float64(...)` 只能在**數字型別之間**轉換。要把文字 `"18"` 變成整數，還是要用第 16 集的 `strconv.Atoi`。

## 重點整理

- 不同的數字型別不能直接一起運算，要先轉成相同型別。
- 轉換的寫法是 `型別(值)`，例如 `float64(count)`、`int(price)`；原本的變數不會改變。
- 兩個整數相除想得到小數，要在除之前先轉成 `float64`。
- 浮點數轉整數會直接砍掉小數部分，不會四捨五入。
