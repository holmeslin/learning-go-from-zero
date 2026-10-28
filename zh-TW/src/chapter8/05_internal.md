# `internal` 目錄

## 本集目標

用名叫 `internal` 的資料夾，讓套件只給特定匯入路徑範圍的程式碼使用。

## 正文

### 大寫還不夠

第 3 集學到，大寫開頭的名稱可以被其他套件使用。但有時候會遇到這種情況：`order` 套件需要一個計算稅金的輔助套件 `price`，`price` 裡的函式必須大寫，`order` 才能用；可是大寫之後，**所有**套件都能用它了，包括別人的模組。

我們只想讓 `order` 用，不想讓全世界都依賴它。這時就把它放進 `internal` 資料夾。

### 規則

路徑中有一段叫 `internal` 的套件，只能被「`internal` 上一層匯入路徑」所涵蓋的套件引入，也就是該路徑本身與它的子路徑。這個範圍稱為匯入路徑的**子樹**。在一般單模組專案裡，可以先對照資料夾結構來看。

看這個模組 `shop` 的結構：

```text
shop/
├── go.mod
├── main.go
├── order/
│   ├── order.go
│   └── internal/
│       └── price/
│           └── price.go
└── report/
    └── report.go
```

`price` 的路徑是 `shop/order/internal/price`，`internal` 上一層的匯入路徑是 `shop/order`。所以只有路徑是 `shop/order` 或以 `shop/order/` 開頭的套件能引入 `price`；本例的 `report` 和根目錄的 `main.go` 都不行，即使它們在同一個模組裡。

### 實際試試

`order/internal/price/price.go`：

```go,ignore
package price

func WithTax(n int) int {
	return n * 105 / 100
}
```

`order/order.go`：

```go,ignore
package order

import "shop/order/internal/price"

func Total(n int) int {
	return price.WithTax(n)
}
```

`report/report.go`：

```go,ignore
package report

import "shop/order/internal/price"

func Show(n int) int {
	return price.WithTax(n)
}
```

在 `shop` 資料夾執行 `go build ./...`（`./...` 代表「這個資料夾和底下所有的套件」）：

```text
package shop/report
	report/report.go:3:8: use of internal package shop/order/internal/price not allowed
```

`order` 引入 `price` 沒問題，`report` 引入就被擋下來了。`main.go` 想用稅金計算的話，要透過 `order.Total`：

`main.go`：

```go,ignore
package main

import (
	"fmt"

	"shop/order"
)

func main() {
	fmt.Println(order.Total(200))
}
```

把 `report` 資料夾刪掉後執行 `go run .`：

```text
210
```

### 常見的擺法

很多專案會直接在模組最上層放一個 `internal` 資料夾，例如 `shop/internal/price`。在一般單模組專案裡，模組中的套件都在 `shop` 這棵匯入路徑子樹內，所以都能用。這是「只給自己專案用」最常見的寫法。

但限制不是看兩邊是否共用同一個 `go.mod`。例如 `example.com/shop/internal/price` 也能被 `example.com/shop/client` 引入，即使後者是獨立模組；`example.com/other` 則不行。判斷時要看匯入路徑的範圍，不是只看模組邊界。

## 重點整理

- 路徑中有 `internal` 的套件，只能被 `internal` 上一層匯入路徑本身及其子路徑中的套件引入。
- 違反規則時，編譯會出現 `use of internal package ... not allowed`。
- 放在模組最上層的 `internal`，通常讓整個模組都能用；是否允許引入是看匯入路徑，不是是否共用同一個 `go.mod`。
- `go build ./...` 會編譯目前資料夾和底下所有的套件。
