#!/usr/bin/env python3
"""表示セル幅(全角=2, 半角=1)を基準に、常に一定幅のテキストを出す。
waybarのマーキー表示で、全角/半角混在によるガタつきを防ぐために使う。

引数: <text> <target_cells> <offset_chars>
出力: 1行目=表示するスライス(不足分は半角スペースで埋める)
      2行目=次回呼び出し用のoffset
"""
import sys
import unicodedata


def cell_width(ch: str) -> int:
    return 2 if unicodedata.east_asian_width(ch) in ("W", "F") else 1


def main() -> None:
    text = sys.argv[1]
    target = int(sys.argv[2])
    offset = int(sys.argv[3])

    total_w = sum(cell_width(c) for c in text)

    if total_w <= target:
        print(text + " " * (target - total_w))
        print(0)
        return

    loop_chars = list(text + "   ")
    n = len(loop_chars)
    offset %= n

    out = []
    w = 0
    i = offset
    for _ in range(n):
        ch = loop_chars[i % n]
        cw = cell_width(ch)
        if w + cw > target:
            out.append(" " * (target - w))
            break
        out.append(ch)
        w += cw
        i += 1
        if w >= target:
            break

    print("".join(out))
    print((offset + 1) % n)


if __name__ == "__main__":
    main()
