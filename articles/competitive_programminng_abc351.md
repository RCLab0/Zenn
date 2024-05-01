---
title: "AtCoder ABC 351 参加してみた"
emoji: "📝"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["javascript", "AtCoder"]
published: false
---

RCLab です。数年ぶりに競技プログラミングやってみたいなと思ったので、AtCoder に参加しました。
https://atcoder.jp/users/RClab

js から標準入力どうすんだっけ？みたいなところからリスタート。当分の目標は参加できる週は毎回参加でやっていききます。

# A. The bottom of the ninth
:::details 解答
```js
const { log } = require("console")

function Main(input) {
    let [a, b] = input.split("\n")
    a = a.split(' ').map(v => parseInt(v))
    b = b.split(' ').map(v => parseInt(v))

    a_total = a.reduce((a, b) => a + b)
    b_total = b.reduce((a, b) => a + b)

    console.log(a_total - b_total + 1)
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

# B. Spot the Difference
:::details 解答
```js
const { log } = require("console")

function Main(input) {
    let rules = input.split("\n")
    const N = parseInt(rules[0])

    for (let i = 0; i < N; i++) {
        const A = rules[1 + i]
        const B = rules[1 + N + i]
        for (let j = 0; j < N; j++) {
            if (A.charAt(j) !== B.charAt(j)) {
                console.log(i + 1, j + 1)
                return
            }
        }
    }
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

# C. Merge the balls
Array.shift() よりも Array.pop() の方が計算量少ないことを失念して TLE。
普段 js でそこまで意識できてないなって思いました
:::details TLE の解答
```js
const { log } = require("console")

function Main(input) {
    let rules = input.split("\n")
    const N = parseInt(rules[0])
    const sizes = rules[1].split(' ').map(v => parseInt(v))

    const balls = [sizes[0]]
    for (let i = 1; i < N; i++) {
        if (sizes[i] === balls[0]) {
            balls[0]++
            while (1) {
                if (balls.length === 1) {
                    break
                }
                if (balls[0] !== balls[1]) {
                    break
                }
                balls.shift()
                balls[0]++
            }
        } else {
            balls.unshift(sizes[i])
        }
    }
    log(balls.length)
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

pop 使って書き直したらいけました。

:::details 解答
```js
const { log } = require("console")

function Main(input) {
    let rules = input.split("\n")
    const N = parseInt(rules[0])
    const sizes = rules[1].split(' ').map(v => parseInt(v))

    const balls = []
    for (let i = 0; i < N; i++) {
        balls.push(sizes[i])
        while (1) {
            if (balls.length === 1) {
                break
            }
            if (balls[balls.length - 1] !== balls[balls.length - 2]) {
                break
            }
            balls[balls.length - 2]++
            balls.pop()
        }

    }
    log(balls.length)
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

# D. Grid and Magnet
ここからコンテスト中に見てない問題です。 shift pop 問題で諦めて辞めてしまった...  
FIFO を Array.push Array.shift で実装しようと思ったんですが、さっきと同様の問題で TLE してしまいます。(1敗)
今更だけど js 競プロに向いてないな... queue も自分で実装するしかなさそうです。今回は RingBufferQueue を実装して実行時間を減らしました。

そもそも根本的にこれを見て「グラフの探索問題だ！」ってピンとこない時点で素人なのですかね。精進します。

↓ 色々と苦しんだ跡。
https://atcoder.jp/contests/abc351/submissions?f.Task=abc351_d&f.LanguageName=&f.Status=&f.User=RClab

:::details 解答
```js
const { log } = require("console")

class RingBufferQueue {
    value
    head
    tail

    constructor(size = 4294967295) {
        this.value = Array(size).fill(undefined)
        this.head = 0
        this.tail = 0
    }

    push(value) {
        this.value[this.tail] = value
        this.tail++
    }

    pop() {
        const ret = this.value[this.head]
        this.head++
        return ret
    }

    size() {
        return this.tail - this.head
    }

    init() {
        this.head = 0
        this.tail = 0
    }
}

function Main(input) {
    const rules = input.split("\n")
    const [H, W] = rules[0].split(' ').map(v => parseInt(v))
    // これで 1行目から H行目までが .# の文字列になる
    rules.shift()

    const dx = [-1, 0, 1, 0]
    const dy = [0, -1, 0, 1]

    // # またはそれに隣接するマスを全てメモ化
    const dead_end_or_sharp = Array.from({ length: H }, e => Array(W).fill(false))
    for (let i = 0; i < H; i++) {
        for (let j = 0; j < W; j++) {
            if (rules[i].charAt(j) === '#') {
                dead_end_or_sharp[i][j] = true
                for (let v = 0; v < 4; v++) {
                    const next_x = i + dx[v]
                    const next_y = j + dy[v]

                    // 境界条件
                    if (next_x < 0 || next_x > H - 1 || next_y < 0 || next_y > W - 1) {
                        continue
                    }
                    // # マスの周り四マスは行き止まりになる
                    dead_end_or_sharp[next_x][next_y] = true
                }
            }
        }
    }

    // それ以外のマスに関して、深さ優先探索 (DFS) で幾つの塊の大きさを調べる
    // 一度チェックしたマスの座標をメモ化
    const checked = Array.from({ length: H }, e => Array(W).fill(false))
    let ans = 1

    // i,j から探索を開始して、到達できるマスのキューのデータ構造を用意
    const can_reach = new RingBufferQueue(H * W)
    // i,j から探索を開始して、到達できるマスの個数を調べる
    for (let i = 0; i < H; i++) {
        for (let j = 0; j < W; j++) {
            if (dead_end_or_sharp[i][j]) continue
            if (checked[i][j]) continue
            checked[i][j] = true

            // 到達したことのある行き止まりをメモ化
            // Array.from({ length: H }, e => Array(W).fill(false)) は計算量がエグいことになるので、
            // H * i + j をキーとした key value store を用いる
            const visited_dead_end = []
            // i,j から探索を開始して、到達できるマスのキューを初期化
            can_reach.init()
            // i,j は到達可能なのでキューに積む
            can_reach.push([i, j])
            // i,j から探索を開始して、到達できるマスの数
            // キューから取り出すタイミングで到達したとして、インクリメントする
            let tmp_ans = 0
            while (can_reach.size() > 0) {
                // 移動開始前の初期位置
                const [init_x, init_y] = can_reach.pop()
                // キューから position を取り出したので、その座標に到達した
                tmp_ans++
                for (let v = 0; v < 4; v++) {
                    const next_x = init_x + dx[v]
                    const next_y = init_y + dy[v]

                    // 境界条件
                    if (next_x < 0 || next_x > H - 1 || next_y < 0 || next_y > W - 1) {
                        continue
                    }
                    // 既に踏破した座標はキューに詰めないようにする
                    if (checked[next_x][next_y]) {
                        continue
                    }
                    // 隣が行き止まりの場合は、1マスだけ進める
                    if (dead_end_or_sharp[next_x][next_y]) {
                        // 既に踏破した行き止まりも二重でカウントしないようにする
                        if (visited_dead_end[next_x * W + next_y] === undefined) {
                            visited_dead_end[next_x * W + next_y] = true
                            tmp_ans++
                        }
                        continue
                    }
                    // 隣が行き止まりでないとき、探索を続ける
                    // 始発となる座標をキューに積む
                    checked[next_x][next_y] = true
                    can_reach.push([next_x, next_y])
                }
            }
            ans = Math.max(ans, tmp_ans)
        }
    }
    log(ans)
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

# E. Jump Distance Sum
やや数学的なばらしが必要だった問題でしょうか。以下のような座標変換を考えます。

$$
\begin{equation*}
  \begin{split}
    \begin{pmatrix}X \\ Y\end{pmatrix}
     &= \sqrt{2} \begin{pmatrix} \cos(4/\pi) -\sin(4/\pi) \\ \sin(4/\pi) \cos(4/\pi) \end{pmatrix} \begin{pmatrix}x \\ y\end{pmatrix} \\
     &= \begin{pmatrix}x - y \\ x + y\end{pmatrix}
  \end{split}
\end{equation*}
$$

すると (x, y)座標上で(a, b) から (c, d)に移動する時のジャンプの回数が
```js
Math.max(Math.abs(a-c), Math.abs(b-d))
```
から
```js
(Math.abs(A-C) + Math.abs(B-D)) / 2
```
になっていることがわかります。具体的な幾つかの座標で確かめるのが良いでしょう。
`Math.abs` を気にしなくて良いように、`X_j > X_i` となるようにソートをしてシグマの式を展開すると、コード内のコメントにあるように

$$
\begin{equation*}
  \begin{split}
    \sum_{\mathclap{1 \le i \lt j \le N }}\text{dist}
     &= {1 \above{1px} 2}\left(\sum_{\mathclap{0 \le i \le N-1 }}\text{dist}(2i+1-N)X_i + \sum_{\mathclap{0 \le i \le N-1 }}\text{dist}(2i+1-N)Y_i\right)
  \end{split}
\end{equation*}
$$

のように変換されるので、O(N) の計算量で計算できそうです。
よって、ボトルネックはソートの O(nlog(n)) になる、というところまではわかって以下を実装しましたが、どこが nlog(n) 以上の計算量になっているのかわからず TLE を解消できませんでした。

:::details TLE 誤答
```js
const { log } = require("console")

function mergeSort(array) {
    if (array.length < 2) {
        return array
    }

    const middle = Math.floor(array.length / 2)
    const left = array.slice(0, middle)
    const right = array.slice(middle)

    return merge(mergeSort(left), mergeSort(right))
}

function merge(left, right) {
    const result = []
    let i = 0
    let j = 0

    while (i < left.length && j < right.length) {
        if (left[i] - right[j] < 0) {
            result.push(left[i++])
        } else {
            result.push(right[j++])
        }
    }

    return result.concat(left.slice(i)).concat(right.slice(j))
}


function Main(input) {
    const rules = input.split("\n")
    const N = parseInt(rules[0])
    const even_xs = []
    const even_ys = []
    const odd_xs = []
    const odd_ys = []
    for (let i = 0; i < N; i++) {
        // 45° 回転させて、ルート2倍する
        // (X, Y) = √2 ((cos 4/π, -sin 4/π), (sin 4/π, cos 4/π))(x , y)
        //        = (x - y, x + y)
        // となる
        //
        // また、x - y, x + y の差は -2y と偶数であるため、
        // 移動後の X, Y は必ず偶奇が等しい
        //
        // うさぎの移動も (1, -1) -> (2, 0) のように写像されるので、
        // 先の X ≡ Y (mod2) と合わせて考えると、X (つまり Y) が偶数の座標から
        // X' (つまり Y') が奇数の座標への移動は起こらない
        //
        // なので、予め odd と even で分けて考える
        const [x, y] = rules[i + 1].split(' ').map(v => parseInt(v))
        if ((x - y) % 2 === 0) {
            even_xs.push([x - y])
            even_ys.push([x + y])
        } else {
            odd_xs.push([x - y])
            odd_ys.push([x + y])
        }
    }

    // 先の写像によって
    //   sum(i=1 -> N-1)(sum(j=i+1 -> N)(max(|xi - xj|, |yi - yj|)))
    // = sum(i=1 -> N-1)(sum(j=i+1 -> N)(1/2 * (|Xi - Xj| + |Yi - Yj|)))
    // = 1/2 (sum(i=1 -> N-1)(sum(j=i+1 -> N)(|Xi - Xj|))) + 1/2 (sum(i=1 -> N-1)(sum(j=i+1 -> N)(|Yi - Yj|))) ...①
    // に変換されていることに注目する
    //
    // 例)
    // (0, 0) -> (2, 4) への移動(max((2 - 0), (4 - 0)) = 4回) は
    // (0, 0) -> (-2, 6) への移動 ((|6| + |-2|) / 2 = 4回) へと写像される
    // 差分の最大値の回数移動が、 X軸 Y軸方向へのそれぞれの移動の和に変換される
    //
    // ① は X に関する式と Y に関する式が独立で考えられるので、
    // 初項は X に関してソートを行い Xj > Xi となるように並べ替えると
    // (①の初項) = 1/2 (sum(i=0 -> N-1)(sum(j=i -> N)(Xj - Xi)))
    // 定数を省略してバラすと
    //   sum(i=1 -> N-1)(sum(j=i+1 -> N)Xj - sum(j=i+1 -> N)Xi)
    // = sum(i=1 -> N-1)(sum(j=i+1 -> N)Xj - (N - i)Xi)
    // = sum(i=1 -> N-1)({X_i+1 + X_i+1 + ... + X_N} - (N - i)Xi)
    // = X_2 + X_3 + X_4 + ... + X_N-1 + X_N - (N - 1) X_1
    //       + X_3 + X_4 + ... + X_N-1 + X_N - (N - 2) X_2
    //             + X_4 + ... + X_N-1 + X_N - (N - 3) X_3
    //                   + ...
    //                         + X_N-1 + X_N - (N - (N - 2)) X_N-2
    //                                 + X_N - (N - (N - 1)) X_N-1
    // = (1 - N + 0) X_1 + (2 - N + 1) X_2  + (3 - N + 2) X_3 + ... + ((N - 1) - N + (N - 2)) X_N-1 + (N - 1) X_N
    // = sum(i=1 -> N)(i - N + (i - 1))Xi
    // = sum(i=1 -> N)(2i - N - 1)Xi
    // と計算できるので O(N) で和を求めることが出来る

    const sorted_even_xs = mergeSort(even_xs)
    const sorted_even_ys = mergeSort(even_ys)
    const sorted_odd_xs = mergeSort(odd_xs)
    const sorted_odd_ys = mergeSort(odd_ys)

    let ans = 0
    for (let i = 0; i < sorted_even_xs.length; i++) {
        ans += (2 * i + 1 - sorted_even_xs.length) * sorted_even_xs[i]
    }
    for (let i = 0; i < sorted_even_ys.length; i++) {
        ans += (2 * i + 1 - sorted_even_ys.length) * sorted_even_ys[i]
    }
    for (let i = 0; i < sorted_odd_xs.length; i++) {
        ans += (2 * i + 1 - sorted_odd_xs.length) * sorted_odd_xs[i]
    }
    for (let i = 0; i < sorted_odd_ys.length; i++) {
        ans += (2 * i + 1 - sorted_odd_ys.length) * sorted_odd_ys[i]
    }

    log(ans / 2)
}

Main(require("fs").readFileSync("/dev/stdin", "utf8"))
```
:::

# F. Double Sum
# G. Hash on Tree
このあたりはデータ構造の話で自分にはまだわからないかなと思い、ひとまず解いていないです。
D あたりまでが安定してきたら次の学習として取り組みたいと思います。


# 感想
かなり苦しめられました。数学的な考察までは上手くいっても、TLE 出しまくりで。特に E問題は js の Array.sort のアルゴリズムに疑念を抱いて merge sort を実装してみてもなお TLE を吐き続けており、お手上げ状態です。c++ 人口がかなり多いように見えるので、 c++ で実装できるようになった方がいいんだろうなと思いました。ゲームの開発でも使うことになるでしょうから、次からは c++ で書いてみます。
