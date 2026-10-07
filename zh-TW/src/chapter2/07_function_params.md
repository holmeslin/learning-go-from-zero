# 函式參數

## 本集目標

讓函式接收「參數」，每次呼叫時可以傳入不同的值。

## 正文

上一集的 `sayHello` 每次都印一樣的東西。如果想跟不同的人打招呼呢？我們需要在呼叫時把名字「交給」函式。

### 一個參數

```go
package main

import "fmt"

func greet(name string) {
	fmt.Println("哈囉，" + name)
}

func main() {
	greet("小明")
	greet("小華")
}
```

執行結果：

```text
哈囉，小明
哈囉，小華
```

小括號裡的 `name string` 就是**參數**：`name` 是名字，`string` 是型別。它就像一個在函式裡可以使用的變數，值由呼叫的人決定。呼叫 `greet("小明")` 時，`name` 就是 `"小明"`。

和 `var` 一樣，Go 的參數也是名字在前、型別在後。

### 多個參數

多個參數用逗號隔開：

```go
package main

import "fmt"

func printRect(width int, height int) {
	fmt.Printf("%d x %d 的長方形，面積 %d\n", width, height, width*height)
}

func main() {
	printRect(3, 4)
	printRect(10, 2)
}
```

執行結果：

```text
3 x 4 的長方形，面積 12
10 x 2 的長方形，面積 20
```

呼叫時傳進去的值會照順序對上參數：第一個給 `width`，第二個給 `height`。

如果相鄰的參數型別一樣，可以只寫一次型別：`func printRect(width, height int)` 跟上面完全相同，而且大家比較常這樣寫。

### 型別和數量都要對

參數宣告成 `int`，就不能傳字串進去；要兩個參數，就不能只給一個。這些錯誤都會在編譯時被抓出來：

```go,compile_fail
package main

import "fmt"

func greet(name string) {
	fmt.Println("哈囉，" + name)
}

func main() {
	greet(123)
}
```

```text
cannot use 123 (untyped int constant) as string value in argument to greet
```

### 參數是複本

傳進函式的是值的**複本**。在函式裡修改參數，不會影響呼叫端原本的變數：

```go
package main

import "fmt"

func addOne(n int) {
	n = n + 1
	fmt.Println("函式裡：", n)
}

func main() {
	x := 5
	addOne(x)
	fmt.Println("main 裡：", x)
}
```

執行結果：

```text
函式裡： 6
main 裡： 5
```

`addOne` 拿到的是 5 的一份複本，改的是自己那一份，`main` 裡的 `x` 完全沒變。那如果想讓函式把算好的結果交回來呢？下一集的「回傳值」就是答案。

## 重點整理

- 參數寫在函式名稱後的小括號裡，格式是 `名字 型別`，多個參數用逗號隔開。
- 相鄰參數型別相同時，可以合併寫成 `(a, b int)`。
- 呼叫時傳入的值依序對應參數，型別與數量都要正確，否則無法編譯。
- 傳進函式的是複本，在函式裡改參數不會影響呼叫端的變數。
