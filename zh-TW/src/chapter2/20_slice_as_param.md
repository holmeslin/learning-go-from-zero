# 切片作為參數

## 本集目標

搞懂把切片傳進函式時，哪些修改呼叫端看得到、哪些看不到。

## 正文

第 7 集說過，傳進函式的參數是**複本**。那切片傳進去，複製的是什麼？

答案是：複製的是那扇「窗戶」，也就是切片記住的三件事（指向底層陣列的位置、長度、容量）。我們把這三件事合稱為切片的 **header**。底層陣列本身**不會**被複製。

所以函式裡的切片和呼叫端的切片，是兩扇不同的窗戶，但看著同一個底層陣列。

### 改元素：看得到

```go
package main

import "fmt"

func double(nums []int) {
	for i := range nums {
		nums[i] *= 2
	}
}

func main() {
	scores := []int{1, 2, 3}
	double(scores)
	fmt.Println(scores)
}
```

執行結果：

```text
[2 4 6]
```

`nums[i] *= 2` 改的是底層陣列裡的元素，而 `scores` 也看著同一個底層陣列，所以 `main` 看得到變化。這跟第 7 集傳 `int` 的情況不一樣，但道理相同：被複製的是 header，不是元素。

### `append`：不一定看得到

```go
package main

import "fmt"

func addItem(nums []int) {
	nums = append(nums, 100)
	nums[0] = -1
	fmt.Println("函式裡：", nums)
}

func main() {
	scores := []int{1, 2, 3}
	addItem(scores)
	fmt.Println("main 裡：", scores)
}
```

執行結果：

```text
函式裡： [-1 2 3 100]
main 裡： [1 2 3]
```

`scores` 的長度和容量都是 3。在函式裡 `append` 時容量不夠，於是配置了新陣列，`nums` 這扇窗戶就改看新陣列了。之後的 `nums[0] = -1` 改的也是新陣列。而 `main` 的 `scores` 是另一份 header，它完全不知道這件事，長度也還是 3。

就算容量夠、沒有換新陣列，`main` 的 `scores` 長度也不會變，所以還是看不到新加的元素。總之：**在函式裡 `append`，呼叫端的切片不會自己變長。**

### 想讓呼叫端拿到新切片：回傳它

解法跟 `append` 本身一樣：把新的切片**回傳**，讓呼叫端接回來。

```go
package main

import "fmt"

func addItem(nums []int, item int) []int {
	return append(nums, item)
}

func main() {
	var scores []int
	scores = addItem(scores, 90)
	scores = addItem(scores, 85)
	fmt.Println(scores)
}
```

執行結果：

```text
[90 85]
```

這就是 `s = append(s, ...)` 的同一個模式。

## 重點整理

- 切片傳進函式時，複製的是 header（指向底層陣列的位置、長度、容量），不是元素。
- 在函式裡修改元素，呼叫端看得到，因為兩邊共用底層陣列。
- 在函式裡 `append`，呼叫端的切片不會變長；容量不夠時甚至會換到新陣列，連元素修改都看不到。
- 要讓呼叫端拿到 `append` 後的結果，就把新切片回傳，由呼叫端接回來。
