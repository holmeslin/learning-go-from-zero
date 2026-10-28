# cgo 簡介

## 本集目標

知道 cgo 是什麼、它帶來哪些代價，以及環境變數 `CGO_ENABLED` 對編譯和交叉編譯的影響。這一集只求看懂，不需要自己寫 cgo。

## 正文

### 在 Go 裡呼叫 C

世界上有大量用 C 語言寫成的函式庫：影像處理、加密、資料庫引擎、作業系統提供的功能。重新用 Go 寫一遍要花很多工夫，有時候直接呼叫現成的 C 程式碼比較實際。

**cgo** 就是讓 Go 程式呼叫 C 程式碼的機制。它長這樣：

```go,ignore
package main

/*
static int add(int a, int b) {
	return a + b;
}
*/
import "C"

import "fmt"

func main() {
	sum := C.add(1, 2)
	fmt.Println("C 算出來的結果:", int(sum))
}
```

- `import "C"` 不是真的有一個叫 `C` 的套件，而是告訴 Go：「這個檔案要用 cgo」。
- 緊貼在 `import "C"` 正上方的註解（中間不能有空行）是 C 程式碼，叫做 preamble。這裡定義了一個 C 函式 `add`。
- 在 Go 裡用 `C.add` 呼叫它。C 的 `int` 和 Go 的 `int` 不是同一個型別，回傳值要用 `int(sum)` 轉換。

在裝有 C 編譯器的電腦上，`go run .` 會印出「C 算出來的結果: 3」。

### cgo 的代價

能呼叫 C 聽起來很棒，但 Go 社群有句話：「cgo 不是 Go」。用了它，很多 Go 原本的好處就打了折扣：

- **需要 C 編譯器**。光有 Go 不夠，每台要編譯的電腦都得裝 gcc 或 clang，編譯也明顯變慢。
- **交叉編譯變困難**。上一集提到，純 Go 的程式可以設定 `GOOS` 選作業系統；目標 CPU 架構不同時，也要設定 `GOARCH`。用了 cgo，還得準備目標平台的 C 編譯器和 C 函式庫。
- **呼叫有額外成本**。每次從 Go 呼叫 C 都要切換執行環境，比呼叫一般 Go 函式慢得多，不適合在迴圈裡大量呼叫小函式。
- **失去記憶體安全**。C 配置的記憶體不歸 Go 的垃圾回收管，要自己釋放；C 程式碼寫錯，整個程式會直接當掉，不會有 panic 可以 `recover`。Go 的指標要傳給 C 時也有嚴格的規則。
- **工具支援有限**。不能靠 `go vet`、`-race` 完整檢查任意 C 程式碼，C 端仍需要自己的檢查工具。但也不是完全無法分析 C：在適當的平台與設定下，可以取得 C 的呼叫堆疊等資訊，例如 `runtime.SetCgoTraceback` 提供的支援。

所以一般的原則是：**能用純 Go 的套件，就不要用 cgo**。第 15 章會用到的 SQLite driver `modernc.org/sqlite`，就是特地挑選的純 Go 版本，不需要 cgo。

### `CGO_ENABLED`

要不要啟用 cgo，由環境變數 `CGO_ENABLED` 決定：`1` 是啟用，`0` 是停用。用 `go env` 可以查看目前的設定：

```bash
go env CGO_ENABLED
```

以下是在一台裝了 C 編譯器的 Mac 上查看的結果。

執行結果：

```text
1
```

它的預設值是這樣決定的：

- 一般在本機編譯，而且找得到 C 編譯器時，預設是 `1`。
- **交叉編譯**（`GOOS` 或 `GOARCH` 和本機不同）時，預設是 `0`。
- 找不到 C 編譯器時，預設也是 `0`。

可以直接驗證交叉編譯時的預設值：

```bash
GOOS=linux go env CGO_ENABLED
```

在同一台 Mac 上查看。

執行結果：

```text
0
```

### `CGO_ENABLED=0` 會怎樣

cgo 被停用時，所有 `import "C"` 的檔案都會被排除，就像上一集的 build tags 一樣。上面那個例子用 `CGO_ENABLED=0 go build .` 編譯，整個套件就沒有檔案可編了。

編譯錯誤：

```text
package myapp: build constraints exclude all Go files in ...
```

標準函式庫裡少數套件，例如處理網路的 `net` 和查詢使用者的 `os/user`，在某些系統上會用 cgo 呼叫系統的 C 函式庫，但它們也都準備了純 Go 的版本。`CGO_ENABLED=0` 時就自動改用純 Go 版本，程式照樣能編譯。

很多人部署程式時會特地寫：

```bash
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app .
```

這裡指定編給 Linux／amd64；如果目標是 arm64，就要改成 `GOARCH=arm64`。只設 `GOOS` 不會自動適用所有 CPU 架構。停用 cgo 後，執行檔不依賴 cgo 使用的系統 C 函式庫，部署通常比較方便，但仍需要相容的 CPU 架構、作業系統版本，以及程式用到的外部資料（例如憑證、設定檔）。不能保證任意 Linux 機器或極簡容器都能直接執行。

## 重點整理

- cgo 讓 Go 透過 `import "C"` 和它正上方的 C 程式碼註解呼叫 C 函式。
- cgo 需要 C 編譯器、讓交叉編譯變困難、呼叫有額外成本；C 部分不受 Go 的記憶體安全保護，工具支援也有限，但不是完全無法分析。能用純 Go 就不要用 cgo。
- `CGO_ENABLED` 控制是否啟用 cgo：本機編譯且有 C 編譯器時預設 `1`，交叉編譯或找不到 C 編譯器時預設 `0`。
- `CGO_ENABLED=0` 會排除 `import "C"` 的檔案；`net`、`os/user` 等標準套件會改用純 Go 版本。部署仍要選對 `GOOS`、`GOARCH`，並滿足目標環境的相容條件與外部資料需求。
