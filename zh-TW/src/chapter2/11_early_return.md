# early `return`

## 本集目標

學會「提早 `return`」：先把不合格的情況處理掉，讓主要邏輯不用一層一層往內縮。

## 正文

### 一層包一層的 `if`

假設我們要寫一個函式，判斷成績等第。成績要在 0 到 100 之間才算有效：

```go
package main

import "fmt"

func grade(score int) string {
	if score >= 0 {
		if score <= 100 {
			if score >= 60 {
				return "及格"
			} else {
				return "不及格"
			}
		} else {
			return "成績無效"
		}
	} else {
		return "成績無效"
	}
}

func main() {
	fmt.Println(grade(75))
	fmt.Println(grade(120))
}
```

執行結果：

```text
及格
成績無效
```

能跑，但很難讀。真正重要的「及格／不及格」被埋在第三層，而且每個 `else` 要對到哪個 `if`，得用手指一個一個對。

### 先處理例外，再處理正事

`return` 會立刻離開函式。利用這一點，我們可以**先把不合格的情況擋掉**，剩下的程式碼就只需要處理正常情況：

```go
package main

import "fmt"

func grade(score int) string {
	if score < 0 || score > 100 {
		return "成績無效"
	}
	if score >= 60 {
		return "及格"
	}
	return "不及格"
}

func main() {
	fmt.Println(grade(75))
	fmt.Println(grade(120))
	fmt.Println(grade(42))
}
```

執行結果：

```text
及格
成績無效
不及格
```

一樣的功能，但讀起來像在講話：「無效就回傳無效；及格就回傳及格；剩下的就是不及格。」沒有任何 `else`，程式碼也不再往右縮。

這種寫法叫做 **early return**（提早回傳），也有人叫它「守衛子句」（guard clause）。Go 的程式碼非常喜歡這種風格：**例外情況處理完就離開，正常流程留在最左邊**。

### 你早就在用了

其實固定句型裡就有 early return：

```go,ignore
n, err := strconv.Atoi(line)
if err != nil {
	fmt.Println("請輸入整數")
	return
}
// 走到這裡，n 一定是正確的整數
```

在 `main` 裡，`return` 一樣會讓函式結束。`main` 沒有回傳值，所以只寫 `return`。`main` 一結束，整個程式就結束了。

## 重點整理

- 巢狀很深的 `if`/`else` 不好讀，也容易出錯。
- early return：先用 `if` 檢查例外情況並立刻 `return`，主要邏輯留在最外層。
- 這樣寫通常可以省掉 `else`，是 Go 程式最常見的風格。
- 在 `main` 裡寫 `return` 會結束 `main`，也就結束整個程式。
