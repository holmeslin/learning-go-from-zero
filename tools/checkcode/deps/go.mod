// 書中範例共用的 go.mod：checkcode 會把它和 go.sum 複製到每個範例的暫存目錄。
// 範例需要第三方套件時（目前只有第 15 章的 SQLite driver），在這裡鎖定版本。
module example

go 1.27

require modernc.org/sqlite v1.60.1

require (
	github.com/dustin/go-humanize v1.0.1 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/mattn/go-isatty v0.0.24 // indirect
	github.com/ncruces/go-strftime v1.0.0 // indirect
	github.com/remyoudompheng/bigfft v0.0.0-20230129092748-24d4a6f8daec // indirect
	golang.org/x/sys v0.48.0 // indirect
	modernc.org/libc v1.77.1 // indirect
	modernc.org/mathutil v1.7.1 // indirect
	modernc.org/memory v1.12.1 // indirect
)
