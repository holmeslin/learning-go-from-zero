# 從零開始學 Go — 全書目錄規劃（已定案）

Go 1.27 · 繁中 · 完全零基礎 · 一集一個小概念 · 只用標準庫（第 15 章例外：modernc.org/sqlite）

# 第一部

## 第 1 章 基礎
01 安裝 Go · 02 第一個程式（`go mod init` 固定句型、`package main`、`func main`、`go run`）· 03 變數與輸出（`:=`、`fmt.Println`）· 04 註解 · 05 算術運算子 · 06 運算子優先順序 · 07 比較運算子 · 08 `if` · 09 作用域 · 10 `else` · 11 `else if` · 12 邏輯運算子 · 13 重新賦值與 `var` · 14 複合賦值與 `++` `--` · 15 讀取輸入（`bufio.Scanner` 固定句型）· 16 `strconv.Atoi` 與 `err` 固定句型 · 17 綜合練習 · 18 `for` 無限迴圈 + `break` · 19 `for` 條件迴圈（Go 的 while）· 20 三段式 `for` · 21 `for range` 整數 · 22 巢狀迴圈 · 23 `continue` · 24 型別（基礎）· 25 型別（數字詳解）· 26 零值 · 27 型別轉換 · 28 `byte` 與 `rune` · 29 跳脫字元與 raw string · 30 `switch`

## 第 2 章 函式、陣列、切片與 map
01 `const` · 02 `iota` · 03 底線 `_` · 04 多重賦值與交換 · 05 `fmt.Printf` 格式動詞（`%v` `%d` `%s` `%T`）· 06 簡單函式 · 07 函式參數 · 08 函式回傳值 · 09 多個回傳值 · 10 具名回傳值 · 11 early `return` · 12 遞迴 · 13 陣列基礎 · 14 `for range` 走訪陣列 · 15 切片 · 16 `append`、`len`、`cap` · 17 切片運算式 `s[a:b]` · 18 切片共用底層陣列 · 19 `copy` · 20 切片作為參數 · 21 `make` · 22 字串與 UTF-8 · 23 `for range` 走訪字串 · 24 `strings` 套件常用函式 · 25 map 基礎 · 26 comma-ok · 27 `if` / `switch` 的初始化敘述 · 28 `delete` 與走訪 map（順序隨機）· 29 內建 `min` `max` `clear`

## 第 3 章 結構、指標與方法
01 `struct` · 02 struct literal 與零值 · 03 匿名 struct · 04 指標 `&` `*` · 05 指向 struct 的指標 · 06 `new` 與 `new(expr)` · 07 `nil` · 08 自訂型別 `type X int` · 09 方法 · 10 值接收者 vs 指標接收者 · 11 struct 比較 · 12 嵌入（embedding）· 13 欄位提升與方法提升 · 14 巢狀欄位的 struct literal（Go 1.27）· 15 讓零值有用

## 第 4 章 介面
01 `interface` · 02 隱式實作 · 03 方法集合：指標接收者與介面 · 04 介面值 · 05 `any` · 06 型別斷言 · 07 type switch · 08 `fmt.Stringer` · 09 介面嵌入 · 10 小介面設計 · 11 nil 介面陷阱

## 第 5 章 錯誤處理與 `defer`
01 `error` 是介面 · 02 `errors.New` · 03 `if err != nil` 慣例 · 04 `fmt.Errorf` 與 `%w` · 05 哨兵錯誤 · 06 `errors.Is` · 07 自訂錯誤型別 · 08 `errors.As` 與 `errors.AsType` · 09 `errors.Join` · 10 `defer` · 11 `defer` 的執行順序與參數求值 · 12 `panic` · 13 `recover`

## 第 6 章 函式值、閉包與泛型
01 函式是值 · 02 匿名函式 · 03 閉包 · 04 迴圈變數與閉包（Go 1.22 起每次迭代一份）· 05 可變參數 `...` · 06 函式當參數 · 07 `slices.SortFunc` 與 `cmp.Compare` · 08 泛型函式 · 09 型別約束 · 10 `comparable` 與 `cmp.Ordered` · 11 `~` 底層型別 · 12 泛型型別 · 13 泛型方法（Go 1.27）· 14 型別推論（含 Go 1.27 函式型別推論擴充） · 15 `slices` 與 `maps` 套件

