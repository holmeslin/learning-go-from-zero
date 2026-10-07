# 匯出

## 本集目標

知道 Go 用「名稱第一個字母的大小寫」決定其他套件能不能使用，並解開 `fmt.Println` 為什麼是大寫 P 的謎。

## 正文

### 大寫才能被外面看見

不知道你有沒有注意過：我們用的標準庫函式，`fmt.Println`、`strings.ToUpper`、`strconv.Atoi`，點後面的名字全都是大寫開頭。這不是巧合。

Go 的規則只有一條：

- 名稱以**大寫字母**開頭，其他套件就能使用，這叫**匯出**（exported）。
- 名稱以**小寫字母**開頭，只有同一個套件裡能用，外面看不到。

這條規則適用於函式、變數、常數、型別、struct 欄位、方法，所有東西都一樣。Go 沒有 `public`、`private` 這類關鍵字，大小寫本身就是開關。

所以 `fmt.Println` 一定得是大寫 P：`Println` 寫在 `fmt` 套件裡，我們的 `main` 套件要用它，它就必須是匯出的。

### 試試看用小寫的函式

延續上一集的 `myapp`，在 `greet` 套件加一個小寫開頭的函式：

`greet/greet.go`：

```go,ignore
package greet

func Hello(name string) string {
	return "你好，" + name + "！"
}

func shout(s string) string {
	return s + "！！！"
}
```

`main.go`：

```go,ignore
package main

import (
	"fmt"

	"myapp/greet"
)

func main() {
	fmt.Println(greet.Hello("小明"))
	fmt.Println(greet.shout("嗨"))
}
```

執行 `go build` 會失敗：

```text
./main.go:11:20: undefined: greet.shout
```

對 `main` 套件來說，`greet.shout` 就像不存在一樣。但 `greet` 套件自己的程式碼可以自由使用 `shout`，例如 `Hello` 裡面呼叫 `shout(...)` 完全沒問題。

### 為什麼要藏起來

把東西藏起來聽起來有點小氣，其實是好事。一個套件匯出的東西，等於對使用者的承諾：「這個可以放心用」。一旦別人用了，你就不能隨便改它的名字或參數，否則別人的程式會壞掉。

小寫的東西則是套件內部的細節，以後想怎麼改都可以，不會影響任何人。所以好習慣是：**只匯出真正需要給別人用的東西**，其他的一律小寫。

### struct 欄位也一樣

`greet` 套件裡的 struct：

```go,ignore
package greet

type Person struct {
	Name string
	age  int
}
```

其他套件可以讀寫 `p.Name`，但碰不到 `p.age`。第 7 章的 `Playlist` 把 `songs` 寫成小寫，如果把它搬到獨立的套件，其他套件就只能透過 `Add` 和 `All` 方法操作，不會不小心把內部的切片弄亂。

## 重點整理

- 大寫開頭的名稱會被匯出，其他套件可以使用；小寫開頭的只限同一個套件內使用。
- 規則適用於函式、變數、常數、型別、struct 欄位和方法。
- `fmt.Println` 是大寫，因為它定義在 `fmt` 套件，要給其他套件使用。
- 只匯出必要的東西，內部細節用小寫，之後才能放心修改。
