# prepared statement

## 本集目標

用 `db.Prepare` 先把 SQL 準備好，再帶不同的參數重複執行。

## 正文

### 準備一次，執行很多次

資料庫收到一段 SQL 時，要先**解析**它（看懂語法、決定怎麼查），才能執行。如果同一段 SQL 只是參數不同、要跑很多次，每次都重新解析有點浪費。

**prepared statement**（預備敘述）就是先把 SQL 交給資料庫解析好，得到一個 `*sql.Stmt`，之後只要送參數過去：

```go
package main

import (
	"database/sql"
	"fmt"

	_ "modernc.org/sqlite"
)

type Book struct {
	Title string
	Price int
}

func main() {
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1)

	db.Exec("CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT, price INTEGER)")

	stmt, err := db.Prepare("INSERT INTO books (title, price) VALUES (?, ?)")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer stmt.Close()

	books := []Book{
		{"Go 入門", 450},
		{"SQL 速查", 300},
		{"演算法", 520},
	}
	for _, b := range books {
		res, err := stmt.Exec(b.Title, b.Price)
		if err != nil {
			fmt.Println(err)
			return
		}
		id, _ := res.LastInsertId()
		fmt.Println("新增", id, b.Title)
	}
}
```

執行結果：

```text
新增 1 Go 入門
新增 2 SQL 速查
新增 3 演算法
```

- `db.Prepare(SQL)` 回傳 `*sql.Stmt`，SQL 裡一樣用 `?` 佔位。
- `stmt.Exec(參數...)` 的用法和 `db.Exec` 一樣，只是不用再寫 SQL。
- `Stmt` 會佔用資料庫的資源，用完要 `Close`，所以照例緊接著 `defer stmt.Close()`。

### 查詢也可以預備

`Stmt` 也有 `QueryRow` 和 `Query`，用法和 `db` 上的一樣：

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

	db.Exec("CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT, price INTEGER)")
	db.Exec("INSERT INTO books (title, price) VALUES (?, ?), (?, ?)", "Go 入門", 450, "SQL 速查", 300)

	priceOf, err := db.Prepare("SELECT price FROM books WHERE title = ?")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer priceOf.Close()

	for _, title := range []string{"SQL 速查", "Go 入門", "Rust 入門"} {
		var price int
		err := priceOf.QueryRow(title).Scan(&price)
		if errors.Is(err, sql.ErrNoRows) {
			fmt.Printf("%s：沒有這本書\n", title)
			continue
		}
		if err != nil {
			fmt.Println(err)
			return
		}
		fmt.Printf("%s：%d 元\n", title, price)
	}
}
```

執行結果：

```text
SQL 速查：300 元
Go 入門：450 元
Rust 入門：沒有這本書
```

### 什麼時候用 `Prepare`

- **同一段 SQL 要在迴圈裡跑很多次**：用 `Prepare`，省下重複解析的時間。
- **只跑一次**：直接用 `db.Exec`、`db.QueryRow` 就好。其實它們在背後也會幫你準備、執行、關閉，只是用完就丟。

不管有沒有用 `Prepare`，參數都是和 SQL 分開送的，所以兩種寫法一樣能防止第 2 集講的 SQL injection。`Prepare` 是為了效率，不是為了安全。

## 重點整理

- `db.Prepare(SQL)` 先讓資料庫解析好 SQL，得到 `*sql.Stmt`，之後用 `stmt.Exec`、`stmt.QueryRow`、`stmt.Query` 帶參數執行。
- `Stmt` 用完要 `Close`，習慣寫 `defer stmt.Close()`。
- 同一段 SQL 要重複執行很多次時才值得用 `Prepare`；只跑一次就直接用 `db` 的方法。
- 防 SQL injection 靠的是 `?` 參數，`db.Exec` 和 `Prepare` 都有。
