# `time`

## 本集目標

學會用 `time` 套件取得與建立時間、計算時間差（`Duration`）、用 Go 特有的「參考時間」格式化與解析時間，並處理時區。

## 正文

### 現在幾點：`time.Now`

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	now := time.Now()
	fmt.Println(now.Year(), now.Month(), now.Day())
	fmt.Println(now.Weekday())
}
```

執行結果（某一次）：

```text
2026 October 7
Wednesday
```

`time.Now()` 回傳一個 `time.Time`，代表此時此刻。`Year`、`Month`、`Day`、`Hour`、`Minute`、`Second`、`Weekday` 等方法可以取出各個部分。`Month` 和 `Weekday` 是有 `String` 方法的自訂型別（第 4 章的 `fmt.Stringer`），所以印出英文名稱。

因為每次執行結果都不一樣，這集接下來的範例改用 `time.Date` 建立一個**固定的**時間，讓輸出可以重現。

### 建立固定時間：`time.Date`

`time.Date(年, 月, 日, 時, 分, 秒, 奈秒, 時區)`：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	t := time.Date(2026, time.March, 14, 15, 9, 26, 0, time.UTC)
	fmt.Println(t)

	later := t.Add(90 * time.Minute)
	fmt.Println(later)
	fmt.Println(later.After(t))

	nextMonth := t.AddDate(0, 1, 0)
	fmt.Println(nextMonth)
}
```

執行結果：

```text
2026-03-14 15:09:26 +0000 UTC
2026-03-14 16:39:26 +0000 UTC
true
2026-04-14 15:09:26 +0000 UTC
```

- 月份用 `time.March` 這種常數，也可以寫 `3`。最後一個參數是時區，`time.UTC` 是世界標準時間。
- `Add` 加上一段時間；`AddDate(年, 月, 日)` 以日曆為單位加減。
- `Before`、`After`、`Equal` 比較先後。比較兩個時間是否相同要用 `Equal`，不要用 `==`，因為 `==` 連時區等內部資訊都會比。

### 一段時間：`time.Duration`

`time.Duration` 代表「多久」，底層是 `int64`，單位是奈秒（十億分之一秒）。套件提供 `time.Second`、`time.Minute`、`time.Hour` 等常數，用乘法組合：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	d := 2*time.Hour + 30*time.Minute + 15*time.Second
	fmt.Println(d)
	fmt.Println(d.Minutes())
	fmt.Println(1500 * time.Millisecond)

	start := time.Date(2026, 3, 14, 9, 0, 0, 0, time.UTC)
	end := time.Date(2026, 3, 14, 17, 45, 0, 0, time.UTC)
	work := end.Sub(start)
	fmt.Println("上班時間:", work)
	fmt.Println("超過 8 小時?", work > 8*time.Hour)

	n := 3
	fmt.Println(time.Duration(n) * time.Second)
}
```

執行結果：

```text
2h30m15s
150.25
1.5s
上班時間: 8h45m0s
超過 8 小時? true
3s
```

- 印出 `Duration` 時會自動顯示成 `2h30m15s` 這種好讀的格式。
- `end.Sub(start)` 算出兩個時間相差多久。量測程式跑了多久，常寫 `time.Since(start)`，它等於 `time.Now().Sub(start)`。
- `Duration` 可以直接比大小。
- 變數 `n` 是 `int`，要先轉成 `time.Duration` 才能和 `time.Second` 相乘（第 1 章的型別轉換）。常數 `3 * time.Second` 則不用轉，因為 `3` 是無型別常數（附錄一）。

第 9 章的 `time.After`、第 10 章的 `context.WithTimeout` 收的都是 `Duration`。

### 格式化：記住 `2006-01-02 15:04:05`

大部分語言用 `YYYY-MM-DD` 這種代號描述格式。Go 的做法很特別：直接寫出一個**參考時間**長成你要的樣子。這個參考時間是：

```text
2006-01-02 15:04:05
```

也就是「2006 年 1 月 2 日 下午 3 點 4 分 5 秒」。依美式順序排列剛好是 1 月、2 日、3 時、4 分、5 秒、06 年，很好記：

| 寫法 | 代表 |
| --- | --- |
| `2006` | 四位數年份 |
| `01` / `1` | 月（補零／不補零） |
| `02` / `2` | 日 |
| `15` / `03` | 24 小時制／12 小時制的時 |
| `04` | 分 |
| `05` | 秒 |
| `PM` | 上午／下午 |
| `Mon` / `Jan` | 星期／月份的英文縮寫 |
| `-0700` / `MST` | 時區 |

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	t := time.Date(2026, time.March, 14, 15, 9, 26, 0, time.UTC)

	fmt.Println(t.Format("2006-01-02 15:04:05"))
	fmt.Println(t.Format("2006/1/2"))
	fmt.Println(t.Format("03:04 PM"))
	fmt.Println(t.Format("Mon, Jan 2"))
	fmt.Println(t.Format(time.DateOnly))
	fmt.Println(t.Format(time.RFC3339))
}
```

