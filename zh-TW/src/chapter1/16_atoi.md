# `strconv.Atoi` 與 `err`

## 本集目標

把讀進來的文字轉成整數，並在使用者輸入錯誤時印出提示。

## 正文

上一集說過，讀進來的 `"18"` 是文字，不能直接拿來算。這一集我們把它轉成真正的整數。

### 文字轉整數的固定句型

```go,stdin=18
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入你的年齡：")
	scanner.Scan()
	line := scanner.Text()
	age, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}
	fmt.Println("明年你就", age+1, "歲了")
}
```

輸入 `18`，程式印出：

```text
請輸入你的年齡：
明年你就 19 歲了
```

`age+1` 算出了 19，代表 `age` 真的是整數了。

### 拆開來看

新的部分是這幾行，一樣**先照抄**：

```go,ignore
n, err := strconv.Atoi(line)
if err != nil {
	fmt.Println("請輸入整數")
	return
}
```

- `strconv.Atoi(line)` 會把文字 `line` 轉成整數。用到它時，`import` 要加上 `"strconv"`。
- 它一次給出**兩個**結果：左邊的 `n` 是轉好的整數，右邊的 `err` 代表「轉換有沒有出錯」。為什麼可以一次給兩個，第 2 章會解釋。
- `if err != nil` 的意思是「如果出錯了」。`nil` 在這裡可以理解成「沒有錯誤」，所以 `err != nil` 就是「有錯誤」。`err` 的詳細用法在第 5 章。
- `return` 會讓程式在這裡直接結束，後面的程式碼都不執行。

左邊的變數名稱可以自己取，例如上面的範例取成 `age`；`err` 照慣例都叫 `err`。

### 輸入不是整數的時候

如果使用者打的是 `十八`，`strconv.Atoi` 沒辦法把它轉成整數，`err` 就不會是 `nil`：

```go,stdin=十八
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入你的年齡：")
	scanner.Scan()
	line := scanner.Text()
	age, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}
	fmt.Println("明年你就", age+1, "歲了")
}
```

輸入 `十八`，程式印出：

```text
請輸入你的年齡：
請輸入整數
```

程式印出提示後就結束了，最後一行沒有被執行。像 `3.5`、空白一行，或是數字前後多打了空格，也都會被當成錯誤。

使用者常常會打錯，所以只要是把文字轉成整數，就一定要寫 `if err != nil` 這一段檢查。

## 重點整理

- `n, err := strconv.Atoi(line)` 把文字轉成整數，`import` 要加 `"strconv"`。
- 轉換失敗時 `err != nil`，這時印出提示並用 `return` 結束程式。
- 每次轉換都要接著寫 `if err != nil` 的檢查。
