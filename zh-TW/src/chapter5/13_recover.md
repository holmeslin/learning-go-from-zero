# `recover`

## 本集目標

用 `recover` 在 `defer` 的函式裡攔下 panic，讓程式不要整個結束。

## 正文

上一集說過，panic 發生時，Go 會一路執行各層的 `defer`。`recover` 就是讓你在這個過程中把 panic「接住」的工具。

### `recover` 要在被 `defer` 的函式裡呼叫

內建函式 `recover()` 只有在**被 `defer` 的函式裡**直接呼叫才有用。所以我們先寫一個專門處理 panic 的函式，再用 `defer` 延後呼叫它：

```go
package main

import "fmt"

func handlePanic() {
	if r := recover(); r != nil {
		fmt.Println("接住了 panic：", r)
	}
}

func divide(a, b int) int {
	defer handlePanic()
	return a / b
}

func main() {
	fmt.Println(divide(10, 2))
	fmt.Println(divide(10, 0))
	fmt.Println("程式繼續執行")
}
```

執行結果：

```text
5
接住了 panic： runtime error: integer divide by zero
0
程式繼續執行
```

一步一步看第二次呼叫 `divide(10, 0)`：

1. `a / b` 除以 0，發生 panic。
2. `divide` 停下來，開始執行它的 `defer`，也就是 `handlePanic()`。
3. `handlePanic` 裡的 `recover()` 拿到 panic 的值，panic 就此結束。
4. `divide` 正常回到 `main`，回傳值是 `int` 的零值 `0`。
5. `main` 繼續往下執行，印出「程式繼續執行」。

### `recover` 的回傳值

`recover()` 的回傳型別是 `any`（第 4 章學過，可以裝任何值）：

- 有 panic 正在發生時，回傳當初傳給 `panic` 的值；如果是執行期錯誤（像除以 0），回傳的值本身也是一個 `error`。
- 沒有 panic 時，回傳 `nil`。

所以 `if r := recover(); r != nil` 這個寫法，意思是「如果真的有 panic，就處理它」。第一次呼叫 `divide(10, 2)` 沒有 panic，`handlePanic` 也有執行，只是 `recover()` 回傳 `nil`，什麼都不印。

### 在其他地方呼叫沒有效果

如果不是在被 `defer` 的函式裡呼叫，`recover()` 永遠回傳 `nil`，攔不到任何東西：

```go
package main

import "fmt"

func main() {
	r := recover()
	fmt.Println(r)
}
```

執行結果：

```text
<nil>
```

這裡沒有 panic，`recover` 也不在 `defer` 裡，單純回傳 `nil`。

### 以後會常看到的寫法

很多程式會把處理 panic 的函式直接寫在 `defer` 後面，不另外取名字：

```go,ignore
defer func() {
	if r := recover(); r != nil {
		fmt.Println("接住了 panic：", r)
	}
}()
```

這種沒有名字的函式叫做「匿名函式」，第 6 章會正式介紹。效果和上面的 `defer handlePanic()` 一樣，現在先認得這個形狀就好。

### 不要濫用

`recover` 不是用來取代 `error` 的。一般的錯誤還是用 `error` 回傳；`recover` 只用在少數場合，例如伺服器處理某一個請求時出了 bug，我們不希望整台伺服器跟著停掉。

## 重點整理

- `recover()` 能接住 panic，讓程式繼續執行，但只有在被 `defer` 的函式裡直接呼叫才有效。
- 常見寫法是寫一個處理函式，再 `defer handlePanic()`。
- `recover()` 回傳 `any`：有 panic 時是 panic 的值，沒有時是 `nil`。
- 被接住後，發生 panic 的函式會正常回到呼叫者，回傳值是零值（除非另外設定）。
- 一般錯誤還是用 `error`，`recover` 只留給少數必要的場合。
