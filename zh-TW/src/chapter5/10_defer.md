# `defer`

## 本集目標

用 `defer` 把一個函式呼叫「延後」到目前的函式結束時才執行。

## 正文

### 「最後一定要做」的事

很多事情是成對的：打開檔案之後要關閉、開燈之後要關燈、借了東西要還。麻煩的是，函式裡常常有好幾個 `return`（特別是學了 `if err != nil` 之後），每個 `return` 之前都要記得收尾，很容易漏掉。

`defer` 讓你在「借東西」的下一行，就把「還東西」寫好，Go 會保證在函式結束時幫你執行。

### 基本用法

在函式呼叫前面加上 `defer`，這個呼叫就會被延後到**包住它的函式結束時**才執行：

```go
package main

import "fmt"

func main() {
	fmt.Println("開燈")
	defer fmt.Println("關燈")

	fmt.Println("看書")
	fmt.Println("寫作業")
}
```

執行結果：

```text
開燈
看書
寫作業
關燈
```

`defer fmt.Println("關燈")` 寫在第二行，但「關燈」最後才印出來，因為它等到 `main` 結束時才執行。

### 不管從哪個 `return` 離開都會執行

`defer` 真正好用的地方是：函式不管從哪裡 `return`，延後的呼叫都會執行。

```go
package main

import (
	"errors"
	"fmt"
)

func borrowBook(title string) error {
	fmt.Println("借出：", title)
	defer fmt.Println("歸還：", title)

	if title == "" {
		return errors.New("書名是空的")
	}
	if title == "禁書" {
		return errors.New("這本不能看")
	}
	fmt.Println("讀完：", title)
	return nil
}

func main() {
	fmt.Println(borrowBook("小王子"))
	fmt.Println()
	fmt.Println(borrowBook("禁書"))
}
```

執行結果：

```text
借出： 小王子
讀完： 小王子
歸還： 小王子
<nil>

借出： 禁書
歸還： 禁書
這本不能看
```

`borrowBook` 有三個 `return`，但我們只寫了一次「歸還」。不管從哪一個離開，「歸還」都會在函式真正結束前執行。注意「歸還」比 `main` 裡印錯誤的那行還早出現：`defer` 是在 `borrowBook` 結束時執行，不是等到整個程式結束。

### 常見用法

之後你會常看到這樣的寫法（第二部會實際用到檔案與網路，現在先認得形狀）：

```go,ignore
f, err := os.Open("data.txt")
if err != nil {
	return err
}
defer f.Close()
```

先檢查錯誤，確定打開成功了，下一行馬上 `defer` 關閉。這樣不管後面的程式碼多長、有幾個 `return`，檔案都一定會被關上。

## 重點整理

- `defer 函式呼叫` 會把這個呼叫延後到目前的函式結束時才執行。
- 不管函式從哪一個 `return` 離開，被 `defer` 的呼叫都會執行。
- `defer` 在包住它的那個函式結束時執行，不是整個程式結束時。
- 常見用法是取得資源後，下一行立刻 `defer` 釋放它。
