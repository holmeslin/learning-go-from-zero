# 自己寫迭代器

## 本集目標

綜合前面學到的東西，寫出幾種實用的迭代器：無限序列、過濾、以及讓自訂型別提供 `All` 方法。

## 正文

### 無限序列

迭代器不一定要有盡頭。下面的費氏數列會一直交出下一個數字，由使用的人決定什麼時候 `break`：

```go
package main

import (
	"fmt"
	"iter"
)

func fibonacci() iter.Seq[int] {
	return func(yield func(int) bool) {
		a, b := 0, 1
		for {
			if !yield(a) {
				return
			}
			a, b = b, a+b
		}
	}
}

func main() {
	for n := range fibonacci() {
		if n > 50 {
			break
		}
		fmt.Print(n, " ")
	}
	fmt.Println()
}
```

執行結果：

```text
0 1 1 2 3 5 8 13 21 34 
```

`fibonacci` 裡是一個無限迴圈，能結束全靠 `if !yield(a) { return }`。這也是為什麼第 4 集一再強調要檢查 `yield` 的回傳值：少了這行，迴圈 `break` 時程式會 `panic`。

迭代器只在被要求時才計算下一個值，所以「無限長」完全不是問題。換成切片的話，我們根本做不出一個無限長的切片。

### 接收迭代器的迭代器

迭代器也可以當參數。下面的 `filter` 接收一個迭代器和一個判斷函式，回傳一個新的迭代器，只交出判斷為 `true` 的值：

```go
package main

import (
	"fmt"
	"iter"
	"slices"
)

func filter[V any](seq iter.Seq[V], keep func(V) bool) iter.Seq[V] {
	return func(yield func(V) bool) {
		for v := range seq {
			if keep(v) {
				if !yield(v) {
					return
				}
			}
		}
	}
}

func main() {
	nums := []int{3, 8, 15, 4, 22, 7}
	isEven := func(n int) bool { return n%2 == 0 }

	for n := range filter(slices.Values(nums), isEven) {
		fmt.Println(n)
	}

	big := slices.Collect(filter(slices.Values(nums), func(n int) bool {
		return n > 10
	}))
	fmt.Println(big)
}
```

執行結果：

```text
8
4
22
[15 22]
```

注意 `filter` 裡面用 `for v := range seq` 走訪傳進來的迭代器，再對符合條件的值呼叫 `yield`。外面 `break` 時，`yield` 回傳 `false`，我們 `return`，裡面那層 `for range seq` 也就跟著結束，整串一起停下來。

這也說明了第 5 集那些函式的用處：`slices.Values(nums)` 把切片變成迭代器，才能交給 `filter`；`slices.Collect` 再把結果收回切片。

### 幫自訂型別加上 `All` 方法

標準庫有個慣例：一個裝了很多東西的型別，會提供名叫 `All` 的方法，回傳走訪全部內容的迭代器。我們自己的型別也可以這樣做：

```go
package main

import (
	"fmt"
	"iter"
)

type Playlist struct {
	songs []string
}

func (p *Playlist) Add(song string) {
	p.songs = append(p.songs, song)
}

func (p *Playlist) All() iter.Seq2[int, string] {
	return func(yield func(int, string) bool) {
		for i, s := range p.songs {
			if !yield(i+1, s) {
				return
			}
		}
	}
}

func main() {
	var p Playlist
	p.Add("小幸運")
	p.Add("晴天")
	p.Add("倔強")

	for no, song := range p.All() {
		fmt.Printf("第 %d 首：%s\n", no, song)
	}
}
```

執行結果：

```text
第 1 首：小幸運
第 2 首：晴天
第 3 首：倔強
```

`songs` 是小寫開頭的欄位，用的人不需要知道裡面是切片，只要 `range p.All()` 就能走訪。以後如果改用別的方式存歌曲，只要 `All` 的寫法跟著改，用的人完全不受影響。

## 重點整理

- 迭代器可以是無限的，靠 `if !yield(v) { return }` 在使用者 `break` 時停下來。
- 迭代器可以接收另一個迭代器，加工後再交出，例如 `filter`。
- 慣例上，裝了很多東西的型別會提供 `All` 方法回傳迭代器。
- 寫迭代器時，每個 `yield` 都要檢查回傳值，這條規則沒有例外。
