# EXERCISES.md — 練習題規則與固定題庫

這份文件給 AI 助教使用，說明什麼時候可以出題、怎麼出、怎麼批改，並收錄第 1、2 章的固定題目。

本文件裡的題目分成兩種，請不要混在一起：

- **固定題**：寫在本文件「第 1 章」「第 2 章」底下、狀態為 `可用` 的題目。
- **臨時題**：本文件沒有合適的固定題時，AI 依下方規則當場設計的題目。

臨時題只能在下方規則允許時出。固定題是用來對齊程度的，不是讓你延伸出一整套更難、更長、更像一般 Go 課程的題目。

## 出題原則

1. 出題前一定要知道讀者讀到第幾章第幾集（問法見 `GUIDE.md` 第 2 節）。
2. 先在本文件找讀者目前進度以內、離他最近的那一集條目，看它的狀態。
3. 狀態是 `可用`：從「題目」中挑**一題**給讀者。同一條目列了好幾題時，它們是彼此替代的選項，不是要一次做完的題組。
4. 狀態是 `不出題`：用一句話轉述條目裡的原因，再推薦往前最近的 `可用` 條目，或建議讀者繼續往下讀。
5. 找不到合適的固定題，或讀者明確想要超前的挑戰，照「各章出題策略」決定能不能出臨時題。臨時題一定要說明它是臨時題，不能冒充本文件的題目。
6. 臨時題裡讀者需要理解或自己寫的部分，都要在目前進度以內。讀者只是說「想要難一點」「想挑戰」，不代表同意用還沒學的東西。
7. 固定句型的定義與可以改動的範圍，以 `GUIDE.md` 第 4.2 節為準。不要把固定句型背後的原理當成練習目標，例如不要要求第 1 章的讀者解釋 `scanner.Scan()` 是什麼。
8. 題目好像非用到還沒教的語法不可時，先想辦法改題目。真的改不掉，就把那段程式碼獨立放在一個區塊，標題寫「先照抄的部分（之後才會教，請不要修改）」，用一句話說明它的作用，然後清楚告訴讀者他只需要寫哪一段。
9. 只有讀者明確要求超前時，題目的解法才可以依賴還沒教的內容；而且只能用到最少的一點、要標示出來，題目也要維持小規模。

## 各章出題策略

**第 1、2 章**有固定題庫。讀者想針對某一集練習、但那集是 `不出題`，而讀者聽完原因仍然想練，可以臨時出一題，題目前先說：

> 我來出一題給你，不過先說明：題庫裡沒有對應這一集的題目，所以這題是我臨時想的，難度照你目前讀到的範圍。

第 1、2 章的臨時題要小、要完整，一題只練一兩個重點，不要做成綜合大題。

**第 3 章以後**（包括第 3～8 章、附錄一、第二部與附錄二）沒有固定題庫。這幾章多半在講資料怎麼建模、程式怎麼組織、工具怎麼用，硬寫固定題很容易變成「把範例重抄一遍」或「解釋名詞」。讀者想練習、知道沒有固定題後仍然想要，可以臨時出一題，題目前先說：

> 書從第 3 章起就不附固定題了，所以這題由我依你讀到的地方現場設計，會稍微綜合一點。

第 3 章以後的臨時題可以把讀者學過的幾個概念組合起來，稍微有綜合性，但仍以一支 `main.go` 寫得完為限（第 8 章第 2 集以後才可以要求多個檔案或套件）。

讀者**明確要求**超出目前進度的挑戰時，不論在哪一章，都可以臨時出一題，題目前先說：

> 照你的要求，這題會借用少量還沒讀到的內容；用到的地方我都會註明出處，現在看不懂原理也沒關係。

## 固定題庫使用規則

1. 一開始只給讀者看選中的那一題，加上作答需要的材料（起始程式、執行範例）。「批改重點」「提示方向」「參考答案」先不要拿出來。
2. 讀者交答案後，用該題的「批改重點」檢查他有沒有練到該練的東西。
3. 讀者卡住時，照「提示方向」的順序一次給一層，不要一口氣全部說完。
4. 讀者主動要答案，或試過幾次仍然卡住，才給「參考答案」。條目有多題時，參考答案依題號排列，只給讀者做的那一題。
5. 參考答案只是其中一種寫法。讀者的程式只要正確完成題目、沒有用到進度外的東西，就算對。
6. 執行範例中，`fmt.Println` 在多個值之間會自動加一個空格；讀者的輸出空格跟範例不完全一樣，不算錯。
7. 固定題都是要寫程式的題目；不放「確認有沒有安裝成功」或「解釋這個名詞」這類題目。
8. 參考答案都是完整的 `package main`，已在 Go 1.27 實際編譯執行過。讀輸入的題目要用 `go run .` 執行後在終端機打字輸入。

## 題目條目格式

``````md
### 第 X 章第 Y 集：集名

狀態：可用 / 不出題

不出題原因：
- 只有狀態是 `不出題` 時才寫。

練習目標：
- 這集要確認讀者會的事。

題目：
1. 第一個選項。
2. 第二個選項（可省略）。

執行範例：
（讀者可以看的輸出範例、起始程式；沒有可省略）

批改重點：
- 批改時要看的地方。

提示方向：
1. 第一層提示。
2. 第二層提示。

參考答案：
（每一題一個完整的 Go 程式）
``````

## 第 1 章

### 第 1 章第 1 集：安裝 Go

狀態：不出題

不出題原因：
- 這集只是把 Go 裝好、用 `go version` 確認版本，沒有程式可寫。
- 讀者裝不起來、終端機說找不到 `go` 時，直接幫他排除問題就好。

### 第 1 章第 2 集：第一個程式

狀態：不出題

不出題原因：
- 這集的重點是 `go mod init`、`main.go`、`go run .` 這套流程，以及照抄程式骨架；能把書上的程式跑起來就達成目標。
- 這時候出題只會變成「再印一行字」，練不到東西。建議讀者確認程式跑得起來後，讀到第 3 集再練。

### 第 1 章第 3 集：變數與輸出

狀態：可用

練習目標：
- 會用 `:=` 建立變數。
- 會把變數交給 `fmt.Println` 印出來，並知道多個值用逗號隔開。

題目：
1. 建立兩個變數：`drink` 存飲料名稱（文字），`price` 存價格（數字）。用兩行 `fmt.Println` 分別印出飲料名稱和價格。

執行範例：

```text
飲料： 珍珠奶茶
價格： 60
```

批改重點：
- 兩個值都要先存進變數，再把變數交給 `fmt.Println`，不能直接把內容寫死在字串裡。
- 文字要用雙引號，數字不用。
- `fmt.Println` 會在逗號隔開的值之間自動加空格，所以冒號後面多一個空格是正常的。

提示方向：
1. `drink := "珍珠奶茶"` 會建立一個存文字的變數。
2. `fmt.Println("價格：", price)` 會先印出引號裡的文字，再印出變數的值。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	drink := "珍珠奶茶"
	price := 60
	fmt.Println("飲料：", drink)
	fmt.Println("價格：", price)
}
```

### 第 1 章第 4 集：註解

狀態：可用

練習目標：
- 知道註解不會被執行。
- 會用 `//` 寫說明，也會用 `//` 暫時停用一行程式碼。

題目：
1. 下面的程式會印出三行。請不要刪掉任何一行，只用註解讓程式只印出第一行和第三行，並在最上面加一行註解說明這支程式在做什麼。

起始程式：

```go
package main

import "fmt"

func main() {
	fmt.Println("早安")
	fmt.Println("午安")
	fmt.Println("晚安")
}
```

批改重點：
- 要在 `fmt.Println("午安")` 前面加 `//`，不是把它刪掉。
- 說明用的註解寫在哪一行都可以，只要是 `//` 開頭。
- 用 `/* */` 也能達到效果，但這題主要是練 `//`。

提示方向：
1. 一行開頭加上 `//`，那一行就不會被執行。
2. 註解可以單獨佔一行，放在 `func main() {` 的下一行就好。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	// 這支程式會跟你打招呼
	fmt.Println("早安")
	// fmt.Println("午安")
	fmt.Println("晚安")
}
```

### 第 1 章第 5 集：算術運算子

狀態：可用

練習目標：
- 會用 `/` 做整數除法、用 `%` 算餘數。
- 會把計算結果直接交給 `fmt.Println`。

題目：
1. 有 23 顆糖果要平分給 4 個小朋友。建立變數 `candies` 和 `kids`，印出每人分到幾顆、還剩下幾顆。
2. 一部影片長 135 分鐘。建立變數 `minutes`，印出它是幾小時又幾分鐘。

執行範例：

題 1：

```text
每人分到 5 顆
剩下 3 顆
```

題 2：

```text
2 小時 15 分鐘
```

批改重點：
- 數字要先存進變數，計算時用變數，不要直接寫答案。
- 每人分到幾個用 `/`，剩幾個用 `%`。
- 讀者若問為什麼 `23 / 4` 是 `5`：兩個整數相除，小數部分會被丟掉。

提示方向：
1. 「平分」就是除法，「剩下」就是除完的餘數。
2. 1 小時是 60 分鐘，所以小時數是 `minutes / 60`。
3. 剩下的分鐘數是 `minutes % 60`。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	candies := 23
	kids := 4
	fmt.Println("每人分到", candies/kids, "顆")
	fmt.Println("剩下", candies%kids, "顆")
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	minutes := 135
	fmt.Println(minutes/60, "小時", minutes%60, "分鐘")
}
```

### 第 1 章第 6 集：運算子優先順序

狀態：可用

練習目標：
- 知道先乘除後加減。
- 會用小括號改變計算順序。

題目：
1. 下面的程式想算出三次小考的平均分數，正確答案應該是 `80`，但它印出了 `193`。請找出原因並修正。

起始程式：

```go
package main

import "fmt"

func main() {
	quiz1 := 70
	quiz2 := 100
	quiz3 := 70
	fmt.Println("平均：", quiz1+quiz2+quiz3/3)
}
```

