# `sync.Once` 與 `OnceValue`

## 本集目標

學會用 `sync.Once`、`sync.OnceFunc`、`sync.OnceValue`、`sync.OnceValues` 讓某件事只做一次，不管有多少個 goroutine 同時要求。

## 正文

### 只做一次的工作

有些工作只需要做一次，例如讀取設定檔、建立一份很大的對照表。如果好幾個 goroutine 都需要它，我們希望：第一個需要的人去做，其他人等它做完直接用結果，而且絕對不會做第二次。

自己用 `if` 加一個 `bool` 判斷，在並行程式裡會有 data race；加上 `Mutex` 雖然可以，但很囉嗦。`sync` 套件已經準備好現成的工具。

### `sync.Once`

`sync.Once` 有一個 `Do` 方法，傳進去的函式只會被執行一次：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var once sync.Once
	var wg sync.WaitGroup
	for range 5 {
		wg.Go(func() {
			once.Do(func() {
				fmt.Println("初始化")
			})
		})
	}
	wg.Wait()
	fmt.Println("完成")
}
```

執行結果：

```text
初始化
完成
```

5 個 goroutine 都呼叫了 `once.Do`，但「初始化」只印了一次。而且其他 goroutine 呼叫 `Do` 時，如果第一個人還在做，它們會**等到做完**才回傳，所以 `Do` 回傳之後，初始化一定已經完成了。

### `sync.OnceFunc`

Go 1.21 起，有更方便的三個函式。`sync.OnceFunc` 把一個函式包起來，回傳一個「不管呼叫幾次，都只會真正執行一次」的新函式：

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	setup := sync.OnceFunc(func() {
		fmt.Println("連線到伺服器")
	})
	setup()
	setup()
	setup()
	fmt.Println("完成")
}
```

執行結果：

```text
連線到伺服器
完成
```

這樣就不用另外宣告一個 `sync.Once` 變數。

### `sync.OnceValue`：只算一次，記住結果

更常見的需求是：算一次，之後一直用同一個結果。`sync.OnceValue` 接收一個有回傳值的函式，回傳的新函式第一次呼叫時去算，之後直接回傳記住的值：

```go
package main

import (
	"fmt"
	"sync"
)

var loadTable = sync.OnceValue(func() map[string]int {
	fmt.Println("建立對照表")
	return map[string]int{"一": 1, "二": 2, "三": 3}
})

func main() {
	var wg sync.WaitGroup
	results := make([]int, 3)
	for i, word := range []string{"一", "二", "三"} {
		wg.Go(func() {
			results[i] = loadTable()[word]
		})
	}
	wg.Wait()
	fmt.Println(results)
}
```

執行結果：

```text
建立對照表
[1 2 3]
```

`OnceValue` 是泛型函式（第 6 章），回傳值的型別會自動推論，這裡是 `func() map[string]int`。把它放在套件層級的變數，整個程式都能共用同一份。

### `sync.OnceValues`：連 `error` 一起記住

會失敗的初始化通常回傳兩個值：結果和 `error`。這時用 `sync.OnceValues`：

```go
package main

import (
	"errors"
	"fmt"
	"sync"
)

var loadConfig = sync.OnceValues(func() (string, error) {
	fmt.Println("讀取設定")
	return "", errors.New("找不到設定檔")
})

func main() {
	for range 2 {
		cfg, err := loadConfig()
		if err != nil {
			fmt.Println("錯誤：", err)
			continue
		}
		fmt.Println(cfg)
	}
}
```

執行結果：

```text
讀取設定
錯誤： 找不到設定檔
錯誤： 找不到設定檔
```

注意：就算第一次失敗了，之後也**不會重試**，每次都回傳同一個錯誤。如果需要「失敗就重試」，就不適合用這些工具。

### 該用哪一個

| 需求 | 工具 |
| --- | --- |
| 只做一次，沒有回傳值 | `sync.OnceFunc`（或 `sync.Once`） |
| 只算一次，記住一個結果 | `sync.OnceValue` |
| 只算一次，記住結果和 `error` | `sync.OnceValues` |

`sync.Once` 在舊程式裡很常見，新程式通常用後面三個比較簡潔。

## 重點整理

- `sync.Once` 的 `Do` 保證傳入的函式只執行一次，其他呼叫者會等它做完。
- `sync.OnceFunc` 回傳一個只會真正執行一次的函式。
- `sync.OnceValue`、`sync.OnceValues` 只算一次並記住結果，後者可以連 `error` 一起回傳。
- 第一次的結果（包括錯誤）會一直被沿用，不會重試。
