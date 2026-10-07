# `sql.Open` 與 SQLite driver

## 本集目標

在自己的專案裝好 SQLite driver，用 `sql.Open` 開啟一個記憶體資料庫，並了解 blank import 在這裡的作用。

## 正文

### 資料庫與 SQL

**資料庫**是專門保管資料的程式。資料放在一張張**資料表**（table）裡，長得很像試算表：每一**列**（row）是一筆資料，每一**欄**（column）是一個欄位。我們用 **SQL** 這種語言對資料庫下指令，例如「新增一列」「找出分數大於 60 的列」。SQL 指令會在接下來幾集一邊用一邊介紹。

**SQLite** 是一種很小的資料庫，整個資料庫就是一個檔案，甚至可以只放在記憶體裡，不用另外架伺服器，很適合練習。

### 兩個角色：`database/sql` 與 driver

Go 把工作分成兩半：

- 標準庫的 `database/sql`：定義大家共用的操作方式，像是 `Open`、`Exec`、`Query`。
- **driver**（驅動程式）：負責跟某一種資料庫真正溝通的套件，由各資料庫社群提供。

我們寫程式時只呼叫 `database/sql`，它再把工作轉交給 driver。換資料庫時，大部分程式碼都不用改。

標準庫沒有內建任何 driver，所以這裡要用到第三方套件。本書選的是 `modernc.org/sqlite`，它是**純 Go** 寫成的 SQLite。另一個常見的選擇是 `github.com/mattn/go-sqlite3`，但它透過 cgo 呼叫 C 語言版的 SQLite（第 11 章介紹過 cgo），電腦上要有 C 編譯器，交叉編譯也比較麻煩。純 Go 的版本只要有 Go 就能編譯。

### 安裝 driver

在自己的模組資料夾裡，用第 8 章學過的 `go get`：

```bash
go mod init dbdemo
go get modernc.org/sqlite
```

`go.mod` 會多出 `require modernc.org/sqlite ...` 和一些它間接需要的模組。本書範例鎖定的版本是 `v1.60.1`，你拿到的可能更新，用法相同。

### 第一支程式

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
		fmt.Println("開啟失敗：", err)
		return
	}
	defer db.Close()
	db.SetMaxOpenConns(1)

	if err := db.Ping(); err != nil {
		fmt.Println("連線失敗：", err)
		return
	}
	fmt.Println("連線成功")
	fmt.Println(sql.Drivers())
}
```

執行結果：

```text
連線成功
[sqlite]
```

一行一行看：

- `_ "modernc.org/sqlite"`：前面加底線的 import 叫 **blank import**。我們在程式裡不會直接用到這個套件的任何名稱，只是要它被載入。慣例上把它和標準庫分成兩組，中間空一行（`goimports` 這類工具會自動這樣排）。
- `sql.Open("sqlite", ":memory:")`：第一個參數是 driver 的名字，第二個是資料來源。`:memory:` 是 SQLite 的特殊寫法，代表「資料庫放在記憶體裡」，程式結束就消失，所以每次執行的結果都一樣。要存成檔案的話，改成檔名，例如 `"shop.db"`。
- `db` 的型別是 `*sql.DB`。用完要 `Close`，所以緊接著 `defer db.Close()`。
- `sql.Open` 其實**還沒有真的連線**，只是準備好設定。`db.Ping()` 才會實際連一次，確認資料庫能用。
- `sql.Drivers()` 列出目前註冊過的 driver 名字。

### blank import 做了什麼

`modernc.org/sqlite` 套件裡有一個 `init` 函式（第 8 章學過，會在 `main` 之前自動執行），裡面呼叫 `sql.Register("sqlite", ...)`，把自己登記在 `database/sql` 的名單上。之後 `sql.Open("sqlite", ...)` 就是照名字去名單裡找。

如果忘了這行 import，名單上就沒有 `sqlite`：

```go
package main

import (
	"database/sql"
	"fmt"
)

func main() {
	_, err := sql.Open("sqlite", ":memory:")
	fmt.Println(err)
}
```

執行結果：

```text
sql: unknown driver "sqlite" (forgotten import?)
```

錯誤訊息還貼心地提醒你：是不是忘了 import？

### `:memory:` 與 `SetMaxOpenConns(1)`

`*sql.DB` 不是「一條」連線，而是一個**連線池**：需要時開新連線，用完放回去重複使用（第 8 集會細談）。

這對 `:memory:` 有個副作用：SQLite 的記憶體資料庫是**每條連線各有一份**。如果第一條連線建了資料表，下一次剛好拿到第二條連線，就會找不到那張表，出現 `no such table` 錯誤，而且時好時壞。

所以本章的範例在開啟後都會加一行 `db.SetMaxOpenConns(1)`，限制連線池最多只開一條連線，大家用的就一定是同一份資料庫。另一種做法是把資料來源寫成 `file::memory:?cache=shared`，讓同一個程式裡的連線共用一份記憶體資料庫；不過它有自己的鎖定規則，本書不採用。

用檔案資料庫時就沒有這個問題，不需要這行。

## 重點整理

- `database/sql` 提供共同的操作方式，真正跟資料庫溝通的是 driver；本書用純 Go、不需要 cgo 的 `modernc.org/sqlite`，driver 名稱是 `"sqlite"`。
- 用 `go get modernc.org/sqlite` 安裝，再用 blank import `_ "modernc.org/sqlite"` 載入；它的 `init` 會把 driver 註冊到 `database/sql`。
- `sql.Open` 只是準備，`db.Ping()` 才實際連線；`*sql.DB` 用完要 `defer db.Close()`。
- `:memory:` 是記憶體資料庫，每條連線各一份，所以要搭配 `db.SetMaxOpenConns(1)`。