批改重點：
- 原因：`/` 比 `+` 先算，所以只有 `quiz3` 被除以 3。
- 修正方式是加小括號：`(quiz1 + quiz2 + quiz3) / 3`。
- 讀者另外建一個變數存總分再除，也是正確的寫法。

提示方向：
1. 先在紙上照「先乘除後加減」的規則算一次 `70 + 100 + 70 / 3`。
2. 你希望先做的是加法，那要怎麼讓加法先算？

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	quiz1 := 70
	quiz2 := 100
	quiz3 := 70
	fmt.Println("平均：", (quiz1+quiz2+quiz3)/3)
}
```

### 第 1 章第 7 集：比較運算子

狀態：可用

練習目標：
- 會用比較運算子寫出條件，並知道結果是 `true` 或 `false`。
- 知道比較相等要用 `==`。

題目：
1. 建立變數 `height`（身高，公分）存 `125`。遊樂設施規定身高至少 120 公分才能搭。把「能不能搭」的比較結果存進變數 `canRide`，再印出來。接著再印出 `height` 是不是剛好等於 `120`。

執行範例：

```text
可以搭乘： true
剛好 120 公分： false
```

批改重點：
- 「至少 120」要用 `>=`，不是 `>`。
- 比較相等要用兩個等號 `==`。
- 比較結果可以先存進變數，也可以直接放進 `fmt.Println`，兩種都算對；題目要求的 `canRide` 要有存下來。

提示方向：
1. `height >= 120` 本身就是一個值，算出來是 `true` 或 `false`。
2. `canRide := height >= 120` 會把這個結果存起來。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	height := 125
	canRide := height >= 120
	fmt.Println("可以搭乘：", canRide)
	fmt.Println("剛好 120 公分：", height == 120)
}
```

### 第 1 章第 8 集：`if`

狀態：可用

練習目標：
- 會用 `if` 讓程式只在條件成立時執行某段程式碼。
- 知道 `if` 後面的程式碼不管條件如何都會執行。

題目：
1. 建立變數 `battery` 代表手機剩餘電量（0～100）。電量低於 20 時印出 `電量不足，請充電`。不管電量多少，最後都要印出 `目前電量：`加上電量。分別用 `15` 和 `80` 試試看。

執行範例：

`battery` 是 `15` 時：

```text
電量不足，請充電
目前電量： 15
```

`battery` 是 `80` 時：

```text
目前電量： 80
```

批改重點：
- 條件要寫 `battery < 20`。
- 「目前電量」那行要寫在 `if` 的大括號外面。
- 條件不用加小括號，`{` 要跟 `if` 同一行。
- 這集還沒教 `else`，不需要處理「電量充足」的訊息。

提示方向：
1. 只在某些情況才要做的事，放進 `if` 的大括號裡。
2. 每次都要做的事，放在 `if` 結束之後。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	battery := 15
	if battery < 20 {
		fmt.Println("電量不足，請充電")
	}
	fmt.Println("目前電量：", battery)
}
```

### 第 1 章第 9 集：作用域

狀態：可用

練習目標：
- 知道在大括號裡建立的變數，出了大括號就不能用。
- 看得懂 `undefined` 編譯錯誤，並會修正。

題目：
1. 下面的程式無法編譯。請先執行看看錯誤訊息，說說看為什麼會錯，再修改成可以編譯、而且分數及格時會印出 `恭喜及格`。

起始程式（這段故意不能編譯）：

```go,compile_fail
package main

import "fmt"

func main() {
	score := 75
	if score >= 60 {
		message := "恭喜及格"
	}
	fmt.Println(message)
}
```

批改重點：
- 讀者要能說出：`message` 是在 `if` 的大括號裡建立的，出了大括號就不存在了。
- 以目前進度，最直接的修法是把 `fmt.Println(message)` 移進 `if` 的大括號裡。
- 改成直接 `fmt.Println("恭喜及格")` 也能跑，但沒有練到作用域；可以鼓勵讀者保留 `message` 變數。
- 這集還沒教 `var` 與重新賦值，不要引導讀者把變數移到外面再賦值。

提示方向：
1. 錯誤訊息裡的 `undefined: message` 是說「這裡找不到 `message`」。
2. `message` 是在哪一對大括號裡建立的？`fmt.Println(message)` 在那對大括號裡面嗎？

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	score := 75
	if score >= 60 {
		message := "恭喜及格"
		fmt.Println(message)
	}
}
```

### 第 1 章第 10 集：`else`

狀態：可用

練習目標：
- 會用 `if` / `else` 讓程式在兩種情況中選一種執行。
- 複習用 `%` 判斷整除。

題目：
1. 建立變數 `number`，判斷它是偶數還是奇數，印出 `number` 加上 `是偶數` 或 `是奇數`。用 `8` 和 `13` 各試一次。

執行範例：

`number` 是 `13` 時：

```text
13 是奇數
```

批改重點：
- 判斷偶數可以用 `number%2 == 0`。
- 兩種情況分別放在 `if` 和 `else` 的大括號裡。
- `else` 要寫在右大括號同一行：`} else {`。

提示方向：
1. 偶數除以 2 的餘數是多少？
2. 不是偶數的情況就交給 `else`。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	number := 13
	if number%2 == 0 {
		fmt.Println(number, "是偶數")
	} else {
		fmt.Println(number, "是奇數")
	}
}
```

### 第 1 章第 11 集：`else if`

狀態：可用

練習目標：
- 會用 `else if` 處理三種以上的情況。
- 知道條件從上往下檢查，順序會影響結果。

題目：
1. 建立變數 `speed` 代表車速。依照車速印出：
    - 超過 110：`超速，罰款！`
    - 100 到 110（含）：`接近速限，請放慢`
    - 其他：`速度正常`

   用 `120`、`105`、`90` 各試一次。

執行範例：

`speed` 是 `105` 時：

```text
接近速限，請放慢
```

批改重點：
- 最嚴格的條件（超過 110）要放最前面。
- 第二個條件寫 `speed >= 100` 就夠了，因為走到這裡代表一定沒有超過 110。
- 讀者若寫成 `speed >= 100 && speed <= 110`，邏輯也對，但 `&&` 是下一集才教的；可以告訴他不需要。
- 「其他」用 `else` 處理。

提示方向：
1. 先檢查最快的情況。
2. 能走到第二個條件時，車速一定是多少以下？

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	speed := 105
	if speed > 110 {
		fmt.Println("超速，罰款！")
	} else if speed >= 100 {
		fmt.Println("接近速限，請放慢")
	} else {
		fmt.Println("速度正常")
	}
}
```

### 第 1 章第 12 集：邏輯運算子

狀態：可用

練習目標：
- 會用 `&&`、`||` 組合兩個條件。
- 會用 `&&` 檢查數字是否在某個範圍內。

題目：
1. 博物館門票規則：未滿 12 歲或 65 歲以上買優待票，其他人買全票。建立變數 `age`，印出 `優待票` 或 `全票`。
2. 建立變數 `month`，如果它在 1 到 12 之間，印出 `月份正確`，否則印出 `沒有這個月份`。

執行範例：

題 1，`age` 是 `70` 時：

```text
優待票
```

題 2，`month` 是 `13` 時：

```text
沒有這個月份
```

批改重點：
- 題 1 要用 `||`：`age < 12 || age >= 65`。
- 題 2 要用 `&&`：`month >= 1 && month <= 12`；不能寫成 `1 <= month <= 12`。
- 邊界要對：12 歲是全票、65 歲是優待票；1 和 12 都是正確月份。

提示方向：
1. 「或」用 `||`，「而且」用 `&&`。
2. 「在 1 到 12 之間」要拆成兩個比較：大於等於 1，而且小於等於 12。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	age := 70
	if age < 12 || age >= 65 {
		fmt.Println("優待票")
	} else {
		fmt.Println("全票")
	}
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	month := 13
	if month >= 1 && month <= 12 {
		fmt.Println("月份正確")
	} else {
		fmt.Println("沒有這個月份")
	}
}
```

### 第 1 章第 13 集：重新賦值與 `var`

狀態：可用

練習目標：
- 會用 `=` 改變已經存在的變數。
- 會用 `var` 建立變數，並知道沒給值時會從 0 開始。

題目：
1. 用 `var balance int` 建立存款變數。依序存入 500 元、領出 120 元、再存入 300 元，每做一次就印出目前的存款。

執行範例：

```text
存款： 500
存款： 380
存款： 680
```

批改重點：
- `balance` 只用 `var` 建立一次，之後都用 `=` 修改，不能再用 `:=`。
- 寫法要像 `balance = balance + 500`：先算右邊，再放回左邊。
- 這集還沒教 `+=`，讀者用了也不算錯，但可以告訴他下一集會正式介紹。

提示方向：
1. `var balance int` 建立後，`balance` 一開始是 0。
2. 存入 500 就是「新的存款 = 舊的存款 + 500」。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	var balance int
	balance = balance + 500
	fmt.Println("存款：", balance)
	balance = balance - 120
	fmt.Println("存款：", balance)
	balance = balance + 300
	fmt.Println("存款：", balance)
}
```

### 第 1 章第 14 集：複合賦值與 `++` `--`

狀態：可用

練習目標：
- 會用 `+=`、`-=`、`*=` 簡化重新賦值。
- 會用 `++`、`--` 讓變數加一或減一。

題目：
1. 停車場一開始有 `cars := 0` 輛車。依序發生：進來 1 輛、進來 1 輛、出去 1 輛、一次進來 5 輛。用 `++`、`--`、`+=` 更新 `cars`，最後印出場內車輛數。
2. 一筆存款 `money := 1000`，每年變成兩倍，連續 3 年。用 `*=` 更新，每年印出一次金額。

執行範例：

題 1：

```text
場內車輛： 6
```

題 2：

```text
第 1 年： 2000
第 2 年： 4000
第 3 年： 8000
```

批改重點：
- 題 1：一次加減 1 用 `++`、`--`；一次加 5 用 `+=`。
- 題 2：用 `money *= 2`。這集還沒教迴圈，連寫三次是正常的。
- `cars++` 要自己獨立一行，不能寫在 `fmt.Println` 裡面。

