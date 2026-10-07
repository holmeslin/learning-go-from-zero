# `QueryRow`

## 本集目標

用 `db.QueryRow` 查出**一列**資料，用 `Scan` 把欄位放進變數，並處理「查不到」的 `sql.ErrNoRows`。

## 正文

### `SELECT` 與 `Scan`

查詢資料的 SQL 是 `SELECT`：`SELECT title, price FROM books WHERE id = ?` 的意思是「從 `books` 找出 `id` 等於某值的列，給我 `title` 和 `price` 兩欄」。

只要一列時，用 `db.QueryRow`：

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
	db.Exec("INSERT INTO books (title, price) VALUES (?, ?), (?, ?)",
		"Go 入門", 450, "SQL 速查", 300)

	var title string
	var price int
	err = db.QueryRow("SELECT title, price FROM books WHERE id = ?", 2).Scan(&title, &price)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Printf("%s：%d 元\n", title, price)
}
```

執行結果：

```text
SQL 速查：300 元
```

- `db.QueryRow(...)` 送出查詢，回傳 `*sql.Row`。
- `.Scan(&title, &price)` 把那一列的欄位**依序**存進變數。要傳指標，`Scan` 才能改到我們的變數（第 3 章的 `&`）。
- 錯誤統一在 `Scan` 時回傳，所以只要檢查 `Scan` 的 `err`。

`SELECT` 的欄位數量要和 `Scan` 的參數數量一樣多，型別也要對得上：`TEXT` 放進 `string`、`INTEGER` 放進 `int` 或 `int64`。

### 查不到：`sql.ErrNoRows`

如果 `WHERE` 沒有任何一列符合，`Scan` 會回傳哨兵錯誤 `sql.ErrNoRows`。「查不到」通常不是程式壞掉，而是正常的情況，所以要跟其他錯誤分開處理。用第 5 章的 `errors.Is` 判斷：

```go
package main

import (
	"database/sql"
	"errors"
	"fmt"

	_ "modernc.org/sqlite"
)

type Book struct {
	Title string
	Price int
}

var ErrNotFound = errors.New("找不到這本書")

func findBook(db *sql.DB, id int) (Book, error) {
	var b Book
	err := db.QueryRow("SELECT title, price FROM books WHERE id = ?", id).Scan(&b.Title, &b.Price)
	if errors.Is(err, sql.ErrNoRows) {
		return Book{}, ErrNotFound
	}
	if err != nil {
		return Book{}, fmt.Errorf("查詢第 %d 本書：%w", id, err)
	}
	return b, nil
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
	db.Exec("INSERT INTO books (title, price) VALUES (?, ?)", "Go 入門", 450)

	for _, id := range []int{1, 99} {
		b, err := findBook(db, id)
		if err != nil {
			fmt.Println(id, err)
			continue
		}
		fmt.Println(id, b.Title, b.Price)
	}

	fmt.Println(sql.ErrNoRows)
}
```

執行結果：

```text
1 Go 入門 450
99 找不到這本書
sql: no rows in result set
```

幾個細節：

- `Scan` 可以直接掃進 struct 的欄位：`&b.Title`、`&b.Price`。
- `findBook` 把 `sql.ErrNoRows` 換成自己套件的 `ErrNotFound`，呼叫的人不必知道底層用的是 `database/sql`。其他錯誤則用 `%w` 包起來往上傳。
- 最後一行印出 `sql.ErrNoRows` 本身的訊息給你看看。

### 只要一個數字

`QueryRow` 也很適合查「一個值」，例如用 `COUNT(*)` 數有幾列：

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

	var count, total int
	err = db.QueryRow("SELECT COUNT(*), SUM(price) FROM books WHERE price >= ?", 400).Scan(&count, &total)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(count, "本，共", total, "元")
}
```

執行結果：

```text
2 本，共 970 元
```

`COUNT(*)` 算列數、`SUM(price)` 加總價格。這種查詢一定會回傳一列，不會遇到 `ErrNoRows`。

## 重點整理

- `db.QueryRow(SQL, 參數...).Scan(&a, &b)` 查出一列，依序把欄位存進變數；要傳指標。
- 錯誤在 `Scan` 時才回傳，只要檢查 `Scan` 的 `err`。
- 查不到資料時 `Scan` 回傳 `sql.ErrNoRows`，用 `errors.Is` 判斷，和其他錯誤分開處理。
- `SELECT` 的欄位數量、型別要和 `Scan` 的參數對得上。
