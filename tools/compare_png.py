"""Compara dos PNG del mismo tamaño y guarda un mapa de diferencias.

Uso: python3 -I tools/compare_png.py captura.png maqueta.png diferencias.png
Imprime el porcentaje de píxeles iguales (tolerancia de 8 por canal).
"""
import struct
import sys
import zlib


def read_png(path):
    data = open(path, "rb").read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    pos, idat = 8, b""
    while pos < len(data):
        length = struct.unpack(">I", data[pos:pos + 4])[0]
        kind, body = data[pos + 4:pos + 8], data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, color = struct.unpack(">IIBB", body[:10])
            assert depth == 8 and color in (2, 6), "solo PNG RGB/RGBA de 8 bits"
            bpp = 4 if color == 6 else 3
        elif kind == b"IDAT":
            idat += body
    raw, stride = zlib.decompress(idat), width * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(height):
        filt, line = raw[i], bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b, c = prev[x], prev[x - bpp] if x >= bpp else 0
            if filt == 1:
                line[x] = (line[x] + a) & 255
            elif filt == 2:
                line[x] = (line[x] + b) & 255
            elif filt == 3:
                line[x] = (line[x] + (a + b) // 2) & 255
            elif filt == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append([tuple(line[x * bpp:x * bpp + 3]) for x in range(width)])
        prev = line
    return width, height, rows


def write_png(path, width, height, rows):
    raw = b"".join(b"\x00" + bytes(v for px in row for v in px) for row in rows)
    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF)
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
                           + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


def main():
    capture, reference, out = sys.argv[1:4]
    w1, h1, a = read_png(capture)
    w2, h2, b = read_png(reference)
    assert (w1, h1) == (w2, h2), f"tamaños distintos: {w1}x{h1} vs {w2}x{h2}"
    same, diff_rows = 0, []
    for y in range(h1):
        row = []
        for x in range(w1):
            if max(abs(p - q) for p, q in zip(a[y][x], b[y][x])) <= 8:
                same += 1
                row.append(tuple(v // 3 for v in b[y][x]))
            else:
                row.append((255, 40, 40))
        diff_rows.append(row)
    write_png(out, w1, h1, diff_rows)
    print(f"Iguales: {100 * same / (w1 * h1):.1f} %  (mapa: {out})")


if __name__ == "__main__":
    main()
