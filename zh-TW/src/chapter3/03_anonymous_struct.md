# 匿名 struct

## 本集目標

知道怎麼建立沒有名字的 struct，以及它適合用在什麼地方。

## 正文

前兩集我們都先用 `type Person struct { ... }` 取好名字，再拿來用。如果某個 struct 只在一個地方用一次，特地取名字有點多餘，這時可以用**匿名 struct**。

### 直接寫出 struct 的樣子

```go
package main

import "fmt"

func main() {
	point := struct {
		X int
		Y int
	}{X: 3, Y: 4}
	fmt.Printf("%+v\n", point)
	fmt.Println(point.X + point.Y)
}
```

執行結果：

```text
{X:3 Y:4}
7
```

拆開來看：

- `struct { X int; Y int }` 這一段就是型別本身，只是沒有用 `type` 取名字。
- 後面緊接著的 `{X: 3, Y: 4}` 是 literal，跟上一集的寫法一樣。

用起來跟有名字的 struct 沒有差別，一樣用 `.` 讀寫欄位。

相同型別的欄位可以寫在同一行，用逗號隔開，例如 `struct { X, Y int }`。這個寫法在有名字的 struct 裡也能用。

### 常見用途：一組測試資料

匿名 struct 最常出現的地方，是「一次性的資料表」。例如我們想檢查一個函式在好幾種輸入下的結果：

```go
package main

import "fmt"

func double(n int) int {
	return n * 2
}

func main() {
	cases := []struct {
		in   int
		want int
	}{
		{in: 1, want: 2},
		{in: 5, want: 10},
		{in: -3, want: -6},
	}
	for _, c := range cases {
		got := double(c.in)
		fmt.Println(c.in, "->", got, got == c.want)
	}
}
```

執行結果：

```text
1 -> 2 true
5 -> 10 true
-3 -> -6 true
```

`[]struct { in int; want int }` 是「匿名 struct 的切片」。切片 literal 裡的每個元素，型別已經確定了，所以直接寫 `{in: 1, want: 2}` 就好，不用再重複一次 `struct { ... }`。

這種寫法在第 8 章學測試時會常常看到。

### 什麼時候該取名字？

如果同樣的 struct 要在兩個以上的地方用，或是要當函式的參數、回傳值，就該用 `type` 取個名字。匿名 struct 每次都要把整個型別寫一遍，用多了反而難讀。

## 重點整理

- 匿名 struct 是沒有 `type` 名字的 struct，寫法是 `struct { 欄位 型別 }{ 值 }`。
- 讀寫欄位的方式和有名字的 struct 一樣。
- 適合只用一次的資料，例如一組測試資料 `[]struct{ ... }{ ... }`。
- 會在多處使用的 struct，還是用 `type` 取名字比較好。
