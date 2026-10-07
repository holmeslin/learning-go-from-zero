# 自訂錯誤型別

## 本集目標

用 struct 定義自己的錯誤型別，讓錯誤除了文字之外，還能帶著額外的資料。

## 正文

哨兵錯誤能告訴你「是哪一種錯」，但它只是一段固定的文字。有時候呼叫者需要更多資訊，例如：「欄位驗證失敗」時，是哪個欄位？填了什麼值？

這時候就自己定義一個錯誤型別，把資料存在欄位裡。

### 定義錯誤型別

第 1 集就看過：只要有 `Error() string` 方法，就是 `error`。

```go
package main

import "fmt"

type ValidationError struct {
	Field string
	Value int
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("欄位 %s 的值 %d 不合法", e.Field, e.Value)
}

func checkAge(age int) error {
	if age < 0 || age > 150 {
		return &ValidationError{Field: "age", Value: age}
	}
	return nil
}

func main() {
	fmt.Println(checkAge(20))
	fmt.Println(checkAge(-3))
}
```

執行結果：

```text
<nil>
欄位 age 的值 -3 不合法
```

幾個習慣寫法：

- 型別名稱以 `Error` 結尾，例如 `ValidationError`。
- `Error()` 方法通常用指標接收者，回傳時也回傳指標 `&ValidationError{...}`。第 3 章學過，這樣傳遞時不用整個 struct 複製一份。

### 一定要回傳 `error` 型別

`checkAge` 的回傳型別寫的是 `error`，不是 `*ValidationError`。這很重要：第 4 章的「nil 介面陷阱」提過，如果函式回傳的是具體型別的 `nil` 指標，再放進 `error` 介面，它就**不等於** `nil` 了。

所以會出錯的函式，回傳型別一律寫 `error`，沒錯時直接 `return nil`。

### 自訂錯誤也能被包裝

自訂錯誤和其他錯誤一樣，可以用 `%w` 包起來：

```go
package main

import "fmt"

type ValidationError struct {
	Field string
	Value int
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("欄位 %s 的值 %d 不合法", e.Field, e.Value)
}

func checkAge(age int) error {
	if age < 0 || age > 150 {
		return &ValidationError{Field: "age", Value: age}
	}
	return nil
}

func register(name string, age int) error {
	if err := checkAge(age); err != nil {
		return fmt.Errorf("註冊 %s：%w", name, err)
	}
	return nil
}

func main() {
	err := register("小美", 200)
	fmt.Println(err)
}
```

執行結果：

```text
註冊 小美：欄位 age 的值 200 不合法
```

可是現在問題來了：`err` 是一個包裝過的錯誤，我們要怎麼把裡面那個 `*ValidationError` 拿出來，讀它的 `Field` 和 `Value`？第 4 章的型別斷言 `err.(*ValidationError)` 只看最外層，會失敗。下一集的 `errors.As` 就是答案。

## 重點整理

- 自訂錯誤型別通常是 struct，用欄位存放額外資訊，再實作 `Error() string`。
- 習慣以 `Error` 結尾命名，用指標接收者，回傳 `&MyError{...}`。
- 函式的回傳型別要寫 `error`，不要寫具體的錯誤型別，避免 nil 介面陷阱。
- 自訂錯誤也能用 `%w` 包裝。
