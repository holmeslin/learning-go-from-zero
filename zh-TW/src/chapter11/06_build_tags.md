# build tags

## 本集目標

學會用檔案開頭的 `//go:build` 和 `_linux.go` 這類檔名，決定某個檔案要不要參與編譯，並用 `go build -tags` 切換。

## 正文

### 同一份程式，編出不同版本

有時候同一個程式要編出好幾種版本：免費版和專業版功能不同、Windows 和 Linux 要呼叫不同的系統功能、測試用的版本要多印一些除錯訊息。

我們可以把「會不同的部分」放在不同檔案，再告訴 Go：**這次編譯要用哪些檔案**。用來挑選檔案的條件，就叫 **build tags**（建置標籤），也常翻成「建置條件」。

### `//go:build`：檔案的入場條件

在 `.go` 檔的**最上面**寫一行 `//go:build 條件`，這個檔案只有在條件成立時才會被編譯。以下是一個有三個檔案的專案：

`main.go`：

```go,ignore
package main

import "fmt"

func main() {
	fmt.Println("版本:", edition)
	fmt.Println("最多可以建立", maxProjects, "個專案")
}
```

`free.go`：

```go,ignore
//go:build !pro

package main

const edition = "免費版"

const maxProjects = 3
```

`pro.go`：

```go,ignore
//go:build pro

package main

const edition = "專業版"

const maxProjects = 100
```

- `//go:build pro`：有 `pro` 這個標籤時才編譯這個檔案。
- `//go:build !pro`：`!` 是「不是」，也就是沒有 `pro` 標籤時才編譯。
- `//go:build` 必須寫在 `package` 那一行之前，慣例是後面空一行再寫 `package`。忘了空行也沒關係，`gofmt` 會自動幫你補上。

兩個檔案剛好互斥，任何時候都只有一個會被編譯，所以 `edition` 不會重複定義。

### 用 `-tags` 切換

平常執行，沒有任何自訂標籤：

```bash
go run .
```

執行結果：

```text
版本: 免費版
最多可以建立 3 個專案
```

加上 `-tags pro`，換成 `pro.go` 參與編譯：

```bash
go run -tags pro .
```

執行結果：

```text
版本: 專業版
最多可以建立 100 個專案
```

`go build`、`go test`、`go vet` 也都接受 `-tags`，用法一樣。多個標籤用逗號分隔，例如 `-tags pro,debug`。

### 條件可以組合

條件裡可以用 `&&`（而且）、`||`（或者）、`!`（不是）和小括號，跟第 1 章的邏輯運算子一樣：

```go,ignore
//go:build linux && amd64

//go:build darwin || linux

//go:build !windows && (debug || dev)
```

除了自己取名的標籤，Go 也內建了一些標籤，不用寫 `-tags` 就會自動成立：

- 作業系統：`linux`、`darwin`（macOS）、`windows` 等。
- CPU 架構：`amd64`、`arm64` 等。
- Go 版本：例如 `go1.26` 表示「Go 1.26 或更新的版本」。

### 用檔名表示平台

針對作業系統和 CPU 的情況太常見了，所以 Go 還有一個更省事的規則：檔名結尾是 `_作業系統.go` 或 `_CPU架構.go` 的檔案，會自動加上對應的條件，不用寫 `//go:build`。

```text
myapp/
├── main.go
├── platform_darwin.go
├── platform_linux.go
└── platform_windows.go
```

三個檔案各自定義一個同名的 `platformName` 函式，回傳 `"macOS"`、`"Linux"`、`"Windows"`。在 macOS 上編譯時，只有 `platform_darwin.go` 會被選中，在 Linux 上則只會選 `platform_linux.go`。

用環境變數 `GOOS` 可以指定「要編給哪個作業系統」，在 Mac 上也能編出 Linux 的執行檔：

```bash
GOOS=linux go build -o app-linux .
```

這叫做**交叉編譯**，Go 的交叉編譯非常方便，下一集講 cgo 時會再提到它。如果編譯的目標平台沒有對應的檔案，例如上面的專案用 `GOOS=freebsd` 編譯，`platformName` 就找不到定義：

編譯錯誤：

```text
undefined: platformName
```

另外，同一個資料夾裡寫著 `//go:build ignore` 的檔案永遠不會被一般的編譯選中，常拿來放輔助用的小程式，下一集就會看到。

舊的程式碼裡，你可能還會看到 `// +build pro` 這種舊寫法，意思一樣；現在一律用 `//go:build`。

### 不要用得太多

build tags 讓同一份程式碼有很多種組合，每多一個標籤，要測試的版本就多一倍。能用一般的 `if` 或設定值解決的事，就不要用 build tags；把它留給「真的不能編在一起」的情況，例如不同作業系統的系統呼叫。

## 重點整理

- `.go` 檔最上面的 `//go:build 條件` 決定這個檔案是否參與編譯，寫在 `package` 之前。
- 自訂標籤用 `go build -tags 名稱`（`go run`、`go test`、`go vet` 也一樣）啟用；條件可用 `&&`、`||`、`!` 組合。
- 作業系統、CPU 架構和 Go 版本是內建標籤；`_linux.go`、`_windows.go` 這類檔名會自動套用對應條件。
- 用 `GOOS` 指定目標作業系統可以交叉編譯；build tags 會增加要測試的組合，能不用就不用。
