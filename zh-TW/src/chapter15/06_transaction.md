# 交易

## 本集目標

用 `BeginTx`、`Commit`、`Rollback` 把好幾個 SQL 綁成「全部成功或全部不算」的一組，並學會 `defer tx.Rollback()` 的慣例。

## 正文

### 轉帳只做一半會怎樣

小明轉 300 元給小美，要做兩件事：小明的餘額減 300、小美的餘額加 300。如果第一步做完、第二步之前程式當掉，300 元就憑空消失了。

**交易**（transaction）把多個 SQL 綁在一起：

- **Commit**（提交）：全部做完，一起生效。
- **Rollback**（回滾）：中途有問題，全部取消，資料回到交易開始前的樣子。

不會出現「只做一半」的狀態。

### 基本寫法

```go
package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	_ "modernc.org/sqlite"
)

var ErrNotEnough = errors.New("餘額不足")

func transfer(ctx context.Context, db *sql.DB, from, to string, amount int) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	res, err := tx.Exec("UPDATE accounts SET balance = balance - ? WHERE name = ? AND balance >= ?",
		amount, from, amount)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return ErrNotEnough
	}

	if _, err := tx.Exec("UPDATE accounts SET balance = balance + ? WHERE name = ?", amount, to); err != nil {
		return err
	}
	return tx.Commit()
}

func printBalances(db *sql.DB) {
	rows, err := db.Query("SELECT name, balance FROM accounts ORDER BY name")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var name string
		var balance int
		if err := rows.Scan(&name, &balance); err != nil {
			fmt.Println(err)
			return
		}
		fmt.Printf("  %s：%d\n", name, balance)
	}
	if err := rows.Err(); err != nil {
		fmt.Println(err)
	}
}

func main() {
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1)

	db.Exec("CREATE TABLE accounts (name TEXT PRIMARY KEY, balance INTEGER)")
	db.Exec("INSERT INTO accounts VALUES (?, ?), (?, ?)", "小明", 500, "小美", 100)

	ctx := context.Background()
	fmt.Println("轉 300：", transfer(ctx, db, "小明", "小美", 300))
	printBalances(db)
	fmt.Println("再轉 300：", transfer(ctx, db, "小明", "小美", 300))
	printBalances(db)
}
```

執行結果：

```text
轉 300： <nil>
  小明：200
  小美：400
再轉 300： 餘額不足
  小明：200
  小美：400
```

一步一步看 `transfer`：

- `db.BeginTx(ctx, nil)` 開始一個交易，回傳 `*sql.Tx`。第一個參數是第 10 章的 context，第二個是交易選項，用預設值就傳 `nil`。（也有不帶 context 的 `db.Begin()`。）
- 交易裡的每個 SQL 都要用 **`tx`** 的方法：`tx.Exec`、`tx.QueryRow`、`tx.Query`。用 `db.Exec` 的話，那段 SQL 會跑到交易外面，不受 Commit／Rollback 控制。在我們只有一條連線的設定下更糟：那條連線正被交易佔著，`db.Exec` 會一直等下去。
- 扣款的 `WHERE ... AND balance >= ?` 讓餘額不夠時一列都不會改到，所以用 `RowsAffected` 是否為 0 判斷餘額不足。
- 全部成功才 `return tx.Commit()`。

第二次轉帳在第一步就發現餘額不足，直接 `return ErrNotEnough`，`defer` 的 `tx.Rollback()` 取消交易，餘額都沒變。

### `defer tx.Rollback()` 為什麼安全

你可能會擔心：成功的時候已經 `Commit` 了，`defer` 還是會再呼叫 `Rollback`，不會把剛提交的資料取消嗎？

不會。交易一旦 `Commit` 或 `Rollback` 過就結束了，之後再呼叫只會回傳 `sql.ErrTxDone`，不做任何事：

```go
package main

import (
	"database/sql"
	"errors"
	"fmt"

	_ "modernc.org/sqlite"
)

func main() {
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1)

	db.Exec("CREATE TABLE notes (body TEXT)")

	tx, err := db.Begin()
	if err != nil {
		fmt.Println(err)
		return
	}
	tx.Exec("INSERT INTO notes VALUES (?)", "第一則")
	fmt.Println("Commit：", tx.Commit())

	err = tx.Rollback()
	fmt.Println("Rollback：", err, errors.Is(err, sql.ErrTxDone))

	var count int
	db.QueryRow("SELECT COUNT(*) FROM notes").Scan(&count)
	fmt.Println("筆數：", count)
}
```

執行結果：

```text
Commit： <nil>
Rollback： sql: transaction has already been committed or rolled back true
筆數： 1
```

所以慣例是：`BeginTx` 成功後**立刻** `defer tx.Rollback()`。之後不管從哪個 `return` 離開、甚至發生 panic，只要還沒 `Commit`，交易都會被取消；有 `Commit` 的話，這個 `Rollback` 就什麼都不做。這和 `defer rows.Close()` 是同一種思路：先把收尾安排好，再專心寫正事。

## 重點整理

- 交易把多個 SQL 綁在一起：`Commit` 一起生效，`Rollback` 一起取消，不會只做一半。
- `db.BeginTx(ctx, nil)` 開始交易；交易裡的 SQL 都要用 `tx.Exec`、`tx.QueryRow`、`tx.Query`，不要用 `db`。
- 開始交易後立刻 `defer tx.Rollback()`，全部成功時最後 `return tx.Commit()`。
- `Commit` 之後再 `Rollback` 只會回傳 `sql.ErrTxDone`，不會影響已提交的資料。
