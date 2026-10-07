# `NULL` 處理

## 本集目標

知道資料庫的 `NULL` 是什麼，用 `sql.NullString` 與泛型的 `sql.Null[T]` 讀寫可能是 `NULL` 的欄位。

## 正文

### `NULL`：沒有值

資料庫裡的欄位可以是 **`NULL`**，意思是「沒有值」「不知道」。它和空字串 `""`、數字 `0` 都不一樣：電話欄是 `""` 可能代表「填了空白」，是 `NULL` 則代表「根本沒填」。

建表時沒寫 `NOT NULL` 的欄位就可以是 `NULL`。新增資料時，參數傳 Go 的 `nil` 就會存成 `NULL`。

問題來了：Go 的 `string` 沒辦法表示「沒有值」，它的零值是 `""`。直接把 `NULL` 掃進 `string` 會出錯：

```go
package main

import (
	"database/sql"
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

	db.Exec("CREATE TABLE members (name TEXT NOT NULL, phone TEXT)")
	db.Exec("INSERT INTO members VALUES (?, ?)", "小美", nil)

	var phone string
	err = db.QueryRow("SELECT phone FROM members WHERE name = ?", "小美").Scan(&phone)
	fmt.Println(err)
}
```

執行結果：

```text
sql: Scan error on column index 0, name "phone": converting NULL to string is unsupported
```

### `sql.NullString`

`database/sql` 準備了一組專門裝「可能是 `NULL`」的型別，例如 `sql.NullString`、`sql.NullInt64`、`sql.NullFloat64`、`sql.NullBool`、`sql.NullTime`。以 `sql.NullString` 為例，它是一個 struct：

```go,ignore
type NullString struct {
	String string
	Valid  bool // 不是 NULL 時為 true
}
```

`Valid` 是 `false` 就代表 `NULL`：

```go
package main

import (
	"database/sql"
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

	db.Exec("CREATE TABLE members (name TEXT NOT NULL, phone TEXT)")
	db.Exec("INSERT INTO members VALUES (?, ?), (?, ?), (?, ?)",
		"小明", "0912-345-678", "小美", nil, "阿華", "")

	rows, err := db.Query("SELECT name, phone FROM members")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		var name string
		var phone sql.NullString
		if err := rows.Scan(&name, &phone); err != nil {
			fmt.Println(err)
			return
		}
		if phone.Valid {
			fmt.Printf("%s：%q\n", name, phone.String)
		} else {
			fmt.Printf("%s：沒填\n", name)
		}
	}
	if err := rows.Err(); err != nil {
		fmt.Println(err)
	}
}
```

執行結果：

```text
小明："0912-345-678"
小美：沒填
阿華：""
```

用 `%q` 印出來，可以清楚看到阿華填的是空字串，和小美的 `NULL` 不一樣。

### 泛型版：`sql.Null[T]`

每種型別各一個 `NullXxx` 有點囉嗦。Go 1.22 起有泛型版的 `sql.Null[T]`（第 6 章的泛型型別），欄位固定叫 `V` 和 `Valid`：

```go,ignore
type Null[T any] struct {
	V     T
	Valid bool
}
```

它也能當成參數傳給 `Exec`：`Valid` 為 `false` 時會存成 `NULL`。

```go
package main

import (
	"database/sql"
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

	db.Exec("CREATE TABLE scores (name TEXT NOT NULL, score INTEGER)")

	absent := sql.Null[int64]{}
	present := sql.Null[int64]{V: 0, Valid: true}
	db.Exec("INSERT INTO scores VALUES (?, ?), (?, ?)", "小明", present, "小美", absent)

	for _, name := range []string{"小明", "小美"} {
		var score sql.Null[int64]
		err := db.QueryRow("SELECT score FROM scores WHERE name = ?", name).Scan(&score)
		if err != nil {
			fmt.Println(err)
			return
		}
		fmt.Printf("%s：%+v\n", name, score)
	}

	var count int
	db.QueryRow("SELECT COUNT(*) FROM scores WHERE score IS NULL").Scan(&count)
	fmt.Println("缺考人數：", count)
}
```

執行結果：

```text
小明：{V:0 Valid:true}
小美：{V:0 Valid:false}
缺考人數： 1
```

小明考了 0 分、小美缺考，兩個的 `V` 都是 `0`，靠 `Valid` 才分得出來。另外注意 SQL 裡判斷 `NULL` 要寫 `IS NULL`，不能寫 `= NULL`。

### 能避免就避免

`NULL` 讓每次讀取都多一道檢查。設計資料表時，如果某欄沒有「沒填」這種狀態，就加上 `NOT NULL`，讀的時候直接用 `string`、`int` 就好。只有真的需要分辨「沒有值」的欄位，才用 `sql.Null[T]`。

## 重點整理

- `NULL` 代表「沒有值」，和 `""`、`0` 不同；把 `NULL` 直接 `Scan` 進 `string` 會出錯。
- `sql.NullString` 等型別用 `Valid` 表示是否有值，`Valid` 為 `false` 就是 `NULL`。
- Go 1.22 起的 `sql.Null[T]` 是泛型版，欄位是 `V` 和 `Valid`，可用於 `Scan` 也可當 `Exec` 參數。
- 寫入 `NULL` 可以傳 `nil` 或 `Valid: false` 的值；SQL 裡用 `IS NULL` 判斷。
- 不需要「沒有值」的欄位就加上 `NOT NULL`。
