# `Exec`

## 本集目標

用 `db.Exec` 執行建立資料表、新增、修改、刪除這類「不需要拿回資料」的 SQL，並用 `?` 佔位符安全地放入參數。

## 正文

### 建立資料表、新增資料

`db.Exec` 用來執行**不回傳資料列**的 SQL：

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

	_, err = db.Exec(`CREATE TABLE books (
		id    INTEGER PRIMARY KEY,
		title TEXT NOT NULL,
		price INTEGER NOT NULL
	)`)
	if err != nil {
		fmt.Println(err)
		return
	}

	res, err := db.Exec("INSERT INTO books (title, price) VALUES (?, ?)", "Go 入門", 450)
	if err != nil {
		fmt.Println(err)
		return
	}
	id, _ := res.LastInsertId()
	fmt.Println("新書編號：", id)

	res, _ = db.Exec("INSERT INTO books (title, price) VALUES (?, ?)", "SQL 速查", 300)
	id, _ = res.LastInsertId()
	fmt.Println("新書編號：", id)
}
```

執行結果：

```text
新書編號： 1
新書編號： 2
```

兩段 SQL 的意思：

- `CREATE TABLE books (...)`：建立一張叫 `books` 的資料表，有三欄。`INTEGER` 是整數、`TEXT` 是文字；`NOT NULL` 表示這欄一定要有值；`id INTEGER PRIMARY KEY` 是每一列的編號，沒指定時 SQLite 會自動從 1 開始往上編。SQL 很長時用 raw string（反引號）就能換行。
- `INSERT INTO books (title, price) VALUES (?, ?)`：新增一列，`title` 和 `price` 的值先用 `?` 佔位，真正的值接在 SQL 後面當參數傳入，依序對應每個 `?`。

`db.Exec` 回傳一個 `sql.Result` 和一個 `error`。`res.LastInsertId()` 告訴我們剛剛新增那一列拿到的編號。（為了讓範例短一點，第二次 `Exec` 省略了錯誤檢查，實際程式不要這樣做。）

### 修改與刪除：`RowsAffected`

`UPDATE` 修改資料、`DELETE` 刪除資料，`WHERE` 指定要動哪些列。`res.RowsAffected()` 告訴我們實際影響了幾列：

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

	db.Exec("CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT, price INTEGER)")
	db.Exec("INSERT INTO books (title, price) VALUES (?, ?), (?, ?), (?, ?)",
		"Go 入門", 450, "SQL 速查", 300, "演算法", 520)

	res, err := db.Exec("UPDATE books SET price = price - ? WHERE price > ?", 50, 400)
	if err != nil {
		fmt.Println(err)
		return
	}
	n, _ := res.RowsAffected()
	fmt.Println("打折的書：", n, "本")

	res, _ = db.Exec("DELETE FROM books WHERE title = ?", "不存在的書")
	n, _ = res.RowsAffected()
	fmt.Println("刪除：", n, "本")
}
```

執行結果：

```text
打折的書： 2 本
刪除： 0 本
```

`UPDATE ... SET price = price - ? WHERE price > ?` 的意思是「把價格大於 400 的書都減 50 元」，有兩本符合。刪除一本不存在的書不算錯誤，只是影響 0 列；想知道「到底有沒有刪到」，就要看 `RowsAffected`。

### 一律用 `?`，不要自己拼字串

你可能會想：何必用 `?`，直接用 `+` 或 `fmt.Sprintf` 把值拼進 SQL 不就好了？

```go,ignore
// 危險！不要這樣寫
query := "DELETE FROM books WHERE title = '" + title + "'"
```

如果 `title` 是使用者輸入的 `x' OR '1'='1`，拼出來的 SQL 會變成：

```sql
DELETE FROM books WHERE title = 'x' OR '1'='1'
```

`'1'='1'` 永遠成立，整張表都被刪光了。這種「輸入的資料被當成 SQL 指令執行」的攻擊叫 **SQL injection**（SQL 注入），是最常見的資安漏洞之一。

用 `?` 時，SQL 指令和資料是**分開**送給資料庫的，資料再怎麼寫都只會被當成一段文字：

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

	db.Exec("CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT)")
	db.Exec("INSERT INTO books (title) VALUES (?), (?)", "Go 入門", "SQL 速查")

	title := "x' OR '1'='1"
	res, _ := db.Exec("DELETE FROM books WHERE title = ?", title)
	n, _ := res.RowsAffected()
	fmt.Println("刪除：", n, "本")
}
```

執行結果：

```text
刪除： 0 本
```

資料庫在找書名**剛好等於** `x' OR '1'='1` 的書，當然找不到。記住：**值一律用 `?` 傳**，SQL 字串裡只放固定的指令。

## 重點整理

- `db.Exec` 執行不回傳資料列的 SQL（`CREATE TABLE`、`INSERT`、`UPDATE`、`DELETE`），回傳 `sql.Result` 與 `error`。
- `res.LastInsertId()` 取得新增那一列的編號，`res.RowsAffected()` 取得影響的列數。
- SQL 裡用 `?` 佔位，值依序接在後面當參數。
- 不要用字串拼接把值放進 SQL，否則會有 SQL injection 的風險。
