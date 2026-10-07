# `continue`

## 本集目標

用 `continue` 跳過這一圈剩下的程式碼，直接進入下一圈。

## 正文

`break` 是「整個迴圈不跑了」。有時候我們只是想「這一圈不要做，但下一圈繼續」，這就是 `continue` 的工作。

### 跳過這一圈

印出 1 到 10 之間的奇數：

```go
package main

import "fmt"

func main() {
	for i := 1; i <= 10; i++ {
		if i%2 == 0 {
			continue
		}
		fmt.Println(i)
	}
}
```

執行結果：

```text
1
3
5
7
9
```

當 `i` 是偶數時，執行 `continue`，**這一圈剩下的程式碼都跳過**（也就是不會印出），直接進入下一圈。在三段式 `for` 裡，跳到下一圈之前還是會先執行 `i++`。

### `break` 和 `continue` 的差別

```go
package main

import "fmt"

func main() {
	for i := range 5 {
		if i == 2 {
			continue
		}
		fmt.Println("continue 版：", i)
	}
	for i := range 5 {
		if i == 2 {
			break
		}
		fmt.Println("break 版：", i)
	}
}
```

執行結果：

```text
continue 版： 0
continue 版： 1
continue 版： 3
continue 版： 4
break 版： 0
break 版： 1
```

- `continue`：只跳過 `i == 2` 那一圈，後面的 3、4 照樣執行。
- `break`：遇到 `i == 2` 就整個迴圈結束，3、4 都不會執行。

### 用 `continue` 減少縮排

`continue` 常用來「先把不要的情況排除掉」。例如加總 1 到 20 之間，不是 3 的倍數的數：

```go
package main

import "fmt"

func main() {
	sum := 0
	for i := 1; i <= 20; i++ {
		if i%3 == 0 {
			continue
		}
		sum += i
	}
	fmt.Println(sum)
}
```

執行結果：

```text
147
```

先用 `continue` 把 3 的倍數排除，剩下的程式碼就專心處理「要的情況」，不用整段包在 `if` 裡面。

和 `break` 一樣，在巢狀迴圈裡 `continue` 只會影響最近的那一層迴圈。

## 重點整理

- `continue` 會跳過這一圈剩下的程式碼，直接進入下一圈。
- 三段式 `for` 遇到 `continue` 時，仍會先執行更新（例如 `i++`）再進入下一圈。
- `break` 結束整個迴圈；`continue` 只跳過這一圈。
- `continue` 適合用來先排除不要的情況。