提示方向：
1. `cars++` 等於 `cars = cars + 1`。
2. `money *= 2` 等於 `money = money * 2`。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	cars := 0
	cars++
	cars++
	cars--
	cars += 5
	fmt.Println("場內車輛：", cars)
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	money := 1000
	money *= 2
	fmt.Println("第 1 年：", money)
	money *= 2
	fmt.Println("第 2 年：", money)
	money *= 2
	fmt.Println("第 3 年：", money)
}
```

### 第 1 章第 15 集：讀取輸入

狀態：可用

練習目標：
- 會照抄讀一行輸入的固定句型。
- 會在同一支程式裡讀兩行輸入。

題目：
1. 先請使用者輸入名字，再請他輸入喜歡的食物，最後印出一句話把兩個答案組合起來。

執行範例（依序輸入 `小美`、`牛肉麵`）：

```text
你叫什麼名字？
你最喜歡吃什麼？
小美 最喜歡吃 牛肉麵
```

批改重點：
- `scanner := bufio.NewScanner(os.Stdin)` 只寫一次；每讀一行就寫一次 `scanner.Scan()` 和 `變數 := scanner.Text()`。
- 兩個 `scanner.Text()` 要存進不同名字的變數。
- `import` 要有 `bufio`、`fmt`、`os`，用小括號並照字母排序。
- 不要求讀者解釋 `scanner` 的原理，那是第 3、4 章的內容。

提示方向：
1. 先把書上讀一行的三行程式碼照抄過來。
2. 要讀第二行時，不用再建立一次 `scanner`，只要再寫一次 `scanner.Scan()` 和 `scanner.Text()`。

參考答案：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("你叫什麼名字？")
	scanner.Scan()
	name := scanner.Text()
	fmt.Println("你最喜歡吃什麼？")
	scanner.Scan()
	food := scanner.Text()
	fmt.Println(name, "最喜歡吃", food)
}
```

### 第 1 章第 16 集：`strconv.Atoi` 與 `err`

狀態：可用

練習目標：
- 會用 `strconv.Atoi` 把輸入轉成整數。
- 每次轉換後都會檢查 `err`，輸入錯誤時印出提示並結束。

題目：
1. 請使用者輸入今年幾歲，印出他 10 年後幾歲。輸入的不是整數時，印出 `請輸入整數`。

執行範例：

輸入 `25` 時：

```text
請輸入你的年齡：
10 年後你 35 歲
```

輸入 `abc` 時：

```text
請輸入你的年齡：
請輸入整數
```

批改重點：
- 轉換寫成 `age, err := strconv.Atoi(line)`，`import` 要加 `"strconv"`。
- 轉換後要立刻接 `if err != nil { ...; return }`。
- 計算要用轉換後的整數，不能拿 `line` 直接加 10。
- 不要求讀者解釋 `err` 是什麼型別，第 5 章才會講。

提示方向：
1. `scanner.Text()` 拿到的是文字，要先用 `strconv.Atoi` 變成整數才能計算。
2. 轉換失敗時 `err` 不是 `nil`，這時印出提示後用 `return` 結束。

參考答案：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入你的年齡：")
	scanner.Scan()
	line := scanner.Text()
	age, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}
	fmt.Println("10 年後你", age+10, "歲")
}
```

### 第 1 章第 17 集：綜合練習

狀態：可用

練習目標：
- 能把題目拆成「讀輸入、轉換、檢查、判斷、輸出」幾個步驟。
- 能處理錯誤輸入、不合理的值與邊界值。

題目：
1. 停車費計算：請使用者輸入停車幾小時（整數）。
    - 輸入不是整數：印出 `請輸入整數`。
    - 小於等於 0：印出 `時數要大於 0`。
    - 2 小時以內（含）：每小時 30 元。
    - 超過 2 小時：前 2 小時共 60 元，之後每小時 50 元。

   印出應付金額。

執行範例：

輸入 `5` 時：

```text
請輸入停車時數：
停車費： 210 元
```

輸入 `0` 時：

```text
請輸入停車時數：
時數要大於 0
```

批改重點：
- 先檢查 `err`，再檢查小於等於 0，最後才算錢。
- 超過 2 小時的算法：`60 + (hours-2)*50`；要注意運算子優先順序。
- 邊界值：2 小時應該是 60 元，3 小時應該是 110 元。
- 讀者可以用 `if` / `else if` / `else`，也可以先 `return` 掉不合理的情況，兩種都對。

提示方向：
1. 先寫出讀輸入和轉換整數的部分，確認輸入 `abc` 會印出 `請輸入整數`。
2. 不合理的時數先擋掉。
3. 超過 2 小時的部分是 `hours - 2` 小時，每小時 50 元。

參考答案：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入停車時數：")
	scanner.Scan()
	line := scanner.Text()
	hours, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}

	if hours <= 0 {
		fmt.Println("時數要大於 0")
	} else if hours <= 2 {
		fmt.Println("停車費：", hours*30, "元")
	} else {
		fmt.Println("停車費：", 60+(hours-2)*50, "元")
	}
}
```

### 第 1 章第 18 集：`for` 無限迴圈 + `break`

狀態：可用

練習目標：
- 會寫 `for { ... }` 重複執行。
- 會在條件達成時用 `break` 離開迴圈。

題目：
1. 一張紙對折一次厚度變兩倍。從 `thickness := 1`（單位：張）開始，用 `for` 無限迴圈一直對折，每折一次就把次數加 1，厚度超過 1000 張時停下來，印出折了幾次、厚度是多少。
2. 請使用者輸入密碼，輸入錯誤就印出 `密碼錯誤，請再試一次` 並重新要求輸入，直到輸入 `gopher` 為止，最後印出 `登入成功`。

執行範例：

題 1：

```text
折了 10 次，厚度 1024 張
```

題 2（依序輸入 `1234`、`gopher`）：

```text
請輸入密碼：
密碼錯誤，請再試一次
請輸入密碼：
登入成功
```

批改重點：
- 迴圈寫成 `for { ... }`，在裡面用 `if` 加 `break` 結束。
- 題 1：檢查要在厚度更新之後；`times` 和 `thickness` 要在迴圈外建立，才能在迴圈後印出。
- 題 2：`scanner` 建立一次就好，放在迴圈外；`scanner.Scan()` 和 `scanner.Text()` 放在迴圈裡。
- 題 2：比較文字用 `==`，`"gopher"` 要加雙引號。

提示方向：
1. 迴圈裡每一圈要做的事是什麼？先寫出來，再想什麼時候該停。
2. 停下來的條件放在 `if` 裡，成立就 `break`。
3. 迴圈結束後要用到的變數，要在迴圈外面先建立。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	thickness := 1
	times := 0
	for {
		thickness *= 2
		times++
		if thickness > 1000 {
			break
		}
	}
	fmt.Println("折了", times, "次，厚度", thickness, "張")
}
```

題 2：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for {
		fmt.Println("請輸入密碼：")
		scanner.Scan()
		password := scanner.Text()
		if password == "gopher" {
			break
		}
		fmt.Println("密碼錯誤，請再試一次")
	}
	fmt.Println("登入成功")
}
```

### 第 1 章第 19 集：`for` 條件迴圈

狀態：可用

練習目標：
- 會寫 `for 條件 { ... }`。
- 會讓迴圈裡的變數改變，讓條件最後變成 `false`。

題目：
1. 每週存 150 元，存款從 0 開始。用 `for 條件` 迴圈算出要存幾週，存款才會達到 1000 元以上，印出週數和最後的存款。

執行範例：

```text
存了 7 週，共 1050 元
```

批改重點：
- 迴圈條件是「還沒存到 1000」：`savings < 1000`。
- 迴圈裡要同時更新存款和週數。
- 讀者若用 `for { ... break }` 也能做出來，但這集要練的是把條件寫在 `for` 後面。

提示方向：
1. 什麼情況下還要繼續存？把它寫在 `for` 後面。
2. 每一圈存一次錢，也要記錄週數加 1。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	savings := 0
	weeks := 0
	for savings < 1000 {
		savings += 150
		weeks++
	}
	fmt.Println("存了", weeks, "週，共", savings, "元")
}
```

### 第 1 章第 20 集：三段式 `for`

狀態：可用

練習目標：
- 會寫 `for 初始化; 條件; 更新 { ... }`。
- 會控制起點、終點和每次增加的量。

題目：
1. 用三段式 `for` 印出 7 的乘法表（`7 x 1 = 7` 到 `7 x 9 = 63`）。
2. 用三段式 `for` 印出倒數 `10`、`8`、`6`、`4`、`2`，最後印出 `發射！`。

執行範例：

題 1（前三行與最後一行）：

```text
7 x 1 = 7
7 x 2 = 14
7 x 3 = 21
...
7 x 9 = 63
```

題 2：

```text
10
8
6
4
2
發射！
```

批改重點：
- 題 1：`for i := 1; i <= 9; i++`，注意是 `<=`。
- 題 2：更新寫 `i -= 2`，條件寫 `i > 0` 或 `i >= 2`。
- `發射！` 要在迴圈外面印，只印一次。

提示方向：
1. 先想清楚：從幾開始？到幾結束？每次怎麼變？
2. 這三件事依序填進 `for` 的三段，用分號隔開。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	for i := 1; i <= 9; i++ {
		fmt.Println(7, "x", i, "=", 7*i)
	}
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	for i := 10; i > 0; i -= 2 {
		fmt.Println(i)
	}
	fmt.Println("發射！")
}
```

### 第 1 章第 21 集：`for range` 整數

狀態：可用

練習目標：
- 會用 `for i := range n` 跑固定次數。
- 知道 `i` 從 0 開始，用不到 `i` 時寫 `for range n`。

題目：
1. 用 `for range` 算出 1 加到 100 的總和。
2. 用 `for range 3` 印出三次 `加油！`，再印出 `出發`。

執行範例：

題 1：

```text
總和： 5050
```

題 2：

```text
加油！
加油！
加油！
出發
```

