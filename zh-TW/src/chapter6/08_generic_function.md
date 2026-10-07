# 泛型函式

## 本集目標

寫出有「型別參數」的泛型函式，讓同一份程式碼可以用在不同型別上。

## 正文

### 同樣的程式寫兩次

假設要寫一個函式，把切片的順序反過來印出。給 `[]int` 用的寫一次，給 `[]string` 用的又要寫一次：

```go
package main

import "fmt"

func printReversedInts(s []int) {
	for i := len(s) - 1; i >= 0; i-- {
		fmt.Print(s[i], " ")
	}
	fmt.Println()
}

func printReversedStrings(s []string) {
	for i := len(s) - 1; i >= 0; i-- {
		fmt.Print(s[i], " ")
	}
	fmt.Println()
}

func main() {
	printReversedInts([]int{1, 2, 3})
	printReversedStrings([]string{"a", "b", "c"})
}
```

執行結果：

```text
3 2 1 
c b a 
```

兩個函式除了型別以外一模一樣。如果還要支援 `[]float64`、`[]bool`……就要一直複製下去。

### 型別參數

泛型讓我們把「型別」也變成參數：

```go
package main

import "fmt"

func printReversed[T any](s []T) {
	for i := len(s) - 1; i >= 0; i-- {
		fmt.Print(s[i], " ")
	}
	fmt.Println()
}

func main() {
	printReversed([]int{1, 2, 3})
	printReversed([]string{"a", "b", "c"})
	printReversed([]float64{1.5, 2.5})
}
```

執行結果：

```text
3 2 1 
c b a 
2.5 1.5 
```

新的地方是函式名稱後面的 `[T any]`：

- 方括號 `[...]` 裡宣告的是**型別參數**。一般參數放在小括號裡，代表「值」；型別參數放在方括號裡，代表「型別」。
- `T` 是型別參數的名字，習慣用一個大寫字母，`T` 是 type 的意思。
- `any` 是這個型別參數的**約束**，表示 `T` 可以是任何型別。約束下一集會詳細介紹。

在函式裡，`T` 就像一個普通的型別名稱：`s []T` 表示「元素型別是 `T` 的切片」。

呼叫 `printReversed([]int{1, 2, 3})` 時，Go 看到傳進來的是 `[]int`，就知道這次 `T` 是 `int`。

### 自己指定型別

也可以在呼叫時，用方括號明確寫出型別參數：

```go
package main

import "fmt"

func firstOr[T any](s []T, fallback T) T {
	if len(s) == 0 {
		return fallback
	}
	return s[0]
}

func main() {
	fmt.Println(firstOr[string]([]string{"蘋果", "香蕉"}, "沒有水果"))
	fmt.Println(firstOr([]string{}, "沒有水果"))
	fmt.Println(firstOr([]int{}, -1))
}
```

執行結果：

```text
蘋果
沒有水果
-1
```

`firstOr[string](...)` 明確指定 `T` 是 `string`。大多數時候不需要寫，Go 會自己從參數推出來，第 14 集會再細談。

第 5 章的 `errors.AsType[*ValidationError](err)` 就是這種寫法：它是一個泛型函式，方括號裡指定要找的錯誤型別。因為型別沒辦法從參數 `err` 推出來，所以一定要自己寫。

### 多個型別參數

型別參數可以有好幾個，用逗號分開。下面的 `mapSlice` 把每個元素轉換成另一種型別：

```go
package main

import (
	"fmt"
	"strings"
)

func mapSlice[T, U any](s []T, f func(T) U) []U {
	result := make([]U, 0, len(s))
	for _, v := range s {
		result = append(result, f(v))
	}
	return result
}

func main() {
	words := []string{"go", "is", "fun"}
	fmt.Println(mapSlice(words, func(w string) int { return len(w) }))
	fmt.Println(mapSlice(words, strings.ToUpper))
}
```

執行結果：

```text
[2 2 3]
[GO IS FUN]
```

`[T, U any]` 宣告了兩個型別參數，`T` 是輸入元素的型別，`U` 是輸出元素的型別。第一次呼叫 `T` 是 `string`、`U` 是 `int`；第二次兩個都是 `string`。

## 重點整理

- 泛型函式在名稱後面用方括號宣告型別參數，例如 `func f[T any](s []T)`。
- 型別參數在函式裡可以當成一般型別使用。
- 呼叫時通常可以省略型別參數，Go 會從傳入的值推論；也可以寫成 `f[int](...)` 明確指定。
- 可以宣告多個型別參數，例如 `[T, U any]`。
