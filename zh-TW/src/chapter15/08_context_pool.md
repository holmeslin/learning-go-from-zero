# context 與連線池

## 本集目標

用 `QueryContext`、`ExecContext` 讓資料庫操作可以被取消或逾時，並認識連線池的四個設定。

## 正文

### 帶 context 的版本

前面用過的方法都有一個帶 context 的版本，名字後面多了 `Context`，第一個參數是 `ctx`：

| 不帶 context | 帶 context |
| --- | --- |
| `db.Exec` | `db.ExecContext` |
| `db.QueryRow` | `db.QueryRowContext` |
| `db.Query` | `db.QueryContext` |
| `db.Prepare` | `db.PrepareContext` |
| `db.Begin` | `db.BeginTx` |
| `db.Ping` | `db.PingContext` |

`tx`、`stmt` 上的方法也一樣。不帶 context 的版本其實就是傳 `context.Background()`，永遠不會被取消。

第 10 章說過：會花時間、可能卡住的操作都應該接受 context。查資料庫正是這種操作，查詢寫得不好、資料量大或資料庫很忙時，可能跑很久。在第 14 章的 Web 服務裡，通常把 `r.Context()` 一路傳下來，使用者關掉網頁時，還在跑的查詢也會跟著停止。

### 逾時與取消

```go
package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	_ "modernc.org/sqlite"
)

const slowQuery = `WITH RECURSIVE n(x) AS (
	SELECT 1 UNION ALL SELECT x + 1 FROM n WHERE x < 1000000000
) SELECT COUNT(*) FROM n`

func main() {
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1)

	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	var count int
	err = db.QueryRowContext(ctx, slowQuery).Scan(&count)
	fmt.Println(err)
	fmt.Println(errors.Is(err, context.DeadlineExceeded))

	ctx2, cancel2 := context.WithCancel(context.Background())
	cancel2()
	_, err = db.ExecContext(ctx2, "CREATE TABLE t (x INTEGER)")
	fmt.Println(err)

	err = db.QueryRowContext(context.Background(), "SELECT 1 + 1").Scan(&count)
	fmt.Println(count, err)
}
```

執行結果：

```text
context deadline exceeded
true
context canceled
2 <nil>
```

- `slowQuery` 是一個故意要數到十億的 SQL，正常會跑很久。這裡看不懂它的寫法沒關係，只要知道它很慢。
- 100 毫秒一到，context 逾時，SQLite 中斷查詢，`Scan` 回傳的錯誤可以用 `errors.Is(err, context.DeadlineExceeded)` 判斷。
- 已經取消的 context 傳進 `ExecContext`，根本不會執行，直接回傳 `context canceled`。
- 被中斷之後，資料庫還是能正常使用。

實務上，**有 context 就用帶 `Context` 的版本**，例如 HTTP handler 裡、或是函式本身就收到 `ctx` 參數時。

### 連線池

第 1 集提過，`*sql.DB` 是一個**連線池**。跟資料庫建立連線很花時間，所以 `database/sql` 會把用完的連線留著，下次直接拿來用；同時有好幾個 goroutine 要查詢時，就開好幾條連線同時處理。

也因為這樣，一個程式通常**只開一個 `*sql.DB`**，在程式啟動時 `sql.Open`，然後傳給所有需要它的地方。`*sql.DB` 可以安全地被很多 goroutine 同時使用，不需要自己加 `Mutex`。不要每次查詢都 `sql.Open` 再 `Close`，那樣就享受不到連線池的好處。

連線池有四個設定：

| 方法 | 意思 | 預設 |
| --- | --- | --- |
| `SetMaxOpenConns(n)` | 最多同時開幾條連線 | 不限制 |
| `SetMaxIdleConns(n)` | 最多留幾條閒置的連線備用 | 2 |
| `SetConnMaxLifetime(d)` | 一條連線最多用多久就換新的 | 不限制 |
| `SetConnMaxIdleTime(d)` | 一條連線閒置多久就關掉 | 不限制 |

下面用一個檔案資料庫，讓 10 個 goroutine 同時查詢，連線池最多開 4 條連線：

```go
package main

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"time"

	_ "modernc.org/sqlite"
)

func main() {
	db, err := sql.Open("sqlite", "pool_demo.db")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer os.Remove("pool_demo.db")
	defer db.Close()

	db.SetMaxOpenConns(4)
	db.SetMaxIdleConns(4)
	db.SetConnMaxLifetime(30 * time.Minute)
	db.SetConnMaxIdleTime(5 * time.Minute)

	ctx := context.Background()
	var total atomic.Int64
	var wg sync.WaitGroup
	for i := range 10 {
		wg.Go(func() {
			var n int64
			err := db.QueryRowContext(ctx, "SELECT ? * ?", i, i).Scan(&n)
			if err != nil {
				fmt.Println(err)
				return
			}
			total.Add(n)
		})
	}
	wg.Wait()

	stats := db.Stats()
	fmt.Println("平方和：", total.Load())
	fmt.Println("連線上限：", stats.MaxOpenConnections)
	fmt.Println("沒超過上限：", stats.OpenConnections <= 4)
}
```

執行結果：

```text
平方和： 285
連線上限： 4
沒超過上限： true
```

`db.Stats()` 回傳連線池的統計資料。實際開了幾條連線要看 goroutine 執行的時機，每次可能不同，但一定不會超過 4 條；超過的請求會排隊等別人歸還連線。（`defer` 照後進先出的順序，先 `db.Close()` 再刪掉檔案。）

### 怎麼設定

- **`SetMaxOpenConns`**：資料庫能承受的連線數有限，用它保護資料庫。用 `:memory:` 時要設成 1（第 1 集的原因）。
- **`SetMaxIdleConns`**：預設只留 2 條。同時查詢的量比較大時，可以調到和 `SetMaxOpenConns` 一樣，避免連線一直被關掉又重開。
- **`SetConnMaxLifetime`、`SetConnMaxIdleTime`**：連線伺服器型資料庫時，網路設備或資料庫可能會默默切斷太久的連線，定期換新可以避開這種問題。注意：`:memory:` 資料庫在連線被關掉時就消失了，所以不要對它設定很短的時間。

具體數字沒有標準答案，要看資料庫和流量，先用預設值，有需要再調。

## 重點整理

- 每個方法都有帶 context 的版本（`ExecContext`、`QueryContext`、`QueryRowContext`、`BeginTx`……），有 context 時就用它們，逾時或取消會中斷查詢。
- 被中斷的錯誤可以用 `errors.Is(err, context.DeadlineExceeded)` 或 `context.Canceled` 判斷。
- `*sql.DB` 是可以給多個 goroutine 共用的連線池；整個程式通常只開一個。
- 用 `SetMaxOpenConns`、`SetMaxIdleConns`、`SetConnMaxLifetime`、`SetConnMaxIdleTime` 調整連線池；`:memory:` 要設 `SetMaxOpenConns(1)`，也不要讓連線過期。
