# comma-ok

## 本集目標

用 `v, ok := m[k]` 分辨「鍵存在但值是零值」和「鍵根本不存在」。

## 正文

上一集遇到一個問題：查不到的鍵會得到零值。那 `scores["阿強"]` 回傳 0 時，到底是阿強考了 0 分，還是根本沒有阿強？

### 多接一個 `ok`

查 map 時，可以在左邊放**兩個**變數：

```go
package main

import "fmt"

func main() {
	scores := map[string]int{
		"小明": 90,
		"小華": 0,
	}

	v, ok := scores["小華"]
	fmt.Println(v, ok)

	v, ok = scores["阿強"]
	fmt.Println(v, ok)
}
```

執行結果：

```text
0 true
0 false
```

第二個值 `ok` 是 `bool`：鍵存在就是 `true`，不存在就是 `false`。兩次查到的值都是 0，但 `ok` 讓我們分得清楚：小華真的考了 0 分，阿強則不在名單裡。

這種寫法因為長得像「值，逗號，ok」，大家都叫它 **comma-ok**。變數名稱可以自己取，但習慣上第二個就叫 `ok`。

### 實際用法：先檢查再使用

```go,stdin=芭樂
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	prices := map[string]int{
		"蘋果": 30,
		"香蕉": 15,
	}

	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	fruit := scanner.Text()

	price, ok := prices[fruit]
	if !ok {
		fmt.Println("沒有賣", fruit)
		return
	}
	fmt.Println(fruit, "一個", price, "元")
}
```

輸入 `芭樂` 的執行結果：

```text
沒有賣 芭樂
```

這裡用上了第 11 集的 early return：找不到就先處理掉並離開，後面就可以安心使用 `price`。

### 只想知道在不在

只關心鍵存不存在、不在乎值的話，前面用 `_`：

```go
package main

import "fmt"

func main() {
	members := map[string]bool{
		"小明": true,
		"小華": true,
	}
	_, ok := members["阿強"]
	fmt.Println("阿強是會員嗎？", ok)
}
```

執行結果：

```text
阿強是會員嗎？ false
```

### 看起來很眼熟？

`v, ok := m[k]` 和 `n, err := strconv.Atoi(line)` 長得很像，都是「值 + 一個告訴你狀況的東西」。不過 comma-ok 是 map 查詢的特殊語法，不是函式的多個回傳值：只寫 `v := m[k]` 也可以，Go 會讓你選擇要不要那個 `ok`。

## 重點整理

- `v, ok := m[k]`：`ok` 為 `true` 表示鍵存在，`false` 表示不存在（此時 `v` 是零值）。
- 用 `ok` 可以分辨「值剛好是零值」和「鍵不存在」。
- 常見寫法是 `if !ok { ...; return }` 先處理找不到的情況。
- 只想知道鍵存不存在時，寫 `_, ok := m[k]`。
