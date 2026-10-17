#!/usr/bin/env python3
"""UI 픽셀아트(9-슬라이스용 프레임, 버튼, 슬롯 등) 생성기.

외부 라이브러리 없이 PNG를 직접 씀. 아트 1픽셀 = 파일 2x2 픽셀 (SCALE).
실행: python3 dev/gen_ui_art.py  → static/ui/*.png
"""
import os
import struct
import zlib

SCALE = 2
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "static", "ui")

# 팔레트 (RGBA)
T    = (0, 0, 0, 0)
OUTL = (14, 10, 14, 255)      # 바깥 외곽선
GD   = (112, 74, 36, 255)     # 금 (어두움)
GM   = (198, 148, 66, 255)    # 금 (중간)
GL   = (248, 216, 140, 255)   # 금 (밝음)
INL  = (40, 30, 36, 255)      # 안쪽 경계
PF   = (22, 18, 28, 242)      # 판넬 채움
SD   = (64, 64, 72, 255)      # 비활성 테두리
SF   = (40, 40, 46, 255)      # 비활성 채움


def write_png(path, pixels):
    h = len(pixels) * SCALE
    w = len(pixels[0]) * SCALE
    raw = b""
    for row in pixels:
        line = b"\x00"
        for px in row:
            line += bytes(px) * SCALE
        raw += line * SCALE
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def canvas(w, h, fill=T):
    return [[fill for _ in range(w)] for _ in range(h)]


def rect(img, x0, y0, x1, y1, color):
    """테두리만 (x1, y1 포함)"""
    for x in range(x0, x1 + 1):
        img[y0][x] = color
        img[y1][x] = color
    for y in range(y0, y1 + 1):
        img[y][x0] = color
        img[y][x1] = color


def fill(img, x0, y0, x1, y1, color):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            img[y][x] = color


def panel():
    """큰 판넬: 금 테두리 + 베벨 + 모서리 장식"""
    n = 24
    img = canvas(n, n)
    fill(img, 0, 0, n - 1, n - 1, OUTL)
    rect(img, 1, 1, n - 2, n - 2, GD)
    # 베벨: 위/왼쪽 밝게, 아래/오른쪽 어둡게
    for i in range(2, n - 2):
        img[2][i] = GL
        img[i][2] = GL
        img[n - 3][i] = GM
        img[i][n - 3] = GM
    rect(img, 3, 3, n - 4, n - 4, GD)
    rect(img, 4, 4, n - 5, n - 5, INL)
    fill(img, 5, 5, n - 6, n - 6, PF)
    # 모서리 리벳
    for cx, cy in [(2, 2), (n - 4, 2), (2, n - 4), (n - 4, n - 4)]:
        fill(img, cx, cy, cx + 1, cy + 1, GL)
        img[cy + 1][cx + 1] = GM
    # 바깥 모서리 둥글게
    for cx, cy in [(0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)]:
        img[cy][cx] = T
    return img


def panel_small():
    """작은 판넬 (툴팁, 판 형태 HUD)"""
    n = 12
    img = canvas(n, n)
    fill(img, 0, 0, n - 1, n - 1, OUTL)
    rect(img, 1, 1, n - 2, n - 2, GD)
    for i in range(2, n - 2):
        img[1][i] = GM
    fill(img, 2, 2, n - 3, n - 3, (20, 16, 24, 225))
    for cx, cy in [(0, 0), (n - 1, 0), (0, n - 1), (n - 1, n - 1)]:
        img[cy][cx] = T
    return img


def button(border, body, top, bottom, edge_hi=None):
    """버튼: 둥근 모서리, 윗줄 하이라이트, 아랫줄 그림자"""
    w, h = 16, 12
    img = canvas(w, h)
    fill(img, 1, 0, w - 2, h - 1, OUTL)
    fill(img, 0, 1, w - 1, h - 2, OUTL)
    rect(img, 1, 1, w - 2, h - 2, border)
    fill(img, 2, 2, w - 3, h - 3, body)
    for x in range(2, w - 2):
        img[2][x] = top
        img[h - 3][x] = bottom
    if edge_hi:
        for x in range(2, w - 2):
            img[1][x] = edge_hi
    return img