批改重點：
- 題 1：`for i := range 100` 的 `i` 是 0 到 99，所以要加 `i + 1`；寫成 `range 101` 加上 `i` 也對（多加一個 0 不影響）。
- 題 1：總和變數要在迴圈外建立。
- 題 2：用不到 `i`，所以寫 `for range 3`；寫 `for i := range 3` 會因為 `i` 沒用到而無法編譯。

提示方向：
1. 先印出 `i` 看看它是從幾跑到幾。
2. 總和可以用 `sum += ...` 一圈一圈累加。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	sum := 0
	for i := range 100 {
		sum += i + 1
	}
	fmt.Println("總和：", sum)
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	for range 3 {
		fmt.Println("加油！")
	}
	fmt.Println("出發")
}
```

### 第 1 章第 22 集：巢狀迴圈

狀態：可用

練習目標：
- 會在迴圈裡再放一個迴圈。
- 知道外層每跑一圈，內層會完整跑一輪。

題目：
1. 擲兩顆骰子（點數各是 1～6），列出所有點數加起來等於 7 的組合，最後印出共有幾種。

執行範例：

```text
1 + 6
2 + 5
3 + 4
4 + 3
5 + 2
6 + 1
共有 6 種
```

批改重點：
- 外層跑第一顆骰子，內層跑第二顆，兩層的計數變數名稱要不同。
- 判斷寫在內層迴圈裡：`if a+b == 7`。
- 計數變數要在兩層迴圈外面建立。
- 骰子從 1 開始，用三段式 `for a := 1; a <= 6; a++` 最直接；用 `range 6` 再加 1 也可以。

提示方向：
1. 先寫出印出全部 36 種組合的巢狀迴圈。
2. 再加上 `if`，只印出加起來是 7 的組合。
3. 印出來的同時，讓計數加 1。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	count := 0
	for a := 1; a <= 6; a++ {
		for b := 1; b <= 6; b++ {
			if a+b == 7 {
				fmt.Println(a, "+", b)
				count++
			}
		}
	}
	fmt.Println("共有", count, "種")
}
```

### 第 1 章第 23 集：`continue`

狀態：可用

練習目標：
- 會用 `continue` 跳過這一圈剩下的程式碼。
- 會用「先排除不要的」寫法讓迴圈更清楚。

題目：
1. 印出 1 到 20 之中，不是 3 的倍數、也不是 5 的倍數的數字。用 `continue` 跳過不要的數字。

執行範例：

```text
1
2
4
7
8
11
13
14
16
17
19
```

批改重點：
- 排除條件寫在迴圈開頭：`if i%3 == 0 || i%5 == 0 { continue }`。
- `fmt.Println(i)` 放在 `continue` 的後面。
- 讀者若用一個 `if` 把要印的情況包起來也能得到正確結果，但這題要練的是 `continue`。

提示方向：
1. 哪些數字是「不要的」？把它們的條件寫出來。
2. 遇到不要的數字就 `continue`，剩下的就印出來。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	for i := 1; i <= 20; i++ {
		if i%3 == 0 || i%5 == 0 {
			continue
		}
		fmt.Println(i)
	}
}
```

### 第 1 章第 24 集：型別（基礎）

狀態：不出題

不出題原因：
- 這集在認識 `int`、`float64`、`string`、`bool` 四種型別，以及 `:=` 會自動決定型別，屬於觀念說明。
- 硬出題會變成「這個變數是什麼型別」的問答。建議讀者繼續讀，第 27 集的型別轉換有題目可練。

### 第 1 章第 25 集：型別（數字詳解）

狀態：不出題

不出題原因：
- 這集介紹各種整數、浮點數型別與溢位，重點在知道它們存在、平常用 `int` 和 `float64` 就好。
- 適合的練習會變成背範圍或猜溢位結果，不是寫程式。可以推薦第 23 集或第 27 集的題目。

### 第 1 章第 26 集：零值

狀態：不出題

不出題原因：
- 這集的觀念是「沒給值的變數會有零值」，第 13 集已經用 `var` 練過從 0 開始累加。
- 再出題只會重複第 13 集，或變成問答。建議讀者回去做第 13 集的題目，或繼續讀。

### 第 1 章第 27 集：型別轉換

狀態：可用

練習目標：
- 知道不同數字型別不能直接一起算。
- 會用 `float64(...)` 讓整數相除得到小數，會用 `int(...)` 把小數轉回整數。

題目：
1. 一份披薩有 `pieces := 9` 片，`people := 2` 個人平分。印出每人分到幾片（要有小數）。
2. 商品原價 `price := 250`（整數），打八折。用 `float64(price) * 0.8` 算出折扣後的價格，再轉回整數印出來。

執行範例：

題 1：

```text
每人 4.5 片
```

題 2：

```text
折扣後 200 元
```

批改重點：
- 題 1：要先轉換再相除：`float64(pieces) / float64(people)`。寫成 `float64(pieces / people)` 會得到 `4`，因為整數相除先發生了。
- 題 2：`int(...)` 會直接砍掉小數，不是四捨五入；這題剛好整除。
- 原本的 `pieces`、`price` 還是整數，轉換不會改變原本的變數。

提示方向：
1. `9 / 2` 為什麼是 `4`？想得到 `4.5`，兩邊要先變成什麼型別？
2. 整數和 `float64` 不能直接相乘，`price` 要先轉成 `float64`。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	pieces := 9
	people := 2
	each := float64(pieces) / float64(people)
	fmt.Println("每人", each, "片")
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	price := 250
	discounted := float64(price) * 0.8
	fmt.Println("折扣後", int(discounted), "元")
}
```

### 第 1 章第 28 集：`byte` 與 `rune`

狀態：不出題

不出題原因：
- 這集只是先認識「字有號碼」以及單引號、雙引號的差別，實際處理一段文字裡的每個字要到第 2 章第 22、23 集。
- 現在出題只能印出某個字的號碼，練不到東西。建議讀者繼續讀，第 2 章第 23 集有對應的題目。

### 第 1 章第 29 集：跳脫字元與 raw string

狀態：可用

練習目標：
- 會在雙引號字串裡用 `\"`、`\\`、`\n`。
- 會用反引號寫 raw string，並知道裡面的反斜線不會被處理。

題目：
1. 用**一個** `fmt.Println` 印出下面兩行（第二行裡有雙引號和反斜線）。
2. 用 raw string 印出同樣的兩行。

執行範例：

```text
檔案位置：
"C:\Users\gopher\notes.txt"
```

批改重點：
- 題 1：換行用 `\n`，雙引號用 `\"`，每個反斜線都要寫成 `\\`。
- 題 2：raw string 用反引號包起來，可以直接跨行，反斜線和雙引號照原樣寫。
- 兩題都只用一個 `fmt.Println`。

提示方向：
1. 雙引號字串裡的 `\U` 會被當成跳脫字元的開頭，所以想印出反斜線本身要怎麼寫？
2. raw string 裡打什麼就印什麼，連換行也是。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	fmt.Println("檔案位置：\n\"C:\\Users\\gopher\\notes.txt\"")
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	fmt.Println(`檔案位置：
"C:\Users\gopher\notes.txt"`)
}
```

### 第 1 章第 30 集：`switch`

狀態：可用

練習目標：
- 會用 `switch 值` 比對多種情況，並用 `default` 處理其他情況。
- 會在一個 `case` 放好幾個值。

題目：
1. 建立變數 `day`（1 代表星期一，7 代表星期日）。1 到 5 印出 `上班日`，6、7 印出 `週末`，其他數字印出 `沒有這一天`。
2. 請使用者輸入月份（整數），用 `switch` 印出它是哪個季節：3～5 月春天、6～8 月夏天、9～11 月秋天、12、1、2 月冬天，其他印出 `沒有這個月份`。輸入不是整數時印出 `請輸入整數`。

執行範例：

題 1，`day` 是 `6` 時：

```text
週末
```

題 2，輸入 `12` 時：

```text
請輸入月份：
冬天
```

批改重點：
- 一個 `case` 用逗號列出好幾個值，例如 `case 6, 7:`。
- 不需要寫 `break`，執行完一個 `case` 就會結束。
- 其他情況用 `default`。
- 讀者若用不帶值的 `switch` 加上條件（例如 `case month >= 3 && month <= 5:`）也對。

提示方向：
1. `switch day {` 後面每個 `case` 寫要比對的值。
2. 好幾個值做同一件事，就用逗號把它們放在同一個 `case`。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	day := 6
	switch day {
	case 1, 2, 3, 4, 5:
		fmt.Println("上班日")
	case 6, 7:
		fmt.Println("週末")
	default:
		fmt.Println("沒有這一天")
	}
}
```

題 2：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入月份：")
	scanner.Scan()
	line := scanner.Text()
	month, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}

	switch month {
	case 3, 4, 5:
		fmt.Println("春天")
	case 6, 7, 8:
		fmt.Println("夏天")
	case 9, 10, 11:
		fmt.Println("秋天")
	case 12, 1, 2:
		fmt.Println("冬天")
	default:
		fmt.Println("沒有這個月份")
	}
}
```

## 第 2 章

### 第 2 章第 1 集：`const`

狀態：可用

練習目標：
- 會用 `const` 宣告不會變的值。
- 會用有意義的常數名稱取代程式裡的「神祕數字」。

題目：
1. 下面的程式算出三種飲料加上外送費的總價，但 `30` 這個數字到處都是，看不出它代表什麼。請宣告常數 `deliveryFee` 代表外送費，把程式改寫成使用常數；改完後輸出要和原本一樣。

起始程式：

```go
package main

import "fmt"

func main() {
	fmt.Println("紅茶：", 35+30)
	fmt.Println("咖啡：", 60+30)
	fmt.Println("果汁：", 50+30)
}
```

批改重點：
- 用 `const deliveryFee = 30` 宣告，寫在 `main` 裡面或外面都可以。
- 三個 `30` 都要換成 `deliveryFee`。
- 讀者若問「為什麼不用變數就好」：常數保證不會被改掉，名字也讓人一看就懂。

提示方向：
1. `const 名稱 = 值` 宣告常數，用法跟變數一樣。
2. 改完後試試看在程式裡寫 `deliveryFee = 40`，看看編譯器怎麼說。

參考答案：

```go,ignore
package main

