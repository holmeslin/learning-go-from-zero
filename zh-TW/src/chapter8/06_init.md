# `init` 函式

## 本集目標

認識會在 `main` 之前自動執行的 `init` 函式，以及程式啟動時的執行順序。

## 正文

### 自動執行的函式

在套件裡寫一個名叫 `init`、沒有參數也沒有回傳值的函式，它就會在程式啟動時**自動**執行，不需要任何人呼叫：

```go
package main

import "fmt"

func init() {
	fmt.Println("init 執行了")
}

func main() {
	fmt.Println("main 執行了")
}
```

執行結果：

```text
init 執行了
main 執行了
```

我們從頭到尾沒有呼叫 `init`，它卻在 `main` 之前執行了。

### 執行順序

一個套件啟動時，順序是：

1. 先算好所有套件層級的變數（寫在函式外面的 `var`）。
2. 再依序執行 `init` 函式。
3. 最後（只有 `main` 套件）執行 `main`。

```go
package main

import "fmt"

var greeting = makeGreeting()

func makeGreeting() string {
	fmt.Println("1. 設定套件層級的變數")
	return "哈囉"
}

func init() {
	fmt.Println("2. 第一個 init，greeting 已經是", greeting)
}

func init() {
	fmt.Println("3. 第二個 init")
}

func main() {
	fmt.Println("4. main")
}
```

執行結果：

```text
1. 設定套件層級的變數
2. 第一個 init，greeting 已經是 哈囉
3. 第二個 init
4. main
```

`init` 是唯一可以重複定義的函式名稱，同一個檔案可以有好幾個，依照寫的順序執行；套件有多個檔案時，Go 會把檔案依檔名排序後再依序執行。另外，`init` 不能被呼叫，在程式裡寫 `init()` 會編譯錯誤。

### 被引入的套件先初始化

如果 `main` 套件引入了 `greet` 套件，`greet` 的變數和 `init` 會先全部跑完，才輪到 `main` 套件。每個套件不管被引入幾次，都只會初始化一次。

這就是第 4 集提到 `import _ "image/png"` 的用途：`image/png` 的 `init` 會向 `image` 套件「登記」自己會讀 PNG 格式，引入它只是為了讓這段 `init` 執行。

### 少用為妙

`init` 很方便，但它是「偷偷」執行的，讀程式的人不容易發現。而且 `init` 不能回傳 `error`，出錯了只能 `panic`。一般來說，能寫成普通函式、在 `main` 裡明確呼叫的，就不要放進 `init`。套件層級的變數也盡量直接初始化，像上面的 `var greeting = makeGreeting()`。

## 重點整理

- `init` 函式沒有參數、沒有回傳值，程式啟動時自動執行，不能手動呼叫。
- 順序：套件層級變數 → `init` → `main`；被引入的套件會先完成初始化。
- 一個套件可以有多個 `init`，依出現順序執行。
- `init` 不容易被看見又不能回傳錯誤，能不用就不用。
