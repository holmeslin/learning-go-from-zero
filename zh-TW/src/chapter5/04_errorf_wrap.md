# `fmt.Errorf` 與 `%w`

## 本集目標

用 `fmt.Errorf` 做出帶有格式的錯誤訊息，並用 `%w` 把原本的錯誤「包」在新的錯誤裡面。

## 正文

上一集的 `parseAge` 把錯誤原封不動往上交，印出來是 `strconv.Atoi: parsing "十八": invalid syntax`。看到這行字的人只知道「某個東西轉整數失敗」，卻不知道是在讀年齡的時候出錯的。

我們想在錯誤前面加上一點說明。

### `fmt.Errorf`：像 `Printf` 一樣做錯誤

`fmt.Errorf` 的用法跟 `fmt.Printf` 一樣，可以用格式動詞，只是它不印出來，而是回傳一個 `error`：

```go
package main

import "fmt"

func main() {
	score := 120
	err := fmt.Errorf("分數 %d 超過上限 100", score)
	fmt.Println(err)
}
```

執行結果：

```text
分數 120 超過上限 100
```

### 用 `%w` 包裝錯誤

`fmt.Errorf` 有一個專屬的格式動詞 `%w`（w 是 wrap，包裝）。把原本的錯誤放到 `%w` 的位置，就能在它前面加上說明：

```go
package main

import (
	"fmt"
	"strconv"
)

func parseAge(s string) (int, error) {
	age, err := strconv.Atoi(s)
	if err != nil {
		return 0, fmt.Errorf("讀取年齡失敗：%w", err)
	}
	return age, nil
}

func main() {
	_, err := parseAge("十八")
	if err != nil {
		fmt.Println(err)
	}
}
```

執行結果：

```text
讀取年齡失敗：strconv.Atoi: parsing "十八": invalid syntax
```

現在一看就知道是讀年齡出錯，原因是轉整數失敗。

### 一層一層包上去

錯誤往上傳的時候，每一層都可以再包一次，加上自己知道的資訊：

```go
package main

import (
	"fmt"
	"strconv"
)

func parseAge(s string) (int, error) {
	age, err := strconv.Atoi(s)
	if err != nil {
		return 0, fmt.Errorf("讀取年齡失敗：%w", err)
	}
	return age, nil
}

func register(name, ageText string) error {
	_, err := parseAge(ageText)
	if err != nil {
		return fmt.Errorf("註冊 %s 失敗：%w", name, err)
	}
	return nil
}

func main() {
	err := register("小明", "abc")
	fmt.Println(err)
}
```

執行結果：

```text
註冊 小明 失敗：讀取年齡失敗：strconv.Atoi: parsing "abc": invalid syntax
```

訊息從左到右讀，就像一條路線：哪一步失敗、為什麼失敗。

### `%w` 和 `%v` 差在哪？

把 `%w` 換成 `%v`，印出來的文字**一模一樣**。差別在看不見的地方：用 `%w` 時，新錯誤裡面還「保留」著原本那個錯誤，之後可以把它拿出來檢查；用 `%v` 只是把文字抄過去，原本的錯誤就不見了。

要怎麼「拿出來檢查」，接下來幾集的 `errors.Is` 和 `errors.As` 會教。現在先記得：**要包裝錯誤就用 `%w`**。

## 重點整理

- `fmt.Errorf` 跟 `fmt.Printf` 一樣能用格式動詞，但會回傳一個 `error`。
- `%w` 會把原本的錯誤包在新錯誤裡，同時在前面加上說明。
- 每一層都可以再包一次，訊息會串成一條完整的路線。
- `%w` 和 `%v` 印出的文字相同，但只有 `%w` 會保留原本的錯誤。
