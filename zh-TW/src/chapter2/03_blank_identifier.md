# 底線 `_`

## 本集目標

認識底線 `_`：一個「我拿到了，但我不要」的特殊名字。

## 正文

第 1 章我們遇過一個 Go 的規矩：宣告了變數卻沒用到，程式就不能編譯。這個規矩可以幫我們抓出寫錯的地方，但有時候某個值我們**就是**用不到，這時就需要 `_`。

### 用不到的值，交給 `_`

還記得把文字轉成整數的固定句型嗎？`strconv.Atoi` 會同時給我們兩個東西：轉好的數字 `n` 和錯誤 `err`。假設我們只想知道使用者輸入的「是不是整數」，根本不需要那個數字：

```go,compile_fail
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	line := scanner.Text()

	n, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("這不是整數")
		return
	}
	fmt.Println("是整數")
}
```

這段程式不能編譯，因為 `n` 宣告了卻沒用到：

```text
declared and not used: n
```

把 `n` 換成 `_` 就好了：

```go,stdin=abc
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	line := scanner.Text()

	_, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("這不是整數")
		return
	}
	fmt.Println("是整數")
}
```

輸入 `abc` 的執行結果：

```text
這不是整數
```

`_` 叫做**空白識別字**（blank identifier）。放在 `_` 的值會直接被丟掉，它不是一個真的變數，所以也不會有「沒用到」的問題。

### `_` 不能拿來讀

既然值被丟掉了，`_` 就只能放在等號左邊「接東西」，不能拿來用：

```go,compile_fail
package main

import "fmt"

func main() {
	_ = 5
	fmt.Println(_)
}
```

```text
cannot use _ as value
```

### 之後還會常常見到它

上一集用 `_ = iota` 跳過 0，也是同一個道理：那個值我們不要。之後學到走訪陣列（第 14 集）和 map 的 comma-ok（第 26 集），還會一直遇到 `_`，用法都一樣：**這個位置一定要放東西，但我不需要它。**

## 重點整理

- `_` 是空白識別字，放進去的值會被直接丟掉。
- 某個值一定得接、但用不到時（例如只想檢查 `err`），用 `_` 接，就不會有「宣告了卻沒用到」的編譯錯誤。
- `_` 只能放在等號左邊，不能拿來讀取。
