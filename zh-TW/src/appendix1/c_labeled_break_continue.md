# 標籤 `break` / `continue`

## 本集目標

在巢狀迴圈中，用標籤一次跳出外層迴圈，或直接進入外層迴圈的下一輪。

## 正文

`break` 和 `continue` 只會影響**最靠近的那一層**迴圈。巢狀迴圈時，這常常不是我們想要的。

### 問題：`break` 只跳出內層

假設我們要在一個二維的座位表裡找空位，找到第一個就停：

```go
package main

import "fmt"

func main() {
	seats := [][]string{
		{"A", "B", "C"},
		{"D", "", "F"},
		{"", "H", "I"},
	}

	for row := range seats {
		for col := range seats[row] {
			if seats[row][col] == "" {
				fmt.Println("空位在", row, col)
				break
			}
		}
	}
}
```

執行結果：

```text
空位在 1 1
空位在 2 0
```

明明只想要第一個空位，卻印了兩個。`break` 只跳出了內層的 `col` 迴圈，外層的 `row` 迴圈照樣繼續跑下一列。

### 給迴圈取名字：標籤

在迴圈前面寫上一個名字加冒號，就是**標籤**。`break` 後面接標籤名稱，就會直接跳出那一層：

```go
package main

import "fmt"

func main() {
	seats := [][]string{
		{"A", "B", "C"},
		{"D", "", "F"},
		{"", "H", "I"},
	}

search:
	for row := range seats {
		for col := range seats[row] {
			if seats[row][col] == "" {
				fmt.Println("空位在", row, col)
				break search
			}
		}
	}
	fmt.Println("搜尋結束")
}
```

執行結果：

```text
空位在 1 1
搜尋結束
```

`break search` 一口氣跳出兩層迴圈，接著執行迴圈後面的程式碼。標籤名稱自己取，慣例是用小寫、說明用途的單字，`gofmt` 會把它往左縮排一格，讓它比較顯眼。

### 標籤 `continue`

`continue` 也能接標籤，意思是「直接進入那一層迴圈的下一輪」。例如找出每一列裡有沒有負數，有的話就跳過整列：

```go
package main

import "fmt"

func main() {
	rows := [][]int{
		{1, 2, 3},
		{4, -5, 6},
		{7, 8, 9},
	}

rowLoop:
	for i, row := range rows {
		sum := 0
		for _, n := range row {
			if n < 0 {
				fmt.Println("第", i, "列有負數，跳過")
				continue rowLoop
			}
			sum += n
		}
		fmt.Println("第", i, "列總和", sum)
	}
}
```

執行結果：

```text
第 0 列總和 6
第 1 列有負數，跳過
第 2 列總和 24
```

遇到 `-5` 時，`continue rowLoop` 讓程式放棄這一列剩下的數字，也跳過印總和那一行，直接開始外層的下一輪。

### 小提醒

- 宣告了標籤卻沒用到，Go 會編譯失敗，就像沒用到的變數一樣。
- 標籤也能用在 `switch` 和 `select` 上（`select` 第 9 章會介紹）。在迴圈裡的 `switch` 中寫 `break`，跳出的是 `switch` 而不是迴圈；想跳出迴圈，就給迴圈加標籤。

## 重點整理

- `break`、`continue` 預設只影響最內層的迴圈。
- 在迴圈前寫 `名稱:` 就是標籤；`break 名稱` 跳出那一層迴圈。
- `continue 名稱` 直接進入那一層迴圈的下一輪。
- 宣告了沒用的標籤會編譯失敗。
