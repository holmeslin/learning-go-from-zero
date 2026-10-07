# 讀取輸入

## 本集目標

讓程式在執行時停下來，讀取使用者打的一行文字。

## 正文

到目前為止，程式裡的資料都是我們事先寫死的。要讓程式真的「有互動」，就得讓使用者在執行時輸入資料。

### 讀一行輸入的固定句型

```go,stdin=小明
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入你的名字：")
	scanner.Scan()
	name := scanner.Text()
	fmt.Println("你好，", name)
}
```

執行 `go run .` 之後，程式會印出「請輸入你的名字：」然後停下來等你。打字，按 Enter，程式才會繼續。假設你輸入 `小明`，畫面上程式印出的內容是：

```text
請輸入你的名字：
你好， 小明
```

（你自己打的 `小明` 也會出現在畫面上，在兩行中間，這裡只列出程式印出來的部分。）

### 拆開來看

這次的程式碼有幾個新東西，**現在先照抄就好**，原理會在第 3 章（方法）和第 4 章（介面）解釋。我們只要知道怎麼用：

```go,ignore
scanner := bufio.NewScanner(os.Stdin)
scanner.Scan()
line := scanner.Text()
```

- 第一行：準備一個專門讀輸入的 `scanner`。一支程式只要寫一次。
- 第二行：`scanner.Scan()` 讓程式停下來，等使用者打完一行、按下 Enter。
- 第三行：`scanner.Text()` 拿到剛剛那一行文字（不包含 Enter），存進變數。變數名稱可以自己取。

另外 `import` 的地方也變了。因為這次除了 `fmt`，還用到 `bufio` 和 `os`，所以改成用小括號把它們一行一個列出來，依照字母順序排好。

### 讀好幾行

要讀第二行，就再寫一次第二、三行，`scanner` 不用重新建立：

```go,stdin=小明\n台北
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("名字：")
	scanner.Scan()
	name := scanner.Text()
	fmt.Println("住在哪裡：")
	scanner.Scan()
	city := scanner.Text()
	fmt.Println(name, "住在", city)
}
```

輸入 `小明` 和 `台北`，程式印出：

```text
名字：
住在哪裡：
小明 住在 台北
```

### 讀進來的都是文字

注意：就算使用者打的是數字，例如 `18`，`scanner.Text()` 拿到的也是**文字** `"18"`，不是數字 18，不能直接拿來做加減。下一集會教怎麼把它轉成數字。

## 重點整理

- 讀一行輸入：先建立一次 `scanner := bufio.NewScanner(os.Stdin)`，之後每讀一行就寫 `scanner.Scan()` 和 `變數 := scanner.Text()`。
- 用到多個套件時，`import` 改用小括號、一行一個、照字母排序。
- 讀進來的內容一律是文字，即使使用者打的是數字。