def focus_ring():
    w, h = 16, 12
    img = canvas(w, h)
    rect(img, 1, 1, w - 2, h - 2, GL)
    img[1][1] = T
    img[1][w - 2] = T
    img[h - 2][1] = T
    img[h - 2][w - 2] = T
    return img


def slot(border, hi):
    n = 12
    img = canvas(n, n)
    fill(img, 0, 0, n - 1, n - 1, OUTL)
    rect(img, 1, 1, n - 2, n - 2, border)
    fill(img, 2, 2, n - 3, n - 3, (16, 13, 20, 255))
    for i in range(2, n - 2):
        img[2][i] = (30, 25, 36, 255)
        img[i][2] = (30, 25, 36, 255)
    img[1][1] = hi
    img[1][n - 2] = hi
    img[n - 2][1] = hi
    img[n - 2][n - 2] = hi
    return img


def grabber(light):
    """슬라이더 손잡이: 금 보석"""
    shape = [
        "...OO...",
        "..OLLO..",
        ".OLLMMO.",
        "OLLMMMDO",
        "OLMMMDDO",
        ".OMMDDO.",
        "..ODDO..",
        "...OO...",
    ]
    pal = {".": T, "O": OUTL, "L": GL if light else GM, "M": GM if light else (170, 120, 50, 255), "D": GD}
    return [[pal[c] for c in row] for row in shape]


def checkbox(checked):
    shape_off = [
        "OOOOOOOO",
        "ODDDDDDO",
        "OD....DO",
        "OD....DO",
        "OD....DO",
        "OD....DO",
        "ODDDDDDO",
        "OOOOOOOO",
    ]
    shape_on = [
        "OOOOOOOO",
        "OMMMMMMO",
        "OM...LLO",
        "OML.LLMO",
        "OMLLL.MO",
        "OM.L..MO",
        "OMMMMMMO",
        "OOOOOOOO",
    ]
    pal = {".": (16, 13, 20, 255), "O": OUTL, "D": GD, "M": GM, "L": GL}
    return [[pal[c] for c in row] for row in (shape_on if checked else shape_off)]


def bar_frame():
    """진행 바 테두리 (경험치/체력)"""
    w, h = 12, 8
    img = canvas(w, h)
    fill(img, 0, 0, w - 1, h - 1, OUTL)
    rect(img, 1, 1, w - 2, h - 2, GD)
    for x in range(2, w - 2):
        img[1][x] = GM
    fill(img, 2, 2, w - 3, h - 3, (12, 10, 16, 235))
    return img


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    arts = {
        "panel": panel(),
        "panel_small": panel_small(),
        "button_normal": button(GD, (44, 34, 50, 255), (66, 52, 72, 255), (30, 24, 34, 255)),
        "button_hover": button(GM, (70, 52, 70, 255), (98, 76, 90, 255), (44, 34, 50, 255), GL),
        "button_pressed": button(GM, (28, 22, 32, 255), (18, 14, 22, 255), (40, 32, 44, 255)),
        "button_disabled": button(SD, SF, (52, 52, 58, 255), (30, 30, 34, 255)),
        "button_focus": focus_ring(),
        "slot": slot(GD, GM),
        "slot_gold": slot(GL, (255, 245, 200, 255)),
        "slot_red": slot((220, 70, 70, 255), (255, 170, 160, 255)),
        "grabber": grabber(False),
        "grabber_hover": grabber(True),
        "check_off": checkbox(False),
        "check_on": checkbox(True),
        "bar_frame": bar_frame(),
    }
    for name, img in arts.items():
        write_png(os.path.join(OUT_DIR, name + ".png"), img)
        print("wrote", name)


if __name__ == "__main__":
    main()
