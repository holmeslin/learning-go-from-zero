# `runtime.AddCleanup` 與 `weak`

## 本集目標

認識 Go 1.24 加入的兩個和垃圾回收有關的工具：用 `runtime.AddCleanup` 在物件不再可達後安排清理，用 `weak.Pointer` 指向物件又不阻止它被回收。也要知道它們的執行時機無法預測，不能拿來取代 `defer` 和 `Close`。

## 正文

### 先複習：垃圾回收

Go 有**垃圾回收**（garbage collection，簡稱 GC）：物件如果已經無法從程式仍會使用的一般指標找到，也就是**不再可達**，Go 就可以把它佔的記憶體收回來。我們不用自己釋放 Go 管理的記憶體，就是因為有 GC。

變數還在作用域裡，不代表物件一定還可達。編譯器可能在變數最後一次真正使用後，就不再把它當成活的引用；不必等到離開函式或賦值成 `nil`。必要時可以在最後一個需要保活的位置之後呼叫 `runtime.KeepAlive(p)`，確保 `p` 指向的物件至少活到那裡。

「某個時候」是重點：GC 什麼時候執行、某個物件什麼時候被回收，由 Go 自己決定，程式無法準確預測。附錄二會再介紹 GC 的運作方式。`runtime.GC()` 可以要求 Go 立刻做一次 GC，這一集的範例會用它來觸發回收，但正式的程式幾乎不會呼叫它。

### `runtime.AddCleanup`：不再可達之後做點事

有些物件除了記憶體，還握著**記憶體以外的資源**，例如作業系統的檔案編號。GC 只會回收記憶體，不會幫你關檔案。`runtime.AddCleanup` 可以登記：「這個物件不再可達之後，請呼叫某個函式」：

```go,ignore
func AddCleanup[T, S any](ptr *T, cleanup func(S), arg S) Cleanup
```

`ptr` 指向的物件不再可達後，Go 可以在之後某個時間，於另一個 goroutine 裡呼叫 `cleanup(arg)`。不要把它理解成「記憶體已經釋放後」的通知。

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

執行結果（某一次）：

```text
使用 data.txt
已清理檔案編號 3
```

一步一步看：

- `File` 假裝握著一個檔案編號 `fd`。`AddCleanup` 的第三個參數 `f.fd` 會在清理時交給清理函式。
- `f = nil` 表示我們不再用它；這裡沒有其他一般指標留住那個 `File`。不過，物件可能在最後一次使用 `f` 後就已經不再可達，不是一定要等到這行。`runtime.GC()` 要求執行 GC，但不會等待清理函式執行完。
- 清理函式在別的 goroutine 執行，所以用 channel 把結果送回 `main` 印出，並用第 9 章的 `select` 加逾時，避免永遠等下去。

這是某一次的觀察；即使手動呼叫 `runtime.GC()`，也不保證一秒內執行清理，可能印出「一秒內沒有清理」。清理函式可能很久之後才執行，甚至程式結束前都沒有執行。

### 清理函式不能碰到物件本身

注意清理函式收到的是 `f.fd`，不是 `f`。如果清理函式或 `arg` 還能碰到 `f`，`f` 就永遠有人指著，永遠不會被回收，清理也永遠不會發生。直接把 `f` 本身當成 `arg` 傳進去，`AddCleanup` 會 panic。

`AddCleanup` 回傳一個 `runtime.Cleanup`，呼叫它的 `Stop()` 方法可以取消尚未排隊的清理；**已經排隊等待執行的清理，`Stop()` 不會撤銷**。若要保證取消，必須讓傳給 `AddCleanup` 的原物件跨過 `Stop()` 呼叫仍然可達，必要時在 `Stop()` 之後呼叫 `runtime.KeepAlive(原指標)`。真正包裝檔案的套件若提供 `Close`，就需要配合這個生命週期規則，不能只靠手上還有 `Cleanup` 值就以為物件被留住了。

舊的程式碼裡可能會看到 `runtime.SetFinalizer`，做的是類似的事，但它有不少陷阱：一個物件只能設定一個、函式會拿到物件本身而讓物件「復活」、互相指向的物件可能永遠不會被回收。Go 1.24 起，新程式碼請用 `AddCleanup`。

### `weak.Pointer`：不留住物件的指標

一般的指標會「留住」物件：只要物件仍可經由活的一般指標找到，就不會被回收。有時候我們想記住一個物件，但**不想因此讓它一直佔著記憶體**，例如快取：還有人在用就直接拿來用，沒人用了就讓 GC 收走。

Go 1.24 加入的 `weak` 套件提供**弱指標**。`weak.Make(p)` 從一般指標做出弱指標，`Value()` 取回一般指標；物件一旦不再可達，`Value()` 就可能回傳 `nil`：

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
	runtime.KeepAlive(img)

	img = nil
	runtime.GC()

	if wp.Value() == nil {
		fmt.Println("已經被回收了")
	}
}
```

執行結果（某一次）：

```text
還拿得到: cat.png
已經被回收了
```

- `weak.Make` 是泛型函式（第 6 章），`wp` 的型別是 `weak.Pointer[Image]`。
- `runtime.KeepAlive(img)` 放在第一次 `Value()` 使用之後，確保這段期間物件仍可達，所以第一次拿得到；不能只因為 `img` 還在作用域裡就認定它活著。
- 之後沒有一般指標留住物件，`wp.Value()` 就可能變成 `nil`。上面這次 GC 後印出了第二行，但不保證何時變成 `nil`，甚至不保證最終一定會變成 `nil`。

使用弱指標時，每次都要先用 `Value()` 取出一般指標、檢查是不是 `nil`，再使用取出來的那個指標。

### 時機不可靠，別拿來管資源

`AddCleanup` 和 `weak` 都和 GC 綁在一起，而 GC 的時機無法預測。所以：

- 檔案、網路連線這類資源，還是要用 `Close` 加上第 5 章的 `defer` 明確關閉。`AddCleanup` 頂多當作「忘記關的時候的最後保險」。
- 程式的正確性不能依賴「清理一定會發生」或「什麼時候發生」。
- 它們主要出現在寫底層套件、快取的情況，一般程式很少直接用到。

## 重點整理

- 作用域不等於可達性；物件可能在最後一次使用後就不再可達。`runtime.KeepAlive(p)` 可明確保活到呼叫處；`runtime.GC()` 不會等待清理完成。
- `runtime.AddCleanup(ptr, cleanup, arg)`（Go 1.24）可在物件不再可達後於另一個 goroutine 呼叫 `cleanup(arg)`；`arg` 和清理函式都不能指到 `ptr`。`Stop()` 不能撤銷已排隊的清理，要保證取消須讓原物件跨過呼叫仍可達。新程式優先用它而非 `runtime.SetFinalizer`。
- `weak.Make(p)`（Go 1.24）不會留住物件；每次使用 `Value()` 都要檢查 `nil`。物件不再可達就可能回傳 `nil`，但不保證最終一定如此。
- 兩者的時機都不可靠，資源一定要用 `Close` 和 `defer` 明確釋放。
