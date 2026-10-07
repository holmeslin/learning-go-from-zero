# `Query` 與 `Rows`

## 本集目標

用 `db.Query` 查出**多列**資料，學會 `for rows.Next()` 走訪、`defer rows.Close()` 與最後檢查 `rows.Err()`。

## 正文

### 一次查很多列

`db.Query` 回傳 `*sql.Rows`，可以一列一列往下讀：

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

	rows, err := db.Query("SELECT id, title, price FROM books WHERE price > ? ORDER BY price DESC", 350)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var id, price int
		var title string
		if err := rows.Scan(&id, &title, &price); err != nil {
			fmt.Println(err)
			return
		}
		fmt.Println(id, title, price)
	}
	if err := rows.Err(); err != nil {
		fmt.Println(err)
		return
	}
}
```

執行結果：

```text
3 演算法 520
1 Go 入門 450
```

`ORDER BY price DESC` 讓結果依價格由高到低排列（`DESC` 是遞減；不寫或寫 `ASC` 是遞增）。沒有 `ORDER BY` 時，資料庫不保證順序。

整個流程分四步，這是固定寫法：

1. `rows, err := db.Query(...)`，先檢查 `err`。
2. **馬上** `defer rows.Close()`。
3. `for rows.Next() { rows.Scan(...) }`：`Next` 移到下一列，有資料回傳 `true`，讀完了回傳 `false`。
4. 迴圈結束後檢查 `rows.Err()`。

### 為什麼要 `rows.Close()`

`Rows` 讀資料的期間會一直**佔住一條連線**。讀完最後一列時 `Rows` 會自動關閉，但如果中途 `return` 或 `break`，沒人關它，連線就一直被佔著。`defer rows.Close()` 保證不管怎麼離開都會歸還連線；重複呼叫 `Close` 也沒關係。

我們的範例把連線池限制在一條連線，這個問題會特別明顯：`rows` 還沒關閉之前，如果在迴圈裡又呼叫 `db.QueryRow` 或 `db.Exec`，它會一直等那條被佔住的連線，程式就卡住了（像這樣的小程式，Go 會偵測到第 9 章講過的死結而當掉）。想要邊讀邊查，就先把結果讀進切片、關掉 `rows` 之後再查。

### 為什麼要 `rows.Err()`

`rows.Next()` 回傳 `false` 有兩種可能：資料真的讀完了，或是讀到一半出錯（例如連線斷了）。光看迴圈結束分不出來，所以最後要問一下 `rows.Err()`，它是 `nil` 才代表全部讀完。

### 包成函式，回傳切片

實際程式通常把查詢包成函式，回傳 struct 切片：

```go
package main

import (
	"database/sql"
	"fmt"

	_ "modernc.org/sqlite"
)

type Book struct {
	ID    int
	Title string
	Price int
}

func listBooks(db *sql.DB, maxPrice int) ([]Book, error) {
	rows, err := db.Query("SELECT id, title, price FROM books WHERE price <= ? ORDER BY id", maxPrice)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var books []Book
	for rows.Next() {
		var b Book
		if err := rows.Scan(&b.ID, &b.Title, &b.Price); err != nil {
			return nil, err
		}
		books = append(books, b)
	}
	return books, rows.Err()
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
	db.Exec("INSERT INTO books (title, price) VALUES (?, ?), (?, ?), (?, ?)",
		"Go 入門", 450, "SQL 速查", 300, "演算法", 520)

	books, err := listBooks(db, 500)
	if err != nil {
		fmt.Println(err)
		return
	}
	fmt.Println(len(books), "本")
	for _, b := range books {
		fmt.Printf("%+v\n", b)
	}

	books, _ = listBooks(db, 100)
	fmt.Println(len(books), "本", books == nil)
}
```

執行結果：

```text
2 本
{ID:1 Title:Go 入門 Price:450}
{ID:2 Title:SQL 速查 Price:300}
0 本 true
```

注意兩件事：

- 最後一行 `return books, rows.Err()`，把 `rows.Err()` 的結果直接當錯誤回傳。
- 一列都沒查到時，`Query` **不會**回傳 `sql.ErrNoRows`（那是 `QueryRow` 才有的），只是迴圈一次都不執行，得到 `nil` 切片。

## 重點整理

- `db.Query` 回傳 `*sql.Rows`，用 `for rows.Next()` 一列一列讀，每列用 `rows.Scan` 取值。
- 檢查完 `err` 就馬上 `defer rows.Close()`，避免連線一直被佔住。
- 迴圈結束後要檢查 `rows.Err()`，才知道是讀完了還是中途出錯。
- `Query` 查不到資料不算錯誤，只是迴圈不執行；要固定順序就加 `ORDER BY`。