執行結果：

```text
2026-03-14 15:09:26
2026/3/14
03:09 PM
Sat, Mar 14
2026-03-14
2026-03-14T15:09:26Z
```

常用格式也有現成的常數：`time.DateTime`（`2006-01-02 15:04:05`）、`time.DateOnly`、`time.TimeOnly`，以及網路上常見的 `time.RFC3339`。

最常見的錯誤是寫成 `"YYYY-MM-DD"` 或寫錯數字（例如把日寫成 `03`），Go 不會報錯，只會印出奇怪的結果。格式化的結果怪怪的，先檢查格式字串是不是照參考時間寫的。

### 解析：`time.Parse`

反過來把字串變成 `time.Time`，用 `time.Parse(格式, 字串)`，格式的寫法一樣：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	t, err := time.Parse(time.DateTime, "2026-12-25 08:30:00")
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(t)
	fmt.Println(t.Month(), t.Day(), t.Hour())

	_, err = time.Parse(time.DateOnly, "2026/12/25")
	if err != nil {
		fmt.Println("格式不符:", err)
	}
}
```

執行結果：

```text
2026-12-25 08:30:00 +0000 UTC
December 25 8
格式不符: parsing time "2026/12/25" as "2006-01-02": cannot parse "/12/25" as "-"
```

字串裡沒有時區資訊時，`time.Parse` 會當成 UTC。

### 時區

同一個瞬間，在台北和倫敦的「幾點」不一樣。`t.In(時區)` 換成另一個時區來看，時間點本身不變：

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	taipei := time.FixedZone("UTC+8", 8*60*60)

	t := time.Date(2026, 3, 14, 15, 0, 0, 0, time.UTC)
	local := t.In(taipei)
	fmt.Println(t.Format(time.DateTime + " MST"))
	fmt.Println(local.Format(time.DateTime + " MST"))
	fmt.Println("是同一個時間點?", t.Equal(local))

	meeting, err := time.ParseInLocation(time.DateTime, "2026-03-14 09:00:00", taipei)
	if err != nil {
		fmt.Println("錯誤:", err)
		return
	}
	fmt.Println(meeting.UTC())
}
```

執行結果：

```text
2026-03-14 15:00:00 UTC
2026-03-14 23:00:00 UTC+8
是同一個時間點? true
2026-03-14 01:00:00 +0000 UTC
```

- `time.FixedZone(名稱, 和 UTC 差幾秒)` 建立一個固定時差的時區。台灣是 UTC+8，沒有夏令時間，用它就夠了。
- `time.ParseInLocation` 把字串當成某個時區的時間來解析。
- `t.UTC()` 換回 UTC，`t.Local()` 換成電腦設定的時區。

需要處理有夏令時間的地區時，用 `time.LoadLocation("America/New_York")` 這種 IANA 時區名稱載入，它需要系統裡有時區資料庫。

## 重點整理

- `time.Now()` 取得現在時間，`time.Date(...)` 建立指定時間；比較用 `Before`、`After`、`Equal`。
- `time.Duration` 代表一段時間，用 `time.Second` 等常數相乘；`Sub` 算時間差，`Add` 加上一段時間。
- 格式化與解析都用參考時間 `2006-01-02 15:04:05` 描述格式；常用格式有 `time.DateTime`、`time.DateOnly`、`time.RFC3339`。
- `t.In(時區)` 換時區看同一個時間點；`time.FixedZone` 建立固定時差的時區，`time.ParseInLocation` 以指定時區解析。
