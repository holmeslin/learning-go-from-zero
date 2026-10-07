# Example 測試

## 本集目標

寫一個 Example 函式，它既是說明文件裡的使用範例，也是會被 `go test` 檢查輸出的測試。

## 正文

### 會被檢查的範例

寫文件時，最有說服力的就是一段範例程式。但文件裡的範例有個老問題：程式改了，範例忘了改，範例就變成錯的。

Go 的解法是 **Example 函式**：把範例寫成程式，並在最後用註解寫出「應該印出什麼」。`go test` 會真的執行它，比對印出來的內容。範例一旦過時，測試就會失敗。

### 寫一個 Example

`greet/example_test.go`：

```go,ignore
package greet_test

import (
	"fmt"

	"myapp/greet"
)

func ExampleHello() {
	fmt.Println(greet.Hello("小明"))
	fmt.Println(greet.Hello(""))
	// Output:
	// 你好，小明！
	// 你好，朋友！
}
```

幾個要注意的地方：

- 函式名稱是 `Example` 加上要示範的名稱，`ExampleHello` 就是 `Hello` 的範例。沒有參數，也沒有回傳值。
- 最後的 `// Output:` 註解寫出預期的輸出，一行對一行。
- 第一行是 `package greet_test`，不是 `package greet`。

### `package greet_test` 是什麼

`_test.go` 檔可以宣告成「套件名稱加上 `_test`」，這樣它就是一個**獨立的測試套件**，站在使用者的角度測試 `greet`：必須 `import "myapp/greet"`，只能使用大寫匯出的名稱，呼叫時也要寫 `greet.Hello`。

範例是寫給使用者看的，所以通常放在 `_test` 套件裡，看起來就和使用者實際寫的程式一模一樣。

### 執行

```bash
go test -v -run Example ./greet
```

```text
=== RUN   ExampleHello
--- PASS: ExampleHello (0.00s)
PASS
ok  	myapp/greet	0.647s
```

`-run Example` 只執行名稱含有 `Example` 的測試。平常直接 `go test` 的話，Example 會和其他測試一起執行。秒數每次不同。

### 輸出對不上的時候

把 `// 你好，朋友！` 故意改成 `// 你好，！`，執行 `go test ./greet`：

```text
--- FAIL: ExampleHello (0.00s)
got:
你好，小明！
你好，朋友！
want:
你好，小明！
你好，！
FAIL
FAIL	myapp/greet	0.543s
FAIL
```

`got` 是實際印出的內容，`want` 是 `// Output:` 寫的內容，差在哪裡一目了然。

### 範例會出現在文件裡

Example 函式會出現在套件的網頁版文件中（例如 pkg.go.dev 這類網站），顯示在 `Hello` 的說明下方，讀者可以直接看到正確的用法。標準庫裡有大量這種範例，`go doc` 的文字輸出則不會顯示它們。

如果範例的輸出每次都不一樣（例如有隨機數），可以不寫 `// Output:`。這樣 `go test` 只會編譯、不會執行它，但它仍然會出現在文件裡。

## 重點整理

- Example 函式名稱是 `Example` 加上要示範的名稱，例如 `ExampleHello`，寫在 `_test.go` 檔裡。
- `// Output:` 註解寫出預期輸出，`go test` 會執行並比對，不符就失敗。
- 套件名稱寫成 `greet_test`，就是站在使用者角度、只能使用匯出名稱的測試套件。
- Example 同時是文件中的範例；沒有 `// Output:` 的 Example 只編譯不執行。
