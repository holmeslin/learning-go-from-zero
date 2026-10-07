# `gofmt` 與 `go vet`

## 本集目標

用 `gofmt` 自動整理程式碼的排版，用 `go vet` 抓出能編譯、但很可能寫錯的地方。

## 正文

### 排版這件事交給工具

假設你在匆忙之中寫出這樣的 `main.go`，縮排有的用空白、有的少，`:=` 兩邊也沒有空格：

```text
package main

import "fmt"

func main() {
    age := 18
  name:="小明"
    fmt.Printf("%s 今年 %s 歲\n", name, age)
}
```

Go 照樣能編譯，但很難讀。我們不用手動修，交給 `gofmt`：

```bash
gofmt -l .
```

`-l` 會列出「排版不符合標準」的檔案：

```text
main.go
```

想先看看它會怎麼改，用 `-d` 顯示差異：

```bash
gofmt -d main.go
```

```text
diff main.go.orig main.go
--- main.go.orig
+++ main.go
@@ -3,7 +3,7 @@
 import "fmt"
 
 func main() {
-    age := 18
-  name:="小明"
-    fmt.Printf("%s 今年 %s 歲\n", name, age)
+	age := 18
+	name := "小明"
+	fmt.Printf("%s 今年 %s 歲\n", name, age)
 }
```

`-` 開頭是原本的樣子，`+` 開頭是改過的樣子。確定沒問題，用 `-w` 直接寫回檔案：

```bash
gofmt -w main.go
```

也可以用 `go fmt ./...` 一次整理整個模組。大部分編輯器都能設定「存檔時自動 `gofmt`」，強烈建議打開。

Go 只有**一種**標準排版，沒有選項可以調整。好處是全世界的 Go 程式碼看起來都一樣，大家不必再為「要不要換行」「用 Tab 還是空白」爭論。第 1 章提過 `if` 的條件不用加小括號，也是 `gofmt` 的規定。

### `go vet`：抓可疑的寫法

排版整理好了，但這個程式其實有錯。執行看看：

```bash
go run .
```

```text
小明 今年 %!s(int=18) 歲
```

`age` 是整數，卻用了字串的格式動詞 `%s`，印出一團奇怪的東西。這種錯誤編譯器不會擋，因為語法完全正確。這時就輪到 `go vet`：

```bash
go vet
```

```text
main.go:8:24: fmt.Printf format %s has arg age of wrong type int
```

`go vet` 指出第 8 行（`8:24` 的 24 是在那一行裡的位置）有問題：`Printf` 的 `%s` 搭配了 `int` 型別的 `age`。把 `%s 歲` 改成 `%d 歲`，再跑一次 `go vet` 就沒有任何輸出了；沒有輸出代表沒發現問題。

`go vet` 會檢查很多種常見錯誤，例如格式動詞和參數對不上、永遠不會成立的比較、寫錯的 struct tag 等等。它不是萬能的，但抓到的幾乎都是真的問題。

### 養成習慣

寫完程式、交出去之前，先跑這兩個：

```bash
gofmt -l .
go vet ./...
```

兩個都沒有輸出，再繼續。下一集開始寫測試，`go test` 其實也會順便執行一部分 `go vet` 的檢查。

## 重點整理

- `gofmt -l` 列出排版不標準的檔案，`-d` 顯示差異，`-w` 直接改寫；`go fmt ./...` 整理整個模組。
- Go 只有一種標準排版，交給工具處理，不要手動排。
- `go vet` 找出能編譯但很可能寫錯的地方，例如 `Printf` 格式動詞和參數型別不符。
- `go vet` 沒有輸出代表沒發現問題。
