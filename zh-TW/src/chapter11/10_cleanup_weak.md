# `runtime.AddCleanup` 與 `weak`

## 本集目標

認識 Go 1.24 加入的兩個和垃圾回收有關的工具：用 `runtime.AddCleanup` 在物件被回收後執行清理，用 `weak.Pointer` 指向物件又不阻止它被回收。也要知道它們的執行時機無法預測，不能拿來取代 `defer` 和 `Close`。

## 正文

### 先複習：垃圾回收

Go 有**垃圾回收**（garbage collection，簡稱 GC）：一個值如果再也沒有任何變數或指標指到它，Go 會在某個時候自動把它佔的記憶體收回來。我們從來不用自己釋放記憶體，就是因為有 GC。

「某個時候」是重點：GC 什麼時候執行、某個物件什麼時候被回收，由 Go 自己決定，程式無法準確預測。附錄二會再介紹 GC 的運作方式。`runtime.GC()` 可以要求 Go 立刻做一次 GC，這一集的範例會用它來觸發回收，但正式的程式幾乎不會呼叫它。

### `runtime.AddCleanup`：被回收之後做點事

有些物件除了記憶體，還握著**記憶體以外的資源**，例如作業系統的檔案編號。GC 只會回收記憶體，不會幫你關檔案。`runtime.AddCleanup` 可以登記：「這個物件被回收之後，請呼叫某個函式」：

```go,ignore
func AddCleanup[T, S any](ptr *T, cleanup func(S), arg S) Cleanup
```

`ptr` 被回收後，Go 會在另一個 goroutine 裡呼叫 `cleanup(arg)`。

```go
package main

import (
	"fmt"
	"runtime"
	"time"
)

type File struct {
	name string
	fd   int
}

func openFile(name string, fd int, cleaned chan<- int) *File {
	f := &File{name: name, fd: fd}
	runtime.AddCleanup(f, func(fd int) {
		cleaned <- fd
	}, f.fd)
	return f
}

func main() {
	cleaned := make(chan int)

	f := openFile("data.txt", 3, cleaned)
	fmt.Println("使用", f.name)
	f = nil

	runtime.GC()
	select {
	case fd := <-cleaned:
		fmt.Println("已清理檔案編號", fd)
	case <-time.After(time.Second):
		fmt.Println("一秒內沒有清理")
	}
}
```

執行結果：

```text
使用 data.txt
已清理檔案編號 3
```

一步一步看：

- `File` 假裝握著一個檔案編號 `fd`。`AddCleanup` 的第三個參數 `f.fd` 會在清理時交給清理函式。
- `f = nil` 之後，再也沒有東西指向那個 `File`，`runtime.GC()` 把它回收，清理函式就被呼叫了。
- 清理函式在別的 goroutine 執行，所以用 channel 把結果送回 `main` 印出，並用第 9 章的 `select` 加逾時，避免永遠等下去。

這個範例我們多次執行，結果都一樣；但這是因為例子很小、又手動呼叫了 `runtime.GC()`。在一般程式裡，清理函式可能很久之後才執行，甚至程式結束前都沒有執行。

### 清理函式不能碰到物件本身

注意清理函式收到的是 `f.fd`，不是 `f`。如果清理函式或 `arg` 還能碰到 `f`，`f` 就永遠有人指著，永遠不會被回收，清理也永遠不會發生。直接把 `f` 本身當成 `arg` 傳進去，`AddCleanup` 會 panic。

`AddCleanup` 回傳一個 `runtime.Cleanup`，呼叫它的 `Stop()` 方法可以取消登記。例如使用者已經自己呼叫 `Close` 把檔案關好了，就不需要再清理一次。

舊的程式碼裡可能會看到 `runtime.SetFinalizer`，做的是類似的事，但它有不少陷阱：一個物件只能設定一個、函式會拿到物件本身而讓物件「復活」、互相指向的物件可能永遠不會被回收。Go 1.24 起，新程式碼請用 `AddCleanup`。

### `weak.Pointer`：不留住物件的指標

一般的指標會「留住」物件：只要指標還在，物件就不會被回收。有時候我們想記住一個物件，但**不想因此讓它一直佔著記憶體**，例如快取：還有人在用就直接拿來用，沒人用了就讓 GC 收走。

Go 1.24 加入的 `weak` 套件提供**弱指標**。`weak.Make(p)` 從一般指標做出弱指標，`Value()` 取回一般指標；如果物件已經被回收，`Value()` 回傳 `nil`：

```go
package main

import (
	"fmt"
	"runtime"
	"weak"
)

type Image struct {
	name   string
	pixels []byte
}

func main() {
	img := &Image{name: "cat.png", pixels: make([]byte, 1024)}
	wp := weak.Make(img)

	if p := wp.Value(); p != nil {
		fmt.Println("還拿得到:", p.name)
	}

	img = nil
	runtime.GC()

	if wp.Value() == nil {
		fmt.Println("已經被回收了")
	}
}
```

執行結果：

```text
還拿得到: cat.png
已經被回收了
```

- `weak.Make` 是泛型函式（第 6 章），`wp` 的型別是 `weak.Pointer[Image]`。
- 只要 `img` 還指著物件，`wp.Value()` 就拿得到。
- `img = nil` 後，只剩弱指標指著它，弱指標不算數，GC 就把物件回收了，`wp.Value()` 變成 `nil`。

使用弱指標時，每次都要先用 `Value()` 取出一般指標、檢查是不是 `nil`，再使用取出來的那個指標。

### 時機不可靠，別拿來管資源

`AddCleanup` 和 `weak` 都和 GC 綁在一起，而 GC 的時機無法預測。所以：

- 檔案、網路連線這類資源，還是要用 `Close` 加上第 5 章的 `defer` 明確關閉。`AddCleanup` 頂多當作「忘記關的時候的最後保險」。
- 程式的正確性不能依賴「清理一定會發生」或「什麼時候發生」。
- 它們主要出現在寫底層套件、快取的情況，一般程式很少直接用到。

## 重點整理

- GC 什麼時候回收物件無法預測；`runtime.GC()` 可以手動觸發，但正式程式很少用。
- `runtime.AddCleanup(ptr, cleanup, arg)`（Go 1.24）在 `ptr` 被回收後於另一個 goroutine 呼叫 `cleanup(arg)`；`arg` 和清理函式都不能指到 `ptr`；回傳值的 `Stop()` 可以取消。新程式用它取代 `runtime.SetFinalizer`。
- `weak.Make(p)`（Go 1.24）做出不會留住物件的弱指標；`Value()` 取回一般指標，物件已被回收時回傳 `nil`。
- 兩者的時機都不可靠，資源一定要用 `Close` 和 `defer` 明確釋放。