import "fmt"

const deliveryFee = 30

func main() {
	fmt.Println("紅茶：", 35+deliveryFee)
	fmt.Println("咖啡：", 60+deliveryFee)
	fmt.Println("果汁：", 50+deliveryFee)
}
```

### 第 2 章第 2 集：`iota`

狀態：可用

練習目標：
- 會在 `const ( ... )` 裡用 `iota` 產生連續編號。
- 會用 `iota + 1` 讓編號從 1 開始。

題目：
1. 用 `iota` 宣告四個常數 `Spring`、`Summer`、`Autumn`、`Winter`，編號從 1 開始。再建立變數 `season := Autumn`，用 `switch` 印出它的中文名稱。

執行範例：

```text
Autumn 的編號： 3
秋天
```

批改重點：
- 只有第一行需要寫 `= iota + 1`，後面幾行會沿用。
- `switch` 的 `case` 用常數名稱比對，不要寫死數字。
- 讀者若用 `_ = iota` 跳過 0 也對。

提示方向：
1. 在 `const ( ... )` 裡，第一行寫 `Spring = iota + 1`，下面三行只寫名字。
2. `case Spring:` 跟 `case 1:` 意思一樣，但前者好讀很多。

參考答案：

```go,ignore
package main

import "fmt"

const (
	Spring = iota + 1
	Summer
	Autumn
	Winter
)

func main() {
	season := Autumn
	fmt.Println("Autumn 的編號：", season)
	switch season {
	case Spring:
		fmt.Println("春天")
	case Summer:
		fmt.Println("夏天")
	case Autumn:
		fmt.Println("秋天")
	case Winter:
		fmt.Println("冬天")
	}
}
```

### 第 2 章第 3 集：底線 `_`

狀態：不出題

不出題原因：
- `_` 的用法很單純：值一定要接但用不到時用它接。單獨出題只會變成「把某個變數換成 `_`」。
- 之後第 9 集多回傳值、第 14 集 `for _, v := range` 都會自然用到，建議到那些題目再練。

### 第 2 章第 4 集：多重賦值與交換

狀態：可用

練習目標：
- 會用 `a, b = b, a` 交換兩個變數。
- 知道多重賦值會先算完右邊，再一起放進左邊。

題目：
1. 費氏數列從 `0`、`1` 開始，之後每個數都是前兩個數的和。用 `a, b := 0, 1` 和多重賦值，印出前 10 個數。

執行範例：

```text
0
1
1
2
3
5
8
13
21
34
```

批改重點：
- 關鍵一行是 `a, b = b, a+b`，不需要暫存變數。
- 迴圈跑 10 次，每次先印 `a` 再更新。
- 讀者若用暫存變數也能做對，可以提示這集的寫法能省掉它。

提示方向：
1. 每往前走一步，新的 `a` 是舊的 `b`，新的 `b` 是舊的 `a + b`。
2. 多重賦值右邊用的都是「舊的值」，所以可以一行寫完。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	a, b := 0, 1
	for range 10 {
		fmt.Println(a)
		a, b = b, a+b
	}
}
```

### 第 2 章第 5 集：`fmt.Printf` 格式動詞

狀態：可用

練習目標：
- 會用 `%s`、`%d`、`%.2f` 把值放進格式字串。
- 知道 `Printf` 要自己加 `\n`。

題目：
1. 買了 3 杯咖啡，每杯 65 元，付了 200 元。用 `fmt.Printf` 印出下面的收據；平均每杯的價格要算成 `float64`，印到小數點後兩位。

執行範例：

```text
品項：咖啡
數量：3 杯
總價：195 元
找零：5 元
平均每杯：65.00 元
```

批改重點：
- 文字用 `%s`、整數用 `%d`、小數用 `%.2f`。
- 每一行結尾要有 `\n`。
- 平均要先轉成 `float64` 再除：`float64(total) / float64(count)`。
- 動詞的數量要和後面的值對上；不對時 `go vet` 會提醒。

提示方向：
1. `fmt.Printf("數量：%d 杯\n", count)` 會把 `count` 填進 `%d` 的位置。
2. `%.2f` 的 `.2` 代表小數點後兩位。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	item := "咖啡"
	count := 3
	price := 65
	paid := 200
	total := count * price

	fmt.Printf("品項：%s\n", item)
	fmt.Printf("數量：%d 杯\n", count)
	fmt.Printf("總價：%d 元\n", total)
	fmt.Printf("找零：%d 元\n", paid-total)
	fmt.Printf("平均每杯：%.2f 元\n", float64(total)/float64(count))
}
```

### 第 2 章第 6 集：簡單函式

狀態：可用

練習目標：
- 會用 `func 名字() { ... }` 定義函式。
- 會在 `main` 裡呼叫同一個函式好幾次。

題目：
1. 寫一個函式 `printLine`，印出一行 `----------`。在 `main` 裡呼叫它，讓輸出變成下面的樣子。

執行範例：

```text
----------
今日菜單
----------
滷肉飯
貢丸湯
----------
```

批改重點：
- `printLine` 寫在 `main` 外面。
- 分隔線出現三次，要呼叫三次 `printLine()`，不能在 `main` 裡直接印分隔線。
- 函式定義的位置在 `main` 前或後都可以。

提示方向：
1. 先寫 `func printLine() { ... }`，把印分隔線的那行放進去。
2. 呼叫函式要加小括號：`printLine()`。

參考答案：

```go,ignore
package main

import "fmt"

func printLine() {
	fmt.Println("----------")
}

func main() {
	printLine()
	fmt.Println("今日菜單")
	printLine()
	fmt.Println("滷肉飯")
	fmt.Println("貢丸湯")
	printLine()
}
```

### 第 2 章第 7 集：函式參數

狀態：可用

練習目標：
- 會定義有參數的函式，並在呼叫時傳入值。
- 會使用兩個不同型別的參數。

題目：
1. 寫一個函式 `cheer(name string, times int)`，印出 `times` 次 `加油，` 加上名字。在 `main` 裡分別替 `小明` 喊 2 次、替 `阿華` 喊 3 次。

執行範例：

```text
加油， 小明
加油， 小明
加油， 阿華
加油， 阿華
加油， 阿華
```

批改重點：
- 參數格式是 `名字 型別`，兩個參數用逗號隔開。
- 函式裡用 `for range times` 重複。
- 呼叫時參數順序要和定義一致：`cheer("小明", 2)`。

提示方向：
1. 參數就像函式裡的變數，值由呼叫的人決定。
2. 重複 `times` 次可以用第 1 章學過的 `for range`。

參考答案：

```go,ignore
package main

import "fmt"

func cheer(name string, times int) {
	for range times {
		fmt.Println("加油，", name)
	}
}

func main() {
	cheer("小明", 2)
	cheer("阿華", 3)
}
```

### 第 2 章第 8 集：函式回傳值

狀態：可用

練習目標：
- 會在函式寫回傳型別，用 `return` 把結果交回去。
- 會把回傳值存進變數或直接拿來用。

題目：
1. 寫一個函式 `ticketPrice(age int) int`：未滿 12 歲回傳 `150`，其他回傳 `300`。在 `main` 裡算出一家人（年齡 40、38、10、7）的票價總和並印出。
2. 寫一個函式 `isLeapYear(year int) bool`，判斷是不是閏年（能被 4 整除但不能被 100 整除，或能被 400 整除），印出 2024、1900、2000 的結果。

執行範例：

題 1：

```text
總票價： 900
```

題 2：

```text
2024 true
1900 false
2000 true
```

批改重點：
- 回傳型別寫在參數小括號後面。
- 題 1：每一條路都要 `return`，否則會出現 `missing return`。
- 題 2：可以直接 `return` 一個布林運算式，不一定要寫 `if`。
- 呼叫端要真的用到回傳值，不是在函式裡直接印。

提示方向：
1. `func ticketPrice(age int) int` 最後的 `int` 是回傳型別。
2. 呼叫 `ticketPrice(40)` 的地方會變成函式回傳的那個數字。
3. 題 2 的條件可以用 `&&` 和 `||` 組合，記得加小括號讓意思清楚。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func ticketPrice(age int) int {
	if age < 12 {
		return 150
	}
	return 300
}

func main() {
	total := ticketPrice(40) + ticketPrice(38) + ticketPrice(10) + ticketPrice(7)
	fmt.Println("總票價：", total)
}
```

題 2：

```go,ignore
package main

import "fmt"

func isLeapYear(year int) bool {
	return (year%4 == 0 && year%100 != 0) || year%400 == 0
}

func main() {
	fmt.Println(2024, isLeapYear(2024))
	fmt.Println(1900, isLeapYear(1900))
	fmt.Println(2000, isLeapYear(2000))
}
```

### 第 2 章第 9 集：多個回傳值

狀態：可用

練習目標：
- 會定義回傳兩個值的函式。
- 會用 `a, b := f()` 接住回傳值，用不到的用 `_` 丟掉。

題目：
1. 寫一個函式 `toHoursMinutes(total int) (int, int)`，把總分鐘數換成小時和分鐘。在 `main` 裡印出 `135` 和 `50` 分鐘的結果；再示範只需要小時時，怎麼用 `_` 丟掉分鐘。

執行範例：

```text
135 分鐘 = 2 小時 15 分鐘
50 分鐘 = 0 小時 50 分鐘
200 分鐘大約是 3 小時
```

批改重點：
- 回傳型別寫成 `(int, int)`，`return` 後面用逗號隔開兩個值。
- 呼叫端用兩個變數接住；只要一個時，另一個用 `_`。
- 讀者若用具名回傳值（第 10 集）也可以。

提示方向：
1. 小時是 `total / 60`，分鐘是 `total % 60`。
2. `h, m := toHoursMinutes(135)` 會一次拿到兩個值。

參考答案：

