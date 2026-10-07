# 反射 `reflect`

## 本集目標

認識 `reflect` 套件的 `TypeOf`、`ValueOf` 和 `Kind`，能在執行期間查出一個值的型別與內容，並知道為什麼平常應該少用它。

## 正文

### 執行期間才知道型別

第 4 章的 `any` 可以裝任何值，再用型別斷言或 type switch 找出它是什麼。但 type switch 只能比對**寫程式時就想得到**的型別。如果要寫一個「任何 struct 都能處理」的函式，例如把任意 struct 轉成 JSON 的 `json.Marshal`，事先根本不知道會收到什麼型別。

這時就要用**反射**（reflection）：程式在執行期間，查看一個值的型別和內容。Go 的反射功能在 `reflect` 套件裡。

### `TypeOf` 與 `Kind`

`reflect.TypeOf(x)` 回傳 `x` 的型別資訊（`reflect.Type`）；它的 `Kind()` 方法回傳這個型別屬於哪一「大類」：

```go
package main

import (
	"fmt"
	"reflect"
)

type Celsius float64

type Point struct {
	X, Y int
}

func main() {
	values := []any{42, "hi", Celsius(36.5), Point{1, 2}, []string{"a"}, &Point{}}
	for _, x := range values {
		t := reflect.TypeOf(x)
		fmt.Println("型別:", t, "種類:", t.Kind())
	}
}
```

執行結果：

```text
型別: int 種類: int
型別: string 種類: string
型別: main.Celsius 種類: float64
型別: main.Point 種類: struct
型別: []string 種類: slice
型別: *main.Point 種類: ptr
```

**型別**（Type）和**種類**（Kind）不一樣：

- 型別是精確的名字。`Celsius` 是我們自訂的型別（第 3 章），所以型別是 `main.Celsius`。
- 種類是底層的分類，數量固定：`int`、`float64`、`string`、`struct`、`slice`、`ptr`（指標）、`map` 等等。`Celsius` 的底層是 `float64`，所以種類就是 `float64`。

寫反射程式時，通常是看 `Kind` 決定要怎麼處理：不管你自訂了多少種 struct，它們的種類都是 `struct`。

### `ValueOf`：拿到值本身

`reflect.ValueOf(x)` 回傳一個 `reflect.Value`，可以用它讀出裡面的內容。讀之前要先看 `Kind`，再呼叫對應的方法：

```go
package main

import (
	"fmt"
	"reflect"
)

func show(x any) {
	v := reflect.ValueOf(x)
	switch v.Kind() {
	case reflect.Int:
		fmt.Println("整數，加 1 是", v.Int()+1)
	case reflect.String:
		fmt.Println("字串，長度", v.Len())
	case reflect.Slice:
		fmt.Println("切片，有", v.Len(), "個元素，第一個是", v.Index(0))
	default:
		fmt.Println("不處理", v.Kind())
	}
}

func main() {
	show(41)
	show("hello")
	show([]float64{1.5, 2.5})
	show(true)
}
```

執行結果：

```text
整數，加 1 是 42
字串，長度 5
切片，有 2 個元素，第一個是 1.5
不處理 bool
```

- `reflect.Int`、`reflect.String` 這些是 `reflect` 套件定義的常數，代表各種 `Kind`。
- `v.Int()` 回傳 `int64`；`v.Len()` 適用於字串、切片、map 等；`v.Index(i)` 取出切片的第 `i` 個元素（也是一個 `reflect.Value`）。

要注意：這些方法只能用在對的種類上。對字串呼叫 `v.Int()`，編譯器不會擋，執行時才 panic。

### 為什麼要少用

反射看起來很萬能，但有幾個實實在在的缺點：

- **編譯器幫不了你**。型別錯誤要等到執行時才會 panic，原本 Go 在編譯時就能抓到的錯誤，全部延後到執行時。
- **比較慢**。每一步都要在執行期間查型別資訊，比直接操作慢很多。
- **難讀**。上面幾行反射，換成一般程式碼可能只是 `x + 1`。

所以優先順序是：

1. 型別寫程式時就確定 → 直接用具體型別。
2. 只是幾種可能的型別 → 用 type switch（第 4 章）。
3. 同一套邏輯要適用很多型別 → 用介面（第 4 章）或泛型（第 6 章）。
4. 真的要處理「事先完全不知道長相」的資料，例如寫序列化套件 → 才用反射。

你平常用的 `fmt.Println`、`encoding/json` 內部就大量使用反射，這正是它最適合的地方：由少數套件作者寫一次，其他人只管呼叫。

## 重點整理

- 反射讓程式在執行期間查看值的型別與內容，功能在 `reflect` 套件。
- `reflect.TypeOf(x)` 取得型別，`Kind()` 取得底層種類；自訂型別的型別名稱和種類可能不同。
- `reflect.ValueOf(x)` 取得值，先看 `Kind()`，再用 `Int()`、`Len()`、`Index()` 等對應的方法讀取，用錯種類會 panic。
- 反射失去編譯期檢查、比較慢也難讀；能用具體型別、type switch、介面或泛型解決時就不要用反射。
