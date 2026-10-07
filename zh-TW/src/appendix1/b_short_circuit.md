# 短路求值

## 本集目標

了解 `&&` 和 `||` 什麼時候會「不看右邊」，並利用這個特性安全地檢查 `nil`。

## 正文

第 1 章學邏輯運算子時，我們只關心 `&&`、`||` 算出來是 `true` 還是 `false`。其實它們還有一個重要的行為：**右邊不一定會執行**。

### 答案已經確定，就不看右邊

想想看：

- `a && b`：只要 `a` 是 `false`，不管 `b` 是什麼，結果都是 `false`。
- `a || b`：只要 `a` 是 `true`，不管 `b` 是什麼，結果都是 `true`。

既然答案已經確定，Go 就不會去算右邊。這叫做**短路求值**。我們用函式來觀察右邊有沒有被執行：

```go
package main

import "fmt"

func check(name string, result bool) bool {
	fmt.Println("檢查", name)
	return result
}

func main() {
	fmt.Println("--- && ---")
	if check("A", false) && check("B", true) {
		fmt.Println("都成立")
	}

	fmt.Println("--- || ---")
	if check("C", true) || check("D", true) {
		fmt.Println("至少一個成立")
	}
}
```

執行結果：

```text
--- && ---
檢查 A
--- || ---
檢查 C
至少一個成立
```

`B` 和 `D` 都沒有被印出來，因為左邊已經決定了答案，右邊的 `check` 根本沒被呼叫。

### 實用例子：先確認不是 `nil`

短路求值最常見的用途，是「先確認安全，再去存取」。對 `nil` 指標存取欄位會 `panic`，所以要先檢查：

```go
package main

import "fmt"

type User struct {
	Name  string
	Admin bool
}

func canDelete(u *User) bool {
	return u != nil && u.Admin
}

func main() {
	var nobody *User
	alice := &User{Name: "Alice", Admin: true}

	fmt.Println(canDelete(nobody))
	fmt.Println(canDelete(alice))
}
```

執行結果：

```text
false
true
```

當 `u` 是 `nil` 時，`u != nil` 是 `false`，右邊的 `u.Admin` 不會執行，所以不會 `panic`。如果把兩邊順序反過來寫成 `u.Admin && u != nil`，就會先存取 `nil` 指標的欄位，程式直接當掉。**順序很重要**。

同樣的模式也常用在切片：

```go
package main

import "fmt"

func main() {
	var names []string
	if len(names) > 0 && names[0] == "Andy" {
		fmt.Println("第一個是 Andy")
	} else {
		fmt.Println("沒有找到")
	}
}
```

執行結果：

```text
沒有找到
```

`names` 是空的，`len(names) > 0` 為 `false`，`names[0]` 就不會被讀取，避免了索引超出範圍的 `panic`。

`||` 也能這樣用，例如 `u == nil || u.Name == ""`：`u` 是 `nil` 時直接得到 `true`，不會去碰 `u.Name`。

## 重點整理

- `a && b`：`a` 為 `false` 時不會執行 `b`。
- `a || b`：`a` 為 `true` 時不會執行 `b`。
- 把「安全檢查」放左邊、「存取」放右邊，例如 `u != nil && u.Admin`、`len(s) > 0 && s[0] == x`。
- 左右順序會影響程式會不會 `panic`，不能隨意交換。
