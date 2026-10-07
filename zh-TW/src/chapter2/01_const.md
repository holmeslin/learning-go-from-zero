# `const`

## 本集目標

用 `const` 宣告「常數」：一個取了名字、之後永遠不會變的值。

## 正文

有些值在程式裡從頭到尾都不會變，例如一週有 7 天、圓周率大約是 3.14159。這種值我們可以用 `const` 宣告成**常數**。

### 宣告常數

```go
package main

import "fmt"

func main() {
	const daysPerWeek = 7
	weeks := 3
	fmt.Println(weeks * daysPerWeek)
}
```

執行結果：

```text
21
```

寫法跟 `var` 很像，只是把 `var` 換成 `const`。之後 `daysPerWeek` 就代表 7，用起來跟變數一樣。

為什麼不直接寫 `weeks * 7` 就好？因為 `7` 這個數字放在那裡，別人（或一個月後的你）不一定知道它是什麼意思；寫成 `daysPerWeek` 就一目了然。

### 常數不能改

常數一旦宣告好，就不能再賦值：

```go,compile_fail
package main

import "fmt"

func main() {
	const pi = 3.14159
	pi = 3
	fmt.Println(pi)
}
```

Go 會拒絕編譯：

```text
cannot assign to pi (neither addressable nor a map index expression)
```

訊息的後半段我們先不用管，重點是「不能對 `pi` 賦值」。這正是常數的用處：你確定某個值不該被改，就宣告成 `const`，萬一哪天不小心改到，編譯器會幫你抓出來。

### 一次宣告好幾個

常數很多時，可以用小括號包起來：

```go
package main

import "fmt"

func main() {
	const (
		minScore = 0
		maxScore = 100
	)
	fmt.Println("分數範圍：", minScore, "到", maxScore)
}
```

執行結果：

```text
分數範圍： 0 到 100
```

### 常數也可以放在 `main` 外面

常數也可以寫在 `func main()` 的外面，放在檔案最上方：

```go
package main

import "fmt"

const greeting = "哈囉"

func main() {
	fmt.Println(greeting, "Go")
}
```

執行結果：

```text
哈囉 Go
```

放在外面的常數，整個檔案都看得到。等我們學了函式，有好幾個函式都要用同一個常數時，就會常常這樣寫。

常數的值必須在編譯時就能確定，所以只能是數字、字串、`true`/`false` 這類寫死的值，不能是使用者輸入的東西。

## 重點整理

- `const 名稱 = 值` 宣告常數，常數宣告後不能再賦值，否則無法編譯。
- 用有意義的常數名稱取代程式裡「神祕的數字」，程式會更好讀。
- 多個常數可以用 `const ( ... )` 一起宣告。
- 常數可以寫在 `main` 外面，整個檔案都能使用；常數的值必須在編譯時就確定。