```go,ignore
package main

import "fmt"

func toHoursMinutes(total int) (int, int) {
	return total / 60, total % 60
}

func main() {
	h, m := toHoursMinutes(135)
	fmt.Println(135, "分鐘 =", h, "小時", m, "分鐘")
	h, m = toHoursMinutes(50)
	fmt.Println(50, "分鐘 =", h, "小時", m, "分鐘")
	hours, _ := toHoursMinutes(200)
	fmt.Println(200, "分鐘大約是", hours, "小時")
}
```

### 第 2 章第 10 集：具名回傳值

狀態：不出題

不出題原因：
- 具名回傳值主要是讓回傳值的意義更清楚，寫法上跟第 9 集只差在把名字寫出來。
- 單獨出題會跟第 9 集重複。讀者想練可以用具名回傳值重做第 9 集的題目。

### 第 2 章第 11 集：early `return`

狀態：可用

練習目標：
- 會先檢查例外情況並立刻 `return`，讓主要邏輯留在最外層。
- 能把巢狀很深的 `if` / `else` 改寫成 early return。

題目：
1. 下面的函式判斷能不能領取包裹，能正確執行但巢狀很深。請改寫成 early return 的風格：每種「不能領」的情況先 `return`，最後才回傳 `可以領取`。輸出要和原本一樣。

起始程式：

```go
package main

import "fmt"

func checkPickup(hasID bool, code int, days int) string {
	if hasID {
		if code == 1234 {
			if days <= 7 {
				return "可以領取"
			} else {
				return "已超過保管期限"
			}
		} else {
			return "取件碼錯誤"
		}
	} else {
		return "請出示證件"
	}
}

func main() {
	fmt.Println(checkPickup(true, 1234, 3))
	fmt.Println(checkPickup(false, 1234, 3))
	fmt.Println(checkPickup(true, 9999, 3))
	fmt.Println(checkPickup(true, 1234, 10))
}
```

執行範例：

```text
可以領取
請出示證件
取件碼錯誤
已超過保管期限
```

批改重點：
- 每個 `if` 檢查的是「不能領」的情況，成立就 `return` 錯誤訊息。
- 改寫後不需要任何 `else`，巢狀最多一層。
- 檢查順序要和原本一致，輸出才會一樣。

提示方向：
1. 原本最外層的條件是 `hasID`，反過來就是「沒有證件」，先處理它。
2. 處理完的情況就 `return`，下面的程式就不用再包在 `else` 裡。

參考答案：

```go,ignore
package main

import "fmt"

func checkPickup(hasID bool, code int, days int) string {
	if !hasID {
		return "請出示證件"
	}
	if code != 1234 {
		return "取件碼錯誤"
	}
	if days > 7 {
		return "已超過保管期限"
	}
	return "可以領取"
}

func main() {
	fmt.Println(checkPickup(true, 1234, 3))
	fmt.Println(checkPickup(false, 1234, 3))
	fmt.Println(checkPickup(true, 9999, 3))
	fmt.Println(checkPickup(true, 1234, 10))
}
```

### 第 2 章第 12 集：遞迴

狀態：可用

練習目標：
- 會寫有終止條件的遞迴函式。
- 知道每次呼叫自己時，問題要變小。

題目：
1. 寫一個遞迴函式 `sumTo(n int) int`，回傳 1 加到 `n` 的總和。印出 `sumTo(10)` 和 `sumTo(100)`。
2. 寫一個遞迴函式 `power(base, exp int) int`，回傳 `base` 的 `exp` 次方（`exp` 大於等於 0）。印出 `power(2, 10)` 和 `power(3, 4)`。

執行範例：

題 1：

```text
55
5050
```

題 2：

```text
1024
81
```

批改重點：
- 一定要有終止條件：題 1 是 `n == 0`（或 `n == 1`），題 2 是 `exp == 0`。
- 遞迴呼叫要讓問題變小：`sumTo(n-1)`、`power(base, exp-1)`。
- 讀者用迴圈寫出來雖然結果正確，但這題要練遞迴。

提示方向：
1. 「1 加到 n」等於「1 加到 n-1」再加上 n。
2. 最小、不用再拆的情況是什麼？那就是終止條件。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func sumTo(n int) int {
	if n == 0 {
		return 0
	}
	return sumTo(n-1) + n
}

func main() {
	fmt.Println(sumTo(10))
	fmt.Println(sumTo(100))
}
```

題 2：

```go,ignore
package main

import "fmt"

func power(base, exp int) int {
	if exp == 0 {
		return 1
	}
	return base * power(base, exp-1)
}

func main() {
	fmt.Println(power(2, 10))
	fmt.Println(power(3, 4))
}
```

### 第 2 章第 13 集：陣列基礎

狀態：可用

練習目標：
- 會宣告固定長度的陣列並給初始值。
- 會用索引讀寫元素，知道索引從 0 開始、最大是 `len - 1`。

題目：
1. 建立一個 `[7]int` 陣列存一週每天的步數：`6000, 8500, 7200, 9100, 4300, 12000, 10500`。印出第一天、最後一天的步數；接著把第五天的步數改成 `5000`，再印出整個陣列和陣列長度。

執行範例：

```text
第一天： 6000
最後一天： 10500
[6000 8500 7200 9100 5000 12000 10500]
天數： 7
```

批改重點：
- 第一天是索引 `0`，最後一天是索引 `6`（也可以寫 `len(steps)-1`）。
- 第五天是索引 `4`，不是 `5`。
- 長度用 `len(steps)`。

提示方向：
1. 索引從 0 開始數，所以第 N 天的索引是 N-1。
2. `steps[4] = 5000` 會改掉那一格的值。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	steps := [7]int{6000, 8500, 7200, 9100, 4300, 12000, 10500}
	fmt.Println("第一天：", steps[0])
	fmt.Println("最後一天：", steps[len(steps)-1])
	steps[4] = 5000
	fmt.Println(steps)
	fmt.Println("天數：", len(steps))
}
```

### 第 2 章第 14 集：`for range` 走訪陣列

狀態：可用

練習目標：
- 會用 `for i, v := range` 走訪陣列。
- 會用 `_` 丟掉用不到的索引。

題目：
1. 建立陣列 `scores := [5]int{72, 95, 58, 88, 64}`。用 `for range` 算出總分、最高分，以及不及格（低於 60）的人數，最後印出。

執行範例：

```text
總分： 377
最高分： 95
不及格人數： 1
```

批改重點：
- 不需要索引時寫 `for _, s := range scores`。
- 最高分的起始值可以用 `scores[0]`，或用 0（分數不會是負數）。
- 這集還沒教內建的 `max`（第 29 集），用 `if` 比較是正確的做法。

提示方向：
1. 總分、最高分、不及格人數各需要一個變數，都要在迴圈外建立。
2. 每一圈拿到一個分數，分別更新這三個變數。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	scores := [5]int{72, 95, 58, 88, 64}
	total := 0
	highest := scores[0]
	failed := 0
	for _, s := range scores {
		total += s
		if s > highest {
			highest = s
		}
		if s < 60 {
			failed++
		}
	}
	fmt.Println("總分：", total)
	fmt.Println("最高分：", highest)
	fmt.Println("不及格人數：", failed)
}
```

### 第 2 章第 15 集：切片

狀態：不出題

不出題原因：
- 這集介紹切片的寫法和「窗戶」的概念，能做的操作（索引、`len`、`for range`）跟陣列一樣，第 14 集已經練過。
- 切片真正不同的地方從第 16 集的 `append` 開始，建議到那集再練。

### 第 2 章第 16 集：`append`、`len`、`cap`

狀態：可用

練習目標：
- 會用 `s = append(s, 值)` 在切片尾端加入元素，並把結果接回來。
- 會從空切片開始，用迴圈收集符合條件的值。

題目：
1. 從 `var evens []int` 開始，用迴圈把 1 到 20 之中的偶數一個一個 `append` 進去，最後印出切片和它的長度。
2. 建立購物清單 `list := []string{"牛奶"}`，用一次 `append` 同時加入 `"雞蛋"` 和 `"吐司"`，印出清單和長度。

執行範例：

題 1：

```text
[2 4 6 8 10 12 14 16 18 20]
長度： 10
```

題 2：

```text
[牛奶 雞蛋 吐司]
長度： 3
```

批改重點：
- `append` 的結果一定要接回來：`evens = append(evens, i)`。只寫 `append(evens, i)` 會無法編譯。
- 題 2：`append` 可以一次放好幾個值。
- 不要求讀者預測 `cap` 的數字，容量怎麼成長由 Go 決定。

提示方向：
1. `nil` 切片可以直接 `append`，不用先準備空間。
2. 迴圈裡先判斷是不是偶數，是的話再 `append`。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	var evens []int
	for i := 1; i <= 20; i++ {
		if i%2 == 0 {
			evens = append(evens, i)
		}
	}
	fmt.Println(evens)
	fmt.Println("長度：", len(evens))
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	list := []string{"牛奶"}
	list = append(list, "雞蛋", "吐司")
	fmt.Println(list)
	fmt.Println("長度：", len(list))
}
```

### 第 2 章第 17 集：切片運算式 `s[a:b]`

狀態：可用

練習目標：
- 會用 `s[a:b]`、`s[:b]`、`s[a:]` 取出一段切片。
- 知道 `b` 是「到這個索引之前」。

題目：
1. 建立 `days := []string{"一", "二", "三", "四", "五", "六", "日"}`。用切片運算式取出上班日（星期一到五）和週末，分別印出來；再印出星期三到星期五。

執行範例：

```text
上班日： [一 二 三 四 五]
週末： [六 日]
三到五： [三 四 五]
```

批改重點：
- 上班日是 `days[:5]`，週末是 `days[5:]`。
- 星期三到星期五是 `days[2:5]`：起點是索引 2，終點寫 5（不含）。
- 長度可以用 `b - a` 檢查：`days[2:5]` 有 3 個。

