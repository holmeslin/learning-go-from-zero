# 自我參照的型別約束

## 本集目標

看懂 Go 1.26 起允許的 `type Adder[A Adder[A]] interface{ Add(A) A }` 這種寫法：泛型型別可以在自己的型別參數清單裡提到自己。

## 正文

### 想要的效果

我們想寫一個泛型的 `Sum`，把一串值加起來。這些值不一定是數字，可能是向量、金額，只要它有一個 `Add` 方法，能「跟同型別的值相加、得到同型別的結果」就行。

用第 6 章的型別約束，可以先寫出這樣的介面：

```go,ignore
type Adder[A any] interface {
	Add(A) A
}
```

意思是：「有 `Add(A) A` 方法的型別」。`Sum` 再寫成 `func Sum[A Adder[A]](xs ...A) A`，要求 `A` 自己要滿足 `Adder[A]`，也就是「`A` 能跟 `A` 相加」。

這樣可以用，但介面本身的 `A any` 太寬鬆了：`Adder[int]` 也是合法的寫法，雖然 `int` 根本沒有 `Add` 方法。「`A` 必須能跟自己相加」這個要求，只寫在 `Sum` 那裡，介面本身沒有表達出來。

### 在約束裡提到自己

最直接的寫法，是在介面的型別參數清單裡就要求 `A` 滿足 `Adder[A]`：

```go,ignore
type Adder[A Adder[A]] interface {
	Add(A) A
}
```

`Adder` 的定義裡提到了 `Adder` 自己，所以叫**自我參照**。Go 1.25 以前，編譯器會直接拒絕，說這是 `invalid recursive type`。Go 1.26 起允許泛型型別在自己的型別參數清單裡參照自己，這種寫法就合法了。

完整的例子：

```go
package main

import "fmt"

type Adder[A Adder[A]] interface {
	Add(A) A
}

type Vec struct {
	X, Y int
}

func (v Vec) Add(o Vec) Vec {
	return Vec{v.X + o.X, v.Y + o.Y}
}

type Money int

func (m Money) Add(o Money) Money {
	return m + o
}

func Sum[A Adder[A]](xs ...A) A {
	var total A
	for _, x := range xs {
		total = total.Add(x)
	}
	return total
}

func main() {
	fmt.Println(Sum(Vec{1, 2}, Vec{3, 4}, Vec{5, 6}))
	fmt.Println(Sum[Money](100, 250, 30))
}
```

執行結果：

```text
{9 12}
380
```

一步一步看：

- `Vec` 的 `Add` 收 `Vec`、回傳 `Vec`，所以 `Vec` 滿足 `Adder[Vec]`；`Money` 也一樣。
- `Sum` 裡的 `var total A` 從零值開始累加。`Vec` 的零值是 `{0 0}`，`Money` 的零值是 `0`，剛好都適合當起點。
- `Sum[Money](100, 250, 30)` 明確指定 `A` 是 `Money`。`100` 這些是無型別常數（附錄一 g），可以直接變成 `Money`；如果不指定，Go 會把它們推論成 `int`，而 `int` 沒有 `Add` 方法。

### 現在介面自己會把關

因為約束寫在介面上，`Adder[int]` 這種沒有意義的寫法會直接被擋下來：

```go,compile_fail
package main

type Adder[A Adder[A]] interface {
	Add(A) A
}

func main() {
	var x Adder[int]
	_ = x
}
```

編譯錯誤：

```text
int does not satisfy Adder[int] (missing method Add)
```

這就是自我參照約束的好處：「`A` 一定要能跟自己相加」這條規則，寫在介面上一次就好，用到它的地方都會被檢查。

### 什麼時候會遇到

這種寫法在「型別要跟自己的同類互動」時最常見，例如：

- 相加、合併：`Add(A) A`、`Merge(A) A`
- 比較大小：`Less(A) bool`
- 複製：`Clone() A`

日常程式碼不一定會自己寫，但讀泛型套件時看到 `[T Foo[T]]`，你就知道它的意思是「`T` 必須能和自己的同類做 `Foo` 規定的事」。

## 重點整理

- `type Adder[A Adder[A]] interface{ Add(A) A }` 在型別參數清單裡參照自己，Go 1.26 起才允許。
- 它表達「`A` 必須能跟同型別的值相加，並得到同型別的結果」。
- 約束寫在介面上，像 `Adder[int]` 這種不合理的實例會在編譯時被擋下。
- 常見於 `Add`、`Less`、`Clone` 這類需要和「自己的同類」互動的方法。