## 第 7 章 迭代器
01 range over func · 02 `iter.Seq` · 03 `iter.Seq2` · 04 提早結束（`yield` 回傳 `false`）· 05 `slices.All` `slices.Values` `maps.Keys` · 06 `slices.Collect` `slices.Sorted` · 07 自己寫迭代器 · 08 `iter.Pull`

## 第 8 章 套件、模組與測試
01 `go mod init` 與 `go.mod` · 02 套件與目錄 · 03 匯出（大寫開頭）· 04 `import` 與別名 · 05 `internal` 目錄 · 06 `init` 函式 · 07 文件註解與 `go doc` · 08 `gofmt` 與 `go vet` · 09 `go test` · 10 表格驅動測試 · 11 `t.Run` 子測試 · 12 benchmark 與 `b.Loop` · 13 Example 測試 · 14 fuzzing · 15 `go get` 與相依版本 · 16 `go fix`

## 附錄一
a 數字字面值（`1_000`、`0x`、`0b`）· b 短路求值 · c 標籤 `break` / `continue` · d `goto` · e shadowing 陷阱 · f 方法值與方法運算式 · g 無型別常數 · h 陣列是值、切片是 header · i `fallthrough` · j `fmt` 進階格式 · k struct tag 初探

# 第二部

## 第 9 章 並行
01 goroutine · 02 `sync.WaitGroup` 與 `wg.Go` · 03 data race 與 `-race` · 04 `sync.Mutex` · 05 `sync.RWMutex` · 06 `sync/atomic` · 07 `sync.Once` 與 `OnceValue` · 08 channel · 09 buffered channel · 10 `close` 與 `range` channel · 11 `select` · 12 逾時 `time.After` · 13 單向 channel · 14 nil channel · 15 死結 · 16 goroutine 洩漏 · 17 worker pool · 18 pipeline · 19 `testing/synctest`

## 第 10 章 `context`
01 為什麼需要 context · 02 `WithCancel` · 03 `WithTimeout` / `WithDeadline` · 04 `WithValue` · 05 `Cause` · 06 `AfterFunc` · 07 context 傳遞慣例

## 第 11 章 進階語言功能
01 反射 `reflect` · 02 用 `reflect` 讀取 struct tag · 03 型別別名與泛型別名 · 04 自我參照的型別約束（Go 1.26）· 05 `//go:embed` · 06 build tags · 07 `//go:generate` · 08 `unsafe` · 09 cgo 簡介（純敘述，不附可執行範例） · 10 `runtime.AddCleanup` 與 `weak`

## 第 12 章 進階標準庫
01 `io.Reader` / `io.Writer` · 02 `bufio` · 03 `os` 檔案操作 · 04 `os.Root` · 05 `path/filepath` 與 `io/fs` · 06 `strings.Builder` 與 `bytes` · 07 `time` · 08 `encoding/json` · 09 `encoding/json/v2` · 10 `log/slog` · 11 `math/rand/v2` · 12 `uuid`

## 第 13 章 實戰：CLI 工具
01 `os.Args` · 02 `flag` · 03 子命令 · 04 結束碼 · 05 stdin/stdout 管線 · 06 走訪目錄 · 07 `signal.NotifyContext` · 08 完整範例

## 第 14 章 實戰：Web 服務
01 `net/http` 第一個伺服器 · 02 `ServeMux` 路由（方法與萬用字元）· 03 Handler 與 HandlerFunc · 04 JSON API · 05 middleware · 06 HTTP client · 07 逾時設定 · 08 graceful shutdown · 09 `httptest`

## 第 15 章 實戰：`database/sql`
01 `sql.Open` 與 SQLite driver · 02 `Exec` · 03 `QueryRow` · 04 `Query` 與 `Rows` · 05 prepared statement · 06 交易 · 07 `NULL` 處理 · 08 context 與連線池

## 附錄二
a 記憶體模型 · b 逃逸分析 · c GC 概念 · d `pprof` · e 介面 vs 泛型的取捨
