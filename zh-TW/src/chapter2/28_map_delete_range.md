# `delete` 與走訪 map

## 本集目標

用 `delete` 從 map 刪掉一筆資料，並用 `for range` 走訪 map，同時認識「map 沒有順序」這件事。

## 正文

### `delete`

```go
package main

import "fmt"

func main() {
	scores := map[string]int{"小明": 90, "小華": 75, "小美": 88}
	delete(scores, "小華")
	fmt.Println(scores, len(scores))

	delete(scores, "阿強")
	fmt.Println(scores, len(scores))
}
```

執行結果：

```text
map[小明:90 小美:88] 2
map[小明:90 小美:88] 2
```

`delete(map, 鍵)` 把那個鍵和它的值一起刪掉。刪除一個不存在的鍵（例如「阿強」）不會出錯，什麼事都不會發生。`delete` 跟 `len`、`append` 一樣是內建函式，不用 `import`。

### 用 `for range` 走訪

```go
package main

import "fmt"

func main() {
	prices := map[string]int{"蘋果": 30, "香蕉": 15, "芭樂": 25}
	total := 0
	for _, price := range prices {
		total += price
	}
	fmt.Println("全部各買一個：", total, "元")
}
```

執行結果：

```text
全部各買一個： 70 元
```

`for k, v := range m` 每一圈拿到一組鍵和值，跟走訪切片很像，只是索引換成了鍵。這裡只要值，所以寫 `for _, price := range prices`；只要鍵的話寫 `for k := range m`。

如果在迴圈裡用 `fmt.Println(name, price)` 把每一組印出來，你會發現**每次執行的順序都可能不一樣**：這次蘋果先出來，下次可能換成香蕉。所以這裡不貼那種輸出。不過加總跟順序無關，永遠是 70。

### map 沒有順序

map 是為了「用鍵快速找到值」設計的，它不記錄資料放進去的先後，也不會幫你排序。Go 甚至**故意**讓每次走訪的順序隨機，提醒大家不要依賴順序。

所以用 map 時要記住：

- 走訪 map 適合做「跟順序無關」的事，例如加總、計數、找最大值。
- 如果真的需要照順序輸出，要先把鍵取出來排序，再照排好的順序查值。排序的方法之後會學到。

（第 25 集說過，`fmt.Println` 印整個 map 時會排序鍵，那是 `fmt` 為了好讀特別處理的，不代表 map 本身有順序。）

### 例子：數每個字出現幾次

map 很適合拿來「計數」。這裡把走訪的結果交給 `fmt.Println` 印出，輸出就是固定的：

```go
package main

import "fmt"

func main() {
	text := "香蕉蘋果香蕉"
	count := map[string]int{}
	for _, r := range text {
		count[string(r)]++
	}
	fmt.Println(count)
}
```

執行結果：

```text
map[果:1 蕉:2 蘋:1 香:2]
```

`count[string(r)]++` 能這樣寫，是因為查不到的鍵會得到 0：第一次遇到「香」時，`count["香"]` 是 0，加 1 變成 1；第二次再加 1 變成 2。不需要先檢查鍵存不存在。

## 重點整理

- `delete(m, k)` 刪除鍵 `k`；鍵不存在也不會出錯。
- `for k, v := range m` 走訪 map 的每一組鍵和值。
- map 沒有順序，每次走訪的順序都可能不同，不要寫依賴順序的程式。
- 利用「查不到得到零值」，`m[k]++` 可以直接拿來計數。
