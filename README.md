[![CC BY-NC-ND 4.0](https://img.shields.io/badge/content-CC%20BY--NC--ND%204.0-blue)](https://creativecommons.org/licenses/by-nc-nd/4.0/)
[![CC0 1.0](https://img.shields.io/badge/code-CC0%201.0-blue)](https://creativecommons.org/publicdomain/zero/1.0/)

# 從零開始學 Go

為程式新手準備的 Go 教學（Go 1.27），請閱讀[線上版](https://holmeslin.github.io/learning-go-from-zero/zh-TW/)。

## 本機建置

需要 Go 1.27 與 [mdBook](https://github.com/rust-lang/mdBook) 0.5.4：

```bash
go run ./tools/checkcode zh-TW/src   # 驗證書中所有 Go 範例
cd zh-TW && mdbook serve             # 本機預覽
```

### 範例程式碼標註

書中 ```` ```go ```` 區塊預設會跑 `go vet` 與 `go run`，必須成功結束。可在 info string 加上標註：

| 標註 | 意義 |
| --- | --- |
| `go,compile_fail` | 必須編譯失敗 |
| `go,stdin=3\n5` | 執行時餵入 stdin（`\n` 代表換行，值內不可有空白） |
| `go,exit=2` | 預期的結束碼（例如 panic、死結） |
| `go,norun` | 只編譯與 `go vet`，不執行（伺服器、signal） |
| `go,ignore` | 不驗證（片段、多檔案範例） |

範例共用 `tools/checkcode/deps/go.mod`；需要第三方套件時在那裡鎖定版本（目前只有第 15 章的 `modernc.org/sqlite`）。

## 授權

除非另有標示，本教學的文字、圖片與非程式碼內容以 [CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/) 授權。

本教學中的程式碼範例以 [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) 釋出，可自由複製、修改與使用。
