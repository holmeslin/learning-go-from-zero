# 複合賦值與 `++` `--`

## 本集目標

用 `+=`、`-=` 等簡寫來修改變數，並用 `++`、`--` 加一減一。

## 正文

上一集我們寫過 `money = money - 30`。這種「拿變數自己來算，再放回去」的寫法非常常見，所以 Go 提供了簡寫。

### 複合賦值

```go
package main

import "fmt"

func main() {
	money := 100
	money -= 30
	fmt.Println(money)
	money += 50
	fmt.Println(money)
	money *= 2
	fmt.Println(money)
}
```

執行結果：

```text
70
120
240
```

`money -= 30` 就等於 `money = money - 30`。五個算術運算子都有對應的簡寫：

| 簡寫 | 等於 |
| --- | --- |
| `x += 3` | `x = x + 3` |
| `x -= 3` | `x = x - 3` |
| `x *= 3` | `x = x * 3` |
| `x /= 3` | `x = x / 3` |
| `x %= 3` | `x = x % 3` |

### `++` 和 `--`

加 1 和減 1 更常用，所以有更短的寫法：

```go
package main

import "fmt"

func main() {
	count := 0
	count++
	count++
	fmt.Println(count)
	count--
	fmt.Println(count)
}
```

執行結果：

```text
2
1
```

`count++` 就是 `count += 1`，`count--` 就是 `count -= 1`。等到學迴圈時，你會常常看到 `++`。

### `++`、`--` 是獨立敘述

在 Go 裡，`count++`、`count--` 是**獨立敘述**：會修改變數，但不會產生值，所以不能放進需要值的地方，例如 `fmt.Println(...)` 裡面：

```go,compile_fail
package main

import "fmt"

func main() {
	count := 0
	fmt.Println(count++)
}
```

編譯錯誤：

```text
./main.go:7:19: syntax error: unexpected ++ in argument list; possibly missing comma or )
```

目前先習慣各寫一行，但不是規定它們必須獨占一行；第 20 集會把 `i++` 放在三段式 `for` 的更新那一段。

如果你看過其他程式語言有 `++count` 這種寫法，Go 也沒有，只有放在變數後面的 `count++`。

## 重點整理

- `x += 3` 是 `x = x + 3` 的簡寫，`-=`、`*=`、`/=`、`%=` 也一樣。
- `x++` 讓 `x` 加 1，`x--` 讓 `x` 減 1。
- `x++`、`x--` 是獨立敘述，不會產生值，不能放進需要值的式子裡。
