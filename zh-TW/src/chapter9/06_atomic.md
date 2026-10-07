# `sync/atomic`

## 本集目標

學會用 `sync/atomic` 套件的 `atomic.Int64` 等型別，在不用鎖的情況下安全地更新一個數字或布林值。

## 正文

### 只是加個 1，也要上鎖？

第 4 集用 `Mutex` 修好了計數器。可是如果要保護的只是一個數字，每次都 `Lock`、`Unlock` 有點大費周章。

`sync/atomic` 套件提供「原子操作」（atomic operation）。「原子」在這裡的意思是**不可分割**：第 3 集說 `count++` 其實是讀、加、寫三步，別人可能插進來；原子操作則保證這三步一次完成，中間沒有人能插隊。

### `atomic.Int64`

最常用的是 `atomic.Int64` 這類型別：

```go
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

func main() {
	var count atomic.Int64
	var wg sync.WaitGroup
	for range 100 {
		wg.Go(func() {
			for range 1000 {
				count.Add(1)
			}
		})
	}
	wg.Wait()
	fmt.Println(count.Load())
}
```

執行結果：

```text
100000
```

- `var count atomic.Int64`：零值就是 0，直接能用。
- `count.Add(1)`：原子地加 1，回傳加完之後的值（這裡用不到，就不接）。
- `count.Load()`：原子地讀出目前的值。

注意不能直接寫 `count++` 或 `fmt.Println(count)`：`atomic.Int64` 是一個 struct，所有讀寫都要透過它的方法。這反而是好事，因為你不可能「不小心」用了不安全的方式存取它。

### 常用的方法

| 方法 | 作用 |
| --- | --- |
| `Load()` | 讀出目前的值 |
| `Store(v)` | 把值設成 `v` |
| `Add(d)` | 加上 `d`，回傳新的值（減法就加負數） |
| `Swap(v)` | 設成 `v`，回傳舊的值 |
| `CompareAndSwap(old, new)` | 如果目前的值是 `old`，就換成 `new` 並回傳 `true`；否則什麼都不做，回傳 `false` |

除了 `atomic.Int64`，還有 `atomic.Int32`、`atomic.Uint64`、`atomic.Bool` 等型別，用法都一樣（`atomic.Bool` 沒有 `Add`）。

### `atomic.Bool` 與 `CompareAndSwap`

`CompareAndSwap` 可以做出「只有第一個人能成功」的效果。下面 5 個 goroutine 都想當第一名，但只有一個會搶到：

```go
package main

import (
	"fmt"
	"sync"
	"sync/atomic"
)

func main() {
	var taken atomic.Bool
	var winners atomic.Int32
	var wg sync.WaitGroup
	for range 5 {
		wg.Go(func() {
			if taken.CompareAndSwap(false, true) {
				winners.Add(1)
			}
		})
	}
	wg.Wait()
	fmt.Println("搶到的人數：", winners.Load())
	fmt.Println("已經被搶走：", taken.Load())
}
```

執行結果：

```text
搶到的人數： 1
已經被搶走： true
```

「檢查是不是 `false`，是的話改成 `true`」整件事是一次完成的，所以不會有兩個 goroutine 同時看到 `false`。哪一個 goroutine 搶到每次可能不同，但永遠只有一個。

### 舊式的函式寫法

讀別人的程式時，你可能會看到這種寫法：

```go,ignore
var count int64
atomic.AddInt64(&count, 1)
fmt.Println(atomic.LoadInt64(&count))
```

這是比較早期的寫法，把普通變數的指標交給 `atomic` 的函式。它的缺點是：只要有一個地方忘了透過 `atomic` 函式、直接寫 `count++`，就又是 data race。新程式請用 `atomic.Int64` 這類型別。

### atomic 還是 Mutex？

- 只保護**一個**數字或布林值，用 atomic，簡單又快。
- 要同時更新**好幾個**相關的值（例如 map、或「餘額」和「交易筆數」要一起改），用 `Mutex`。兩個各自原子的操作，合起來並不是原子的。

和 `Mutex` 一樣，atomic 型別開始使用後就不能複製，放在 struct 裡時方法要用指標接收者。

## 重點整理

- 原子操作是不可分割的讀寫，多個 goroutine 同時做也不會互相干擾。
- 用 `atomic.Int64`、`atomic.Int32`、`atomic.Bool` 等型別，透過 `Load`、`Store`、`Add`、`CompareAndSwap` 等方法存取。
- 舊式的 `atomic.AddInt64(&x, 1)` 寫法容易漏掉，新程式用型別寫法。
- 只保護單一值用 atomic；好幾個值要一起改用 `Mutex`。
