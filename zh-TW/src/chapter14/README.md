# 實戰：Web 服務

你每天用的 App 和網站，背後幾乎都有一台伺服器在回應 HTTP 請求。Go 的標準庫 `net/http` 本身就夠拿來寫正式上線的 Web 服務，不需要額外的框架，這也是很多公司選擇 Go 寫後端的原因之一。

這一章先架起第一個伺服器，接著學路由、`Handler` 介面、JSON API 與 middleware，再換到另一邊寫 HTTP client。後半段處理上線前一定要做好的事：逾時設定與 graceful shutdown。最後用 `httptest` 說明怎麼不開真正的網路連線就能測試這一切。
