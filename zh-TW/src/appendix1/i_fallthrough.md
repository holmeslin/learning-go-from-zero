# `fallthrough`

## 本集目標

知道 Go 的 `switch` 預設不會往下掉，以及需要時怎麼用 `fallthrough` 讓它往下執行。

## 正文

第 1 章學 `switch` 時提過：符合某個 `case` 之後，執行完那段程式碼就會離開 `switch`，不會繼續執行下一個 `case`。如果你學過其他語言，可能知道有些語言剛好相反，每個 `case` 都要自己寫 `break`，忘了寫就會「掉」到下一個 `case`。

Go 選擇了比較安全的預設值。真的需要往下掉時，要明確寫出 `fallthrough`。

### 基本用法

```go
package main

import "fmt"

func main() {
	level := 2
	switch level {
	case 1:
		fmt.Println("解鎖：新手村")
	case 2:
		fmt.Println("解鎖：森林")
		fallthrough
	case 3:
		fmt.Println("解鎖：洞窟")
	case 4:
		fmt.Println("解鎖：城堡")
	}
}
```

執行結果：

```text
解鎖：森林
解鎖：洞窟
```

`level` 是 2，進入 `case 2`。遇到 `fallthrough` 後，程式直接進入下一個 `case 3` 的程式碼。`case 3` 結束時沒有 `fallthrough`，所以就離開了，`case 4` 不會執行。

### 它不會檢查下一個 `case` 的條件

這是最容易誤會的地方：`fallthrough` 是**無條件**跳進下一段，完全不管下一個 `case` 的條件成不成立：

```go
package main

import "fmt"

func main() {
	n := 5
	switch {
	case n > 0:
		fmt.Println("正數")
		fallthrough
	case n > 100:
		fmt.Println("大於 100？")
	}
}
```

執行結果：

```text
正數
大於 100？
```

5 明明不大於 100，第二段還是被執行了。

### 規則

- `fallthrough` 必須是 `case` 裡的**最後一行**。
- 最後一個 `case`（或 `default`）不能寫 `fallthrough`，因為下面已經沒東西可以掉了。
- type switch 裡不能用 `fallthrough`。

### 其實很少用

大部分時候，你想要的其實是「幾個值做同一件事」，那用逗號把值列在同一個 `case` 就好：

```go
package main

import "fmt"

func main() {
	day := "六"
	switch day {
	case "六", "日":
		fmt.Println("週末")
	default:
		fmt.Println("平日")
	}
}
```

執行結果：

```text
週末
```

`fallthrough` 留給「這一段做完，還要接著做下一段」這種少見的情況。

## 重點整理

- Go 的 `switch` 預設執行完一個 `case` 就離開，不會往下掉。
- 在 `case` 最後寫 `fallthrough`，會接著執行下一個 `case` 的程式碼。
- `fallthrough` 不會檢查下一個 `case` 的條件。
- 多個值做同一件事時，用 `case a, b:` 就好，不需要 `fallthrough`。
