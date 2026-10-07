# 用 `reflect` 讀取 struct tag

## 本集目標

學會用 `reflect` 走訪 struct 的欄位、讀出 struct tag，並寫一個簡單的「必填欄位檢查」，理解 `encoding/json` 這類套件是怎麼看懂 tag 的。

## 正文

### tag 是誰在讀？

附錄一 k 說過：struct tag 對 Go 語言本身只是一段字串，意義由讀取它的套件決定。那套件是怎麼讀到的？答案就是反射。

### 走訪 struct 的欄位

`reflect.TypeFor[T]()` 直接用型別參數（第 6 章）取得 `T` 的型別資訊，不用先做出一個值。struct 型別的 `Fields()` 方法會回傳一個迭代器（第 7 章），一個一個交出欄位的資訊：

```go
package main

import (
	"fmt"
	"reflect"
)

type User struct {
	Name  string `json:"name" validate:"required"`
	Email string `json:"email,omitempty"`
	Age   int
}

func main() {
	t := reflect.TypeFor[User]()
	for f := range t.Fields() {
		fmt.Println(f.Name, f.Type, f.Tag)
	}
}
```

執行結果：

```text
Name string json:"name" validate:"required"
Email string json:"email,omitempty"
Age int 
```

每個 `f` 是 `reflect.StructField`，裡面有欄位名稱 `Name`、型別 `Type`，以及 tag `Tag`。`Age` 沒有 tag，所以後面是空的。

`Fields()` 是 Go 1.26 加入的。在比較舊的程式碼裡，你會看到 `for i := range t.NumField()` 搭配 `t.Field(i)` 的寫法，效果一樣。

### `Get` 與 `Lookup`

`f.Tag` 的型別是 `reflect.StructTag`，用 `Get` 取出某一把鑰匙的值：

```go
package main

import (
	"fmt"
	"reflect"
)

type User struct {
	Name  string `json:"name" validate:"required"`
	Email string `json:"email,omitempty"`
	Note  string `json:""`
	Age   int
}

func main() {
	for f := range reflect.TypeFor[User]().Fields() {
		name, ok := f.Tag.Lookup("json")
		fmt.Printf("%s: json=%q 有寫=%v validate=%q\n", f.Name, name, ok, f.Tag.Get("validate"))
	}
}
```

執行結果：

```text
Name: json="name" 有寫=true validate="required"
Email: json="email,omitempty" 有寫=true validate=""
Note: json="" 有寫=true validate=""
Age: json="" 有寫=false validate=""
```

- `Get("validate")` 回傳那把鑰匙的值，沒有就是空字串。
- `Lookup("json")` 多回傳一個 `bool`（comma-ok），可以分辨「寫了但值是空的」（`Note`）和「根本沒寫」（`Age`）。
- 值裡面的逗號選項，例如 `omitempty`，`reflect` 不會幫你拆，要自己用 `strings.Split` 之類的函式處理。

### 動手做：必填欄位檢查

把型別資訊和值結合起來，就能寫出一個小型驗證器：凡是標了 `validate:"required"` 的欄位，值不能是零值。`reflect.Value` 也有 `Fields()` 方法，一次交出欄位資訊和欄位的值：

```go
package main

import (
	"errors"
	"fmt"
	"reflect"
)

type User struct {
	Name  string `validate:"required"`
	Email string `validate:"required"`
	Age   int
}

type Product struct {
	Title string  `validate:"required"`
	Price float64 `validate:"required"`
}

func validate(x any) error {
	v := reflect.ValueOf(x)
	if v.Kind() != reflect.Struct {
		return errors.New("只能檢查 struct")
	}
	var errs []error
	for f, fv := range v.Fields() {
		if f.Tag.Get("validate") == "required" && fv.IsZero() {
			errs = append(errs, fmt.Errorf("%s 是必填欄位", f.Name))
		}
	}
	return errors.Join(errs...)
}

func main() {
	fmt.Println(validate(User{Name: "Andy", Email: "andy@example.com"}))
	fmt.Println(validate(User{Age: 30}))
	fmt.Println(validate(Product{Title: "鍵盤"}))
	fmt.Println(validate(42))
}
```

執行結果：

```text
<nil>
Name 是必填欄位
Email 是必填欄位
Price 是必填欄位
只能檢查 struct
```

- `v.Fields()` 交出兩個值：`f` 是欄位資訊（可以讀 tag），`fv` 是這個欄位的 `reflect.Value`。
- `fv.IsZero()` 判斷欄位是不是零值，任何種類都能用。
- 同一個 `validate` 函式，`User`、`Product` 或以後才定義的任何 struct 都能檢查。這就是反射的價值：寫一次，適用於事先不知道的型別。
- 多個錯誤用第 5 章的 `errors.Join` 合在一起，印出來時一個錯誤一行。

`encoding/json` 做的事情本質上一樣：用反射走訪欄位、讀 `json` tag、決定名稱和選項，只是處理的情況多很多。

## 重點整理

- 套件是透過反射讀取 struct tag 的。
- `reflect.TypeFor[T]()` 取得型別；struct 型別的 `Fields()`（Go 1.26）走訪每個欄位的 `StructField`。
- `f.Tag.Get(key)` 取出某把鑰匙的值；`f.Tag.Lookup(key)` 多回傳一個 `bool`，能分辨「空值」和「沒寫」。
- `reflect.Value` 的 `Fields()` 同時交出欄位資訊和值；搭配 `IsZero()` 就能寫出通用的必填檢查。
