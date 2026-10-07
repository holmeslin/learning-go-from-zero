# `sync.RWMutex`

## 本集目標

知道 `sync.RWMutex` 可以讓很多 goroutine 同時讀，只有寫的時候才需要獨占，並知道什麼時候該用它。

## 正文

### 讀的人不必互相排隊

上一集的 `Mutex` 很嚴格：不管是讀還是寫，同一時間只能有一個 goroutine 進去。

可是仔細想想，好幾個人同時**讀**同一份資料，並不會出問題；會出問題的只有「有人在寫」的時候。就像圖書館的公告欄：大家可以同時站在前面看，但工作人員要換公告時，得請大家先讓開。

`sync.RWMutex`（讀寫鎖）就是這樣設計的，它有兩種鎖法：

| 方法 | 用途 | 規則 |
| --- | --- | --- |
| `RLock()` / `RUnlock()` | 讀 | 很多 goroutine 可以同時持有讀鎖 |
| `Lock()` / `Unlock()` | 寫 | 同一時間只能有一個，而且這時候沒有人能讀 |

### 一個查詢用的快取

假設我們有一份商品價格表，大部分時間都在查價格，偶爾才會更新：

```go
package main

import (
	"fmt"
	"sync"
)

type PriceTable struct {
	mu     sync.RWMutex
	prices map[string]int
}

func (p *PriceTable) Get(name string) (int, bool) {
	p.mu.RLock()
	defer p.mu.RUnlock()
	price, ok := p.prices[name]
	return price, ok
}

func (p *PriceTable) Set(name string, price int) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.prices[name] = price
}

func main() {
	table := PriceTable{prices: map[string]int{"咖啡": 60, "紅茶": 30}}

	var wg sync.WaitGroup
	for range 10 {
		wg.Go(func() {
			table.Get("咖啡")
		})
	}
	wg.Go(func() {
		table.Set("咖啡", 65)
	})
	wg.Wait()

	price, ok := table.Get("咖啡")
	fmt.Println(price, ok)
	_, ok = table.Get("綠茶")
	fmt.Println(ok)
}
```

執行結果：

```text
65 true
false
```

- `Get` 只讀 map，所以用 `RLock`／`RUnlock`，10 個 goroutine 可以同時查價格，不用排隊。
- `Set` 會改 map，所以用 `Lock`／`Unlock`。它要等所有正在讀的 goroutine 都 `RUnlock` 之後才能進去，進去之後，其他人讀寫都要等它結束。
- 和 `Mutex` 一樣，`RWMutex` 的零值就能用，也一樣不能複製，方法要用指標接收者。

### 不要在讀鎖裡寫入

最常見的錯誤是只拿了讀鎖，卻修改了資料：

```go,ignore
func (p *PriceTable) Discount(name string) {
	p.mu.RLock()
	defer p.mu.RUnlock()
	p.prices[name] -= 5 // 錯！讀鎖不能用來保護寫入
}
```

讀鎖允許好幾個 goroutine 同時進來，如果大家都在寫，就又是 data race 了。只要會修改，就用 `Lock`。

### 什麼時候用 `RWMutex`

`RWMutex` 本身比 `Mutex` 複雜，管理起來的成本也比較高。只有在「讀很多、寫很少」，而且讀的動作要花一點時間時，它才會比較快。

如果不確定，先用 `Mutex` 就好。程式正確比快一點重要，真的遇到效能問題再換也不遲。

## 重點整理

- `sync.RWMutex` 有讀鎖 `RLock`/`RUnlock` 和寫鎖 `Lock`/`Unlock`。
- 很多 goroutine 可以同時持有讀鎖；寫鎖同一時間只有一個，而且會擋住所有讀和寫。
- 只拿讀鎖時不可以修改資料。
- 適合「讀很多、寫很少」的情況；不確定時用 `Mutex`。
