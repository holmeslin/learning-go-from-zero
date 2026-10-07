# `internal` 目錄

## 本集目標

用名叫 `internal` 的資料夾，讓套件只給模組裡特定範圍的程式碼使用。

## 正文

### 大寫還不夠

第 3 集學到，大寫開頭的名稱可以被其他套件使用。但有時候會遇到這種情況：`order` 套件需要一個計算稅金的輔助套件 `price`，`price` 裡的函式必須大寫，`order` 才能用；可是大寫之後，**所有**套件都能用它了，包括別人的模組。

我們只想讓 `order` 用，不想讓全世界都依賴它。這時就把它放進 `internal` 資料夾。

### 規則

路徑中有一段叫 `internal` 的套件，只能被「`internal` 的上一層資料夾」以及它底下的程式碼引入。

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

`price` 的路徑是 `shop/order/internal/price`，`internal` 的上一層是 `order`。所以只有 `order` 資料夾以及它底下的套件能引入 `price`；`report` 和根目錄的 `main.go` 都不行。

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

很多專案會直接在模組最上層放一個 `internal` 資料夾，例如 `shop/internal/price`。`internal` 的上一層就是整個模組，所以模組裡的任何套件都能用，但**其他模組**一律不能用。這是「只給自己專案用」最常見的寫法。

## 重點整理

- 路徑中有 `internal` 的套件，只能被 `internal` 上一層資料夾及其底下的程式碼引入。
- 違反規則時，編譯會出現 `use of internal package ... not allowed`。
- 放在模組最上層的 `internal`，代表「整個模組都能用，其他模組不能用」。
- `go build ./...` 會編譯目前資料夾和底下所有的套件。
