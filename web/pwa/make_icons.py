#!/usr/bin/env python3
"""Gera os ícones PWA do Echo Blade (arte original; só biblioteca padrão).

Desenho: anel ciano aberto (o "eco"/loop), anel tênue externo e uma lâmina dourada
que sai pela abertura, sobre fundo escuro. Saída determinística em web/pwa/. Uso:
    python web/pwa/make_icons.py
"""
import math
import os
import struct
import zlib

BG = (18, 18, 26)
CYAN = (79, 216, 255)
GOLD = (255, 209, 77)
SS = 3  # supersampling por eixo (antisserrilhado)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)
    t = max(0.0, min(1.0, t))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def sample(u, v, k):
    """Cor no ponto (u, v) em [0,1]; k = escala do desenho em torno do centro."""
    x = (u - 0.5) / k
    y = (v - 0.5) / k
    r = math.hypot(x, y)
    col = mix(BG, CYAN, max(0.0, 1.0 - r / 0.7) * 0.10)
    if abs(r - 0.40) <= 0.006:
        col = mix(col, CYAN, 0.45)
    # Anel aberto (o loop) com uma abertura a nordeste, por onde a lâmina sai.
    angle = math.atan2(-y, x)
    if abs(r - 0.30) <= 0.030 and abs(angle - math.pi / 4) > 0.42:
        col = CYAN
    if seg_dist(x, y, -0.13, 0.13, 0.30, -0.30) <= 0.026:
        col = GOLD
    return col


def render(size, k):
    rows = []
    n = SS * SS
    for j in range(size):
        row = bytearray([0])  # filtro PNG 0
        for i in range(size):
            r = g = b = 0.0
            for sj in range(SS):
                for si in range(SS):
                    c = sample((i + (si + 0.5) / SS) / size, (j + (sj + 0.5) / SS) / size, k)
                    r += c[0]
                    g += c[1]
                    b += c[2]
            row += bytes((round(r / n), round(g / n), round(b / n), 255))
        rows.append(bytes(row))
    return b"".join(rows)


def chunk(kind, data):
    body = kind + data
    return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def png(size, k):
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    idat = zlib.compress(render(size, k), 9)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")


def ico(images):
    header = struct.pack("<HHH", 0, 1, len(images))
    offset = 6 + 16 * len(images)
    entries = b""
    blobs = b""
    for size, data in images:
        entries += struct.pack("<BBBBHHII", size, size, 0, 0, 1, 32, len(data), offset)
        offset += len(data)
        blobs += data
    return header + entries + blobs


def main():
    out = os.path.dirname(os.path.abspath(__file__))
    files = {
        "icon-192.png": png(192, 1.0),
        "icon-512.png": png(512, 1.0),
        "icon-maskable-512.png": png(512, 0.8),  # área segura da máscara adaptativa
        "apple-touch-icon-180.png": png(180, 0.92),
        "favicon-32.png": png(32, 1.05),
        "favicon-48.png": png(48, 1.05),
    }
    files["favicon.ico"] = ico([(32, files["favicon-32.png"]), (48, files["favicon-48.png"])])
    for name, data in files.items():
        with open(os.path.join(out, name), "wb") as f:
            f.write(data)
        print(f"{name}: {len(data)} bytes")


if __name__ == "__main__":
    main()
