# 型別（基礎）

## 本集目標

認識 Go 最常用的四種型別：`int`、`float64`、`string`、`bool`，並知道變數的型別一旦決定就不能改。

## 正文

到目前為止，我們存過整數、有小數點的數字、文字，還有 `true` / `false`。這些資料其實屬於不同的「種類」，在程式裡叫做**型別**。

### 四種基本型別

| 型別 | 裝什麼 | 例子 |
| --- | --- | --- |
| `int` | 整數 | `18`、`-3`、`0` |
| `float64` | 有小數點的數字（浮點數） | `3.14`、`-0.5`、`2.0` |
| `string` | 字串（文字） | `"你好"`、`"Go"` |
| `bool` | 布林值 | `true`、`false` |

### `:=` 會自動決定型別

用 `:=` 建立變數時，Go 會看右邊的值，自動決定變數的型別：

```go
package main

import "fmt"

func main() {
	age := 18         // int
	height := 172.5   // float64
	name := "小明"      // string
	isStudent := true // bool
	fmt.Println(name, age, height, isStudent)
}
```

執行結果：

```text
小明 18 172.5 true
```

注意 `2` 和 `2.0` 不一樣：寫 `x := 2`，`x` 是 `int`；寫 `x := 2.0`，`x` 是 `float64`。

### 用 `var` 指定型別

第 13 集看過 `var count int`。用 `var` 時可以自己指定型別，也可以同時給值：

```go
package main

import "fmt"

func main() {
	var price float64 = 30
	var title string = "Go 入門"
	fmt.Println(title, price)
}
```

執行結果：

```text
Go 入門 30
```

`price` 雖然放的是 `30`，但我們指定了 `float64`，所以它是浮點數，之後可以放進 `30.5` 這種有小數的值。`float64` 的值如果剛好是整數，印出來時不會顯示小數點。

### 型別決定了就不能換

變數一旦建立，型別就固定了，只能放同型別的值：

```go,compile_fail
package main

import "fmt"

func main() {
	age := 18
	age = "十八"
	fmt.Println(age)
}
```

```text
./main.go:7:8: cannot use "十八" (untyped string constant) as int value in assignment
```

錯誤訊息的意思是：`"十八"` 是字串，不能放進 `int` 型別的變數。

整數變數也不能放有小數的值：

```go,compile_fail
package main

import "fmt"

func main() {
	age := 18
	age = 18.5
	fmt.Println(age)
}
```

```text
./main.go:7:8: cannot use 18.5 (untyped float constant) as int value in assignment (truncated)
```

`truncated` 是「會被截斷」的意思：18.5 放進整數會丟掉小數，Go 不允許這種偷偷遺失資料的事發生。

型別的好處是：很多錯誤在**編譯時**就會被抓出來，不會等到程式執行時才出問題。

## 重點整理

- 最常用的四種型別：`int`（整數）、`float64`（浮點數）、`string`（字串）、`bool`（布林值）。
- `:=` 會依照右邊的值自動決定型別；`2` 是 `int`，`2.0` 是 `float64`。
- `var 名稱 型別 = 值` 可以自己指定型別。
- 變數的型別決定後就不能改，放進不同型別的值會編譯錯誤。