提示方向：
1. 先把每一天的索引寫出來：一是 0、二是 1……日是 6。
2. `s[a:b]` 包含 `a`，不包含 `b`。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	days := []string{"一", "二", "三", "四", "五", "六", "日"}
	fmt.Println("上班日：", days[:5])
	fmt.Println("週末：", days[5:])
	fmt.Println("三到五：", days[2:5])
}
```

### 第 2 章第 18 集：切片共用底層陣列

狀態：不出題

不出題原因：
- 這集的重點是「看懂」共用底層陣列造成的現象，適合的練習是預測輸出，不是寫新程式。
- 想避免共用的實際寫法在第 19 集（`copy`）和第 21 集（`make`），建議到那裡再練。讀者若想確認自己懂了，可以請他改動書上範例的數字，自己先猜結果再執行。

### 第 2 章第 19 集：`copy`

狀態：可用

練習目標：
- 會用 `copy(dst, src)` 把元素複製到另一個切片，目的地寫在前面。
- 知道複製後兩個切片互不影響。

題目：
1. 建立 `original := []int{3, 1, 4}`，再準備一個長度一樣的切片 `backup := []int{0, 0, 0}`，用 `copy` 把 `original` 的內容複製過去。接著把 `original[0]` 改成 `99`，印出兩個切片，確認 `backup` 沒有被影響。

執行範例：

```text
複製了 3 個
original: [99 1 4]
backup: [3 1 4]
```

批改重點：
- `copy` 的順序是 `copy(目的地, 來源)`。
- `backup` 要有足夠的長度；如果寫成 `var backup []int`，`copy` 一個都不會複製。
- `copy` 的回傳值是複製的個數，可以印出來確認。
- 直接寫 `backup := original` 是共用底層陣列（第 18 集），不是複製。

提示方向：
1. `copy` 不會讓目的地變長，所以 `backup` 要先有 3 格。
2. 改完 `original` 後兩個都印出來，比對看看。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	original := []int{3, 1, 4}
	backup := []int{0, 0, 0}
	n := copy(backup, original)
	fmt.Println("複製了", n, "個")
	original[0] = 99
	fmt.Println("original:", original)
	fmt.Println("backup:", backup)
}
```

### 第 2 章第 20 集：切片作為參數

狀態：可用

練習目標：
- 知道函式裡改切片元素，呼叫端看得到。
- 知道函式裡 `append` 的結果要回傳，由呼叫端接回來。

題目：
1. 寫兩個函式：
    - `addBonus(scores []int, bonus int)`：把每個分數都加上 `bonus`，不回傳。
    - `addScore(scores []int, s int) []int`：在尾端加一個分數，回傳新的切片。

   從 `scores := []int{70, 80}` 開始，先加一筆 `90`，再每人加 5 分，最後印出。

執行範例：

```text
[75 85 95]
```

批改重點：
- `addBonus` 裡要用 `scores[i] += bonus` 改元素；寫 `for _, s := range` 再改 `s` 改不到。
- `addScore` 要回傳 `append` 的結果，呼叫端寫 `scores = addScore(scores, 90)`。
- 讀者若問為什麼一個要回傳、一個不用：改元素是透過共用的底層陣列；`append` 改的是長度，函式裡拿到的只是 header 的複本。

提示方向：
1. 先寫 `addScore`，確認呼叫後印出來是 `[70 80 90]`。
2. 改元素要用索引：`for i := range scores`。

參考答案：

```go,ignore
package main

import "fmt"

func addBonus(scores []int, bonus int) {
	for i := range scores {
		scores[i] += bonus
	}
}

func addScore(scores []int, s int) []int {
	return append(scores, s)
}

func main() {
	scores := []int{70, 80}
	scores = addScore(scores, 90)
	addBonus(scores, 5)
	fmt.Println(scores)
}
```

### 第 2 章第 21 集：`make`

狀態：可用

練習目標：
- 會用 `make([]T, n)` 建立長度在執行時才決定的切片。
- 會用 `make([]T, 0, c)` 先準備容量，再用 `append` 放入元素。

題目：
1. 請使用者輸入一個正整數 `n`，用 `make([]int, n)` 建立切片，把 1 到 `n` 的平方依序放進去，最後印出切片。輸入不是整數或小於 1 時，印出提示並結束。
2. 建立 `scores := []int{45, 80, 62, 90, 30}`，用 `make([]int, 0, len(scores))` 準備新切片，只把及格（60 分以上）的分數 `append` 進去，最後印出新切片、長度和容量。

執行範例：

題 1，輸入 `5` 時：

```text
請輸入 n：
[1 4 9 16 25]
```

題 2：

```text
[80 62 90]
3 5
```

批改重點：
- 題 1：用 `make([]int, n)` 之後要用索引 `squares[i] = ...` 放值；如果改用 `append`，前面 `n` 個 0 會留著。
- 題 1：記得檢查 `err` 和 `n < 1`。
- 題 2：長度 0、容量 5 的切片要用 `append` 放入；用索引寫入會 panic。
- 題 2：容量先準備成原本切片的長度，`append` 過程中就不需要換新的底層陣列。

提示方向：
1. `make([]int, n)` 會得到 `n` 個 0，索引從 0 到 `n-1`。
2. 第 `i` 格要放的是 `(i+1)` 的平方。
3. 長度是「已經有幾個」，容量是「準備了幾格」。

參考答案：

題 1：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strconv"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入 n：")
	scanner.Scan()
	line := scanner.Text()
	n, err := strconv.Atoi(line)
	if err != nil {
		fmt.Println("請輸入整數")
		return
	}
	if n < 1 {
		fmt.Println("n 要大於 0")
		return
	}

	squares := make([]int, n)
	for i := range n {
		squares[i] = (i + 1) * (i + 1)
	}
	fmt.Println(squares)
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	scores := []int{45, 80, 62, 90, 30}
	passed := make([]int, 0, len(scores))
	for _, s := range scores {
		if s >= 60 {
			passed = append(passed, s)
		}
	}
	fmt.Println(passed)
	fmt.Println(len(passed), cap(passed))
}
```

### 第 2 章第 22 集：字串與 UTF-8

狀態：可用

練習目標：
- 知道 `len(s)` 算的是 byte 數，不是字數。
- 會用 `len([]rune(s))` 算字數。

題目：
1. 社群貼文限制最多 10 個字。寫一個函式 `checkPost(text string)`，印出這段文字的 byte 數、字數，以及有沒有超過限制。用 `"Hello Go"` 和 `"今天天氣很好適合出去走走"` 各試一次。

執行範例：

```text
Hello Go
byte 數： 8 字數： 8
可以發布
今天天氣很好適合出去走走
byte 數： 36 字數： 12
超過 10 個字
```

批改重點：
- 字數要用 `len([]rune(text))`，不能用 `len(text)`。
- 英文字一個字 1 byte，中文字通常 3 byte，所以兩者在英文時相同、中文時不同。
- 空白也算一個字。

提示方向：
1. 先印出 `len(text)`，看看中文那句是不是比你想的多很多。
2. 把字串轉成 `[]rune` 之後，每一格就是一個字。

參考答案：

```go,ignore
package main

import "fmt"

func checkPost(text string) {
	count := len([]rune(text))
	fmt.Println(text)
	fmt.Println("byte 數：", len(text), "字數：", count)
	if count > 10 {
		fmt.Println("超過 10 個字")
		return
	}
	fmt.Println("可以發布")
}

func main() {
	checkPost("Hello Go")
	checkPost("今天天氣很好適合出去走走")
}
```

### 第 2 章第 23 集：`for range` 走訪字串

狀態：可用

練習目標：
- 會用 `for _, r := range s` 一個字一個字走訪字串。
- 會拿 `rune` 和單引號的字比較。

題目：
1. 寫一個函式 `countRune(s string, target rune) int`，回傳 `target` 這個字在 `s` 裡出現幾次。用它算出 `"吃葡萄不吐葡萄皮，不吃葡萄倒吐葡萄皮"` 裡有幾個 `'葡'`、幾個 `'吐'`。

執行範例：

```text
葡： 4
吐： 2
```

批改重點：
- 走訪要用 `for _, r := range s`，拿到的 `r` 是完整的字。
- 用 `s[i]` 走訪會拿到 byte，比不到中文字。
- 比較時用單引號：`r == target`，呼叫時傳 `'葡'`。
- 印出 `rune` 時要用 `string(r)` 才會是字；這題印的是次數，不需要轉。

提示方向：
1. 先寫一個迴圈，把每個字用 `string(r)` 印出來，確認拿到的是完整的字。
2. 再加上 `if r == target` 和計數。

參考答案：

```go,ignore
package main

import "fmt"

func countRune(s string, target rune) int {
	count := 0
	for _, r := range s {
		if r == target {
			count++
		}
	}
	return count
}

func main() {
	text := "吃葡萄不吐葡萄皮，不吃葡萄倒吐葡萄皮"
	fmt.Println("葡：", countRune(text, '葡'))
	fmt.Println("吐：", countRune(text, '吐'))
}
```

### 第 2 章第 24 集：`strings` 套件常用函式

狀態：可用

練習目標：
- 會用 `strings` 套件處理常見的文字工作。
- 知道這些函式回傳新字串，不會改到原本的字串。

題目：
1. 請使用者輸入一個 email，先用 `strings.TrimSpace` 去掉前後空白，再用 `strings.ToLower` 轉小寫。如果不包含 `@`，印出 `格式不對`；否則印出整理後的 email，以及它是不是 `.tw` 結尾。
2. 有一串用逗號分隔的水果 `"蘋果,香蕉,芭樂"`，用 `strings.Split` 拆開，印出有幾種水果，再用 `strings.Join` 以 ` / ` 接回來印出。

執行範例：

題 1，輸入前後帶有空白的 `Gopher@Example.TW` 時：

```text
請輸入 email：
gopher@example.tw
是 .tw 結尾： true
```

題 2：

```text
共 3 種
蘋果 / 香蕉 / 芭樂
```

批改重點：
- 題 1：要把結果接回變數，例如 `email = strings.TrimSpace(email)`；只呼叫不接，原字串不會變。
- 題 1：檢查用 `strings.Contains`，結尾用 `strings.HasSuffix`。
- 題 2：`Split` 的結果是 `[]string`，可以用 `len` 算個數。
- `import` 要加 `"strings"`，並照字母排序。

提示方向：
1. 先印出整理前和整理後的字串，確認 `TrimSpace`、`ToLower` 有作用。
2. `strings.Contains(email, "@")` 回傳 `true` 或 `false`。
3. `strings.Split(s, ",")` 會把逗號拿掉並切開。

參考答案：

題 1：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("請輸入 email：")
	scanner.Scan()
	email := scanner.Text()
	email = strings.TrimSpace(email)
	email = strings.ToLower(email)
	if !strings.Contains(email, "@") {
		fmt.Println("格式不對")
		return
	}
	fmt.Println(email)
	fmt.Println("是 .tw 結尾：", strings.HasSuffix(email, ".tw"))
}
```

