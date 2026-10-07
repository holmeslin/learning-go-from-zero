# `sync.Mutex`

## 本集目標

學會用 `sync.Mutex` 保護共用的變數，讓同一時間只有一個 goroutine 能修改它。

## 正文

### 一把鎖

上一集的計數器算錯，是因為好幾個 goroutine 同時在改 `count`。解決辦法很直覺：在 `count` 旁邊放一把**鎖**，誰要改它，就先把鎖鎖上，改完再打開。別人想進來，就只能在門口排隊。

`sync.Mutex` 就是這把鎖（mutex 是 mutual exclusion「互斥」的縮寫）。它只有兩個主要的方法：

- `Lock()`：鎖上。如果已經被別人鎖住了，就一直等到對方打開為止。
- `Unlock()`：打開。

### 修好計數器

```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	count := 0
	var mu sync.Mutex
	var wg sync.WaitGroup
	for range 100 {
		wg.Go(func() {
			for range 1000 {
				mu.Lock()
				count++
				mu.Unlock()
			}
		})
	}
	wg.Wait()
	fmt.Println(count)
}
```

執行結果：

```text
100000
```

這次每次執行都是 100000，用 `go run -race .` 跑也不會再出現警告。`mu.Lock()` 和 `mu.Unlock()` 中間的這一段程式碼，同一時間只有一個 goroutine 能執行，這一段叫做**臨界區**（critical section）。

第 3 章說過 `sync.Mutex` 的零值就是一把沒鎖上的鎖，所以 `var mu sync.Mutex` 宣告完就能直接用。

### 把鎖和資料放在一起

實際的程式裡，習慣把鎖和它要保護的資料放在同一個 struct 裡，再用方法包起來，使用的人就不必自己記得上鎖：

```go
package main

import (
	"fmt"
	"sync"
)

type Counter struct {
	mu     sync.Mutex
	counts map[string]int
}

func (c *Counter) Add(name string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.counts[name]++
}

func (c *Counter) Get(name string) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.counts[name]
}

func main() {
	c := Counter{counts: map[string]int{}}
	var wg sync.WaitGroup
	for range 50 {
		wg.Go(func() {
			c.Add("小明")
			c.Add("小美")
		})
	}
	wg.Wait()
	fmt.Println(c.Get("小明"), c.Get("小美"))
}
```

執行結果：

```text
50 50
```

幾個值得學起來的習慣：

- **`Lock` 之後馬上 `defer Unlock`**。這樣不管函式從哪裡 `return`，甚至發生 panic，鎖都一定會打開。忘記打開的鎖，會讓其他 goroutine 永遠等下去。
- **讀也要上鎖**。`Get` 只是讀，但如果讀的同時有人在寫，一樣是 data race。
- map 本身不能同時被好幾個 goroutine 修改，一定要有鎖保護。
- 鎖住的範圍越小越好，只包住真正碰到共用資料的程式碼，其他 goroutine 才不用排隊太久。

### 不要複製 Mutex

注意 `Add`、`Get` 都是**指標接收者**。如果寫成值接收者，每次呼叫方法都會複製一份 struct，連鎖也一起複製，大家各鎖各的，等於沒鎖。`go vet` 會抓出這個錯誤。把上面範例的 `Get` 改成值接收者：

```go,ignore
func (c Counter) Get(name string) int {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.counts[name]
}
```

```bash
go vet .
```

```text
main.go:19:9: Get passes lock by value: example.Counter contains sync.Mutex
```

`example` 是範例模組的名字，你的會是自己 `go mod init` 時取的名字。只要 struct 裡有 `sync.Mutex`，方法一律用指標接收者，也不要把這種 struct 當成值傳來傳去。

## 重點整理

- `sync.Mutex` 是一把鎖：`Lock` 鎖上、`Unlock` 打開，同一時間只有一個 goroutine 能進入兩者之間的臨界區。
- `Lock` 之後立刻 `defer Unlock()`，避免忘記解鎖。
- 讀和寫共用的資料都要上鎖；map 被多個 goroutine 修改時一定要保護。
- 習慣把鎖和資料放在同一個 struct，方法用指標接收者；Mutex 不能複製，`go vet` 會檢查。