題 2：

```go,ignore
package main

import (
	"fmt"
	"strings"
)

func main() {
	fruits := strings.Split("蘋果,香蕉,芭樂", ",")
	fmt.Println("共", len(fruits), "種")
	fmt.Println(strings.Join(fruits, " / "))
}
```

### 第 2 章第 25 集：map 基礎

狀態：可用

練習目標：
- 會建立 `map[string]int` 並用鍵查值。
- 會新增、修改 map 的資料，並知道查不到的鍵會得到零值。

題目：
1. 建立價目表 `prices := map[string]int{"紅茶": 30, "綠茶": 30, "奶茶": 45}`。
    - 新增 `"咖啡"`，價格 `60`。
    - 奶茶漲價為 `50`。
    - 計算一張訂單的總價：一杯紅茶、兩杯奶茶、一杯咖啡。
    - 印出價目表有幾項，以及查詢不存在的 `"可可"` 會得到什麼。

執行範例：

```text
總價： 190
價目表共 4 項
可可： 0
```

批改重點：
- 新增和修改都是 `prices[鍵] = 值`。
- 總價用 `prices["紅茶"] + prices["奶茶"]*2 + prices["咖啡"]`。
- `len(prices)` 是筆數。
- 查不存在的鍵得到 `0`，不會出錯；要分辨「不存在」和「價格是 0」是下一集的內容。

提示方向：
1. map 用 `m[k]` 查值，用 `m[k] = v` 新增或修改，兩種情況寫法一樣。
2. 每一杯的價格都從 `prices` 查，不要寫死數字。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	prices := map[string]int{"紅茶": 30, "綠茶": 30, "奶茶": 45}
	prices["咖啡"] = 60
	prices["奶茶"] = 50

	total := prices["紅茶"] + prices["奶茶"]*2 + prices["咖啡"]
	fmt.Println("總價：", total)
	fmt.Println("價目表共", len(prices), "項")
	fmt.Println("可可：", prices["可可"])
}
```

### 第 2 章第 26 集：comma-ok

狀態：可用

練習目標：
- 會用 `v, ok := m[k]` 判斷鍵存不存在。
- 會用 `if !ok { ...; return }` 先處理找不到的情況。

題目：
1. 建立電話簿 `phones := map[string]string{"小明": "0912-345-678", "小華": "0987-654-321"}`。請使用者輸入名字，找到就印出電話，找不到就印出 `查無此人`。

執行範例：

輸入 `小華` 時：

```text
要查誰？
小華 的電話是 0987-654-321
```

輸入 `小美` 時：

```text
要查誰？
查無此人
```

批改重點：
- 要用 `phone, ok := phones[name]`，用 `ok` 判斷，而不是檢查 `phone == ""`。
- 找不到的情況先處理並 `return`，主要邏輯留在外層。
- `phones` 存的是文字，所以型別是 `map[string]string`。

提示方向：
1. 查 map 時多接一個 `ok`，它會告訴你這個鍵在不在。
2. `ok` 是 `false` 時印出提示並結束。

參考答案：

```go,ignore
package main

import (
	"bufio"
	"fmt"
	"os"
)

func main() {
	phones := map[string]string{"小明": "0912-345-678", "小華": "0987-654-321"}

	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("要查誰？")
	scanner.Scan()
	name := scanner.Text()

	phone, ok := phones[name]
	if !ok {
		fmt.Println("查無此人")
		return
	}
	fmt.Println(name, "的電話是", phone)
}
```

### 第 2 章第 27 集：`if` / `switch` 的初始化敘述

狀態：可用

練習目標：
- 會寫 `if v, ok := m[k]; ok { ... }`。
- 知道初始化敘述裡的變數只在那個 `if` / `else` 裡有效。

題目：
1. 有庫存表 `stock := map[string]int{"鉛筆": 12, "橡皮擦": 0}`。寫一個函式 `report(stock map[string]int, item string)`，用 `if` 的初始化敘述查庫存，分三種情況印出：沒有這項商品、已售完、還有幾個。用 `"鉛筆"`、`"橡皮擦"`、`"尺"` 各呼叫一次。

執行範例：

```text
鉛筆 還有 12 個
橡皮擦 已售完
沒有 尺 這項商品
```

批改重點：
- 查詢寫在 `if` 的初始化敘述裡：`if n, ok := stock[item]; !ok { ... }`。
- 後面的 `else if n == 0`、`else` 都可以使用 `n`。
- `stock` 從 `main` 當參數傳進函式。

提示方向：
1. 先分清楚「沒有這項商品」和「庫存是 0」：前者要靠 `ok`，後者看 `n`。
2. 初始化敘述建立的 `n`、`ok`，在後面的 `else if`、`else` 裡也能用。

參考答案：

```go,ignore
package main

import "fmt"

func report(stock map[string]int, item string) {
	if n, ok := stock[item]; !ok {
		fmt.Println("沒有", item, "這項商品")
	} else if n == 0 {
		fmt.Println(item, "已售完")
	} else {
		fmt.Println(item, "還有", n, "個")
	}
}

func main() {
	stock := map[string]int{"鉛筆": 12, "橡皮擦": 0}
	report(stock, "鉛筆")
	report(stock, "橡皮擦")
	report(stock, "尺")
}
```

### 第 2 章第 28 集：`delete` 與走訪 map

狀態：可用

練習目標：
- 會用 `m[k]++` 計數。
- 會用 `for k, v := range m` 走訪 map，並知道順序不固定。
- 會用 `delete` 刪除一筆資料。

題目：
1. 班上投票選班遊地點，票是 `votes := []string{"海邊", "山上", "海邊", "遊樂園", "海邊", "山上"}`。用 map 統計每個地點的票數，然後：
    - 用 `for range` 走訪 map，找出最高票的地點。
    - 「遊樂園」因故取消，用 `delete` 刪掉，再印出剩下幾個選項。

執行範例：

```text
最高票： 海邊 3 票
剩下 2 個選項
```

批改重點：
- 計數可以直接寫 `counts[v]++`，不用先檢查鍵存不存在。
- `counts` 要先用 `map[string]int{}` 或 `make` 建立；`var counts map[string]int` 是 `nil` map，寫入會 panic。
- map 走訪順序不固定，所以這題只印最高票和數量，不印整張表；讀者若把整張表印出來，提醒他每次順序可能不同。
- 這題沒有平手，不需要處理平手的情況。

提示方向：
1. 先走訪 `votes`，把每一票加到 `counts` 裡。
2. 再走訪 `counts`，用兩個變數記住目前最高的地點和票數。
3. `delete(counts, "遊樂園")` 之後，用 `len(counts)` 看剩幾筆。

參考答案：

```go,ignore
package main

import "fmt"

func main() {
	votes := []string{"海邊", "山上", "海邊", "遊樂園", "海邊", "山上"}
	counts := map[string]int{}
	for _, v := range votes {
		counts[v]++
	}

	best := ""
	bestCount := 0
	for place, n := range counts {
		if n > bestCount {
			best = place
			bestCount = n
		}
	}
	fmt.Println("最高票：", best, bestCount, "票")

	delete(counts, "遊樂園")
	fmt.Println("剩下", len(counts), "個選項")
}
```

### 第 2 章第 29 集：內建 `min` `max` `clear`

狀態：可用

練習目標：
- 會用 `max`、`min` 在迴圈裡更新最大、最小值。
- 會用 `clear` 清空 map，並知道對切片使用時長度不變。

題目：
1. 有一週的氣溫 `temps := []int{24, 27, 31, 29, 22, 26, 30}`，用迴圈搭配 `max`、`min` 找出最高溫和最低溫，印出溫差。
2. 有一個購物車 `cart := map[string]int{"蘋果": 3, "牛奶": 1}`。結帳後用 `clear` 清空，印出清空前後的品項數。

執行範例：

題 1：

```text
最高 31 度，最低 22 度，溫差 9 度
```

題 2：

```text
結帳前 2 項
結帳後 0 項
```

批改重點：
- 題 1：起始值用 `temps[0]`，迴圈裡寫 `highest = max(highest, t)`、`lowest = min(lowest, t)`。
- 題 1：若起始值寫 0，最低溫會變成 0，是錯的。
- 題 2：`clear(cart)` 之後 `len(cart)` 是 0；`cart` 還能繼續使用。
- 讀者若問可不可以用 `slices.Max`：可以，但那是第 6 章的內容，這集先用 `max`。

提示方向：
1. 最高和最低的起始值，用第一天的氣溫最保險。
2. `max(a, b)` 會回傳比較大的那個。

參考答案：

題 1：

```go,ignore
package main

import "fmt"

func main() {
	temps := []int{24, 27, 31, 29, 22, 26, 30}
	highest := temps[0]
	lowest := temps[0]
	for _, t := range temps {
		highest = max(highest, t)
		lowest = min(lowest, t)
	}
	fmt.Println("最高", highest, "度，最低", lowest, "度，溫差", highest-lowest, "度")
}
```

題 2：

```go,ignore
package main

import "fmt"

func main() {
	cart := map[string]int{"蘋果": 3, "牛奶": 1}
	fmt.Println("結帳前", len(cart), "項")
	clear(cart)
	fmt.Println("結帳後", len(cart), "項")
}
```
