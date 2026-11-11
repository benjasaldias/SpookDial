"""Genera el arte de interfaz que dibuja Claude, en art/ui/ (PNG, pixel art, 1 píxel = 1 unidad de Godot).

Reemplaza a los dibujos provisionales hechos con rectángulos en Godot (sesión del 10 de noviembre):
- el mixer visto desde arriba de Audio Sync (el cuerpo y la perilla del fader; lo que se mueve lo dibuja Godot);
- el cuaderno universitario abierto (la hoja, las pestañas como notas adhesivas);
- la mancha de tinta del screamer del cuaderno (3 cuadros que salpican y los chorreones que caen);
- el marco del celular de Snapgram, la placa de las barras de arriba y las barras de señal de las entradas del PC;
- el marco y los botones del menú, la pausa y las pantallas del final de la noche;
- desde el Plan 9.3, el chat: los íconos de las preguntas y de sus estados, el cuaderno junto al nombre de la entidad,
  la señal del botón de sincronizar y las hojas de las respuestas.

Usa la paleta de los sprites de Benja (el mixer y el cuaderno del escritorio): colores planos, contorno negro de
1 px y sombreado simple. El arte de Benja no se toca. Benja puede retocar estos PNG en Aseprite, pero se pisan si se
vuelve a correr este script.

Uso, desde la carpeta del proyecto: /usr/bin/python3 tools/make_ui_art.py   (necesita Pillow y numpy)
"""
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "art" / "ui"


def rgb(code, alpha=255):
    return tuple(int(code[i:i + 2], 16) for i in (1, 3, 5)) + (alpha,)


# --- Paleta (sacada de mixer_sprite y notebook_sprite) --------------------------------------------------------------
BLACK = rgb("#000000")
NAVY = rgb("#191b30")          # el cuerpo del mixer
NAVY_LIGHT = rgb("#2b2f52")
NAVY_DEEP = rgb("#090a17")     # lo hundido
NAVY_DEEPER = rgb("#080914")
GRAY = rgb("#9ea3a9")          # el bisel y las perillas
GRAY_LIGHT = rgb("#d9d9d9")
GRAY_WARM = rgb("#98928c")
GRAY_MID = rgb("#8d8781")
GRAY_DARK = rgb("#6f6b67")
GRAY_DARKER = rgb("#625e5a")
SCREEN = rgb("#252f99")
SCREEN_TOP = rgb("#2b38b0")
SCREEN_MARK = rgb("#258199")
SCREEN_MARK_LIGHT = rgb("#5fc6d9")
RED = rgb("#cd3c3c")
RED_DARK = rgb("#851a1a")
RED_DEEP = rgb("#3f1313")
YELLOW = rgb("#f0ea67")
YELLOW_LIGHT = rgb("#fef769")
GREEN = rgb("#7bc846")
GREEN_LIGHT = rgb("#93d256")
BLUE = rgb("#5b6ee1")
ORANGE = rgb("#bf632e")
TEAL_DARK = rgb("#103344")
COVER = rgb("#0b2f26")         # la tapa del cuaderno
COVER_LIGHT = rgb("#135242")
COVER_DARK = rgb("#041410")
LABEL = rgb("#afcbba")
# El papel: más apagado que el blanco, porque el cuarto está a oscuras y lo ilumina la pantalla.
PAPER = rgb("#d6cfb8")
PAPER_SHADE = rgb("#c7bfa5")
PAPER_EDGE = rgb("#ada388")
# La cuadrícula, a medio camino entre el gris azulado del lápiz y el papel: más suave (pedido de Benja, 11 de noviembre).
GRID = rgb("#c3c5bb")
MARGIN = rgb("#c4545a")
PENCIL = rgb("#77747a")
HOLE = rgb("#2b261d")
WIRE = rgb("#3a3d44")
WIRE_LIGHT = rgb("#a9aeb5")
INK = rgb("#0b0a12")
INK_EDGE = rgb("#151325")
INK_SHINE = rgb("#2f2b4a")
POSTIT = rgb("#e2cf66")
POSTIT_LIGHT = rgb("#eedc84")
POSTIT_SHADE = rgb("#c1ab49")
POSTIT_PINK = rgb("#e39aae")
POSTIT_PINK_LIGHT = rgb("#efb3c3")
POSTIT_PINK_SHADE = rgb("#c27389")
POSTIT_EDGE = rgb("#3b3122")


# --- Herramientas de dibujo -----------------------------------------------------------------------------------------

def box(draw, x0, y0, x1, y1, fill=None, outline=None):
    """Rectángulo con las esquinas incluidas (x1 e y1 son el último píxel)."""
    draw.rectangle([x0, y0, x1, y1], fill=fill, outline=outline)


def disc(image, cx, cy, radius, color, clip=None):
    """Círculo lleno, píxel a píxel, centrado en el píxel (cx, cy). `clip(x, y)` puede excluir píxeles."""
    r = int(math.ceil(radius))
    for y in range(cy - r, cy + r + 1):
        for x in range(cx - r, cx + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius + radius * 0.8:
                if 0 <= x < image.width and 0 <= y < image.height and (clip is None or clip(x, y)):
                    image.putpixel((x, y), color)


def line(draw, points, color, width=1):
    draw.line(points, fill=color, width=width)


def stamp(image, x, y, rows, palette):
    """Dibuja un sprite chico escrito con letras: cada letra es un color de `palette` y '.' es transparente."""
    for dy, row in enumerate(rows):
        for dx, key in enumerate(row):
            if key != ".":
                image.putpixel((x + dx, y + dy), palette[key])


# Letras de 3×5 para los rótulos chicos que son parte del dibujo (no del juego): "VU".
TINY = {
    "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
    "U": ["#.#", "#.#", "#.#", "#.#", "###"],
}


def tiny_text(image, x, y, text, color):
    for char in text:
        stamp(image, x, y, TINY[char], {"#": color})
        x += 4


# --- El mixer ---------------------------------------------------------------------------------------------------------
# Las medidas son las de scripts/ui/mixer_view.gd: si cambian allá, hay que cambiarlas aquí.

MIXER_SIZE = (440, 430)
METERS = [(100, 36, 112, 72), (228, 36, 112, 72)]
KNOBS = [(52, 72), (388, 72)]
CHANNEL_LEFT, CHANNEL_TOP, CHANNEL_W, CHANNEL_H, CHANNEL_GAP = 92, 168, 76, 192, 12
FADER_TOP, FADER_HEIGHT = 52, 104
STEP_TOP = 140


def knob(image, cx, cy, radius, angle_deg=-40):
    """Una perilla vista desde arriba: sombra, borde estriado, la cara gris con su brillo y la marca roja."""
    disc(image, cx + 2, cy + 3, radius, NAVY_DEEP)
    disc(image, cx, cy, radius, BLACK)
    disc(image, cx, cy, radius - 1, GRAY_DARKER)
    for step in range(0, 360, 10):
        a = math.radians(step)
        for r in (radius - 2, radius - 3):
            x, y = cx + round(math.cos(a) * r), cy + round(math.sin(a) * r)
            image.putpixel((x, y), GRAY_MID if step % 20 == 0 else GRAY_DARK)
    top = radius * 0.7
    disc(image, cx, cy, top + 1, BLACK)
    disc(image, cx, cy, top, GRAY)
    disc(image, cx, cy, top, GRAY_LIGHT,
         clip=lambda x, y: (x - cx + 2) ** 2 + (y - cy + 2) ** 2 <= top * top and
         (x - cx - 2) ** 2 + (y - cy - 2) ** 2 > top * top)
    disc(image, cx, cy, top, GRAY_WARM,
         clip=lambda x, y: (x - cx - 2) ** 2 + (y - cy - 2) ** 2 <= top * top and
         (x - cx + 2) ** 2 + (y - cy + 2) ** 2 > top * top)
    draw = ImageDraw.Draw(image)
    a = math.radians(angle_deg - 90)
    end = (cx + round(math.cos(a) * (top - 2)), cy + round(math.sin(a) * (top - 2)))
    line(draw, [(cx, cy), end], RED_DARK, 2 if radius > 14 else 1)


def screw(image, cx, cy):
    disc(image, cx, cy, 2.5, BLACK)
    disc(image, cx, cy, 1.6, GRAY_MID)
    image.putpixel((cx - 1, cy - 1), GRAY_LIGHT)
    ImageDraw.Draw(image).line([(cx - 1, cy + 1), (cx + 1, cy - 1)], fill=GRAY_DARKER)


def vu_meter(image, x, y, w, h):
    """El marco y la cara de un VU-metro; la aguja la dibuja Godot desde la tapa de abajo."""
    draw = ImageDraw.Draw(image)
    box(draw, x - 2, y - 2, x + w + 1, y + h + 1, fill=BLACK)
    box(draw, x - 1, y - 1, x + w, y + h, outline=GRAY_DARK)
    box(draw, x, y, x + w - 1, y + h - 1, fill=GRAY)
    box(draw, x, y, x + w - 1, y, fill=GRAY_LIGHT)
    box(draw, x + 2, y + 2, x + w - 3, y + h - 3, fill=BLACK)
    box(draw, x + 3, y + 3, x + w - 4, y + h - 4, fill=SCREEN)
    box(draw, x + 3, y + 3, x + w - 4, y + 8, fill=SCREEN_TOP)
    pivot = (x + w // 2, y + h - 8)
    # El arco de la escala, y su tramo rojo al final.
    for step in range(0, 101):
        angle = math.radians(-50 + step)
        px = pivot[0] + round(math.sin(angle) * 46)
        py = pivot[1] - round(math.cos(angle) * 46)
        image.putpixel((px, py), RED if step > 75 else SCREEN_MARK)
    for index in range(9):
        angle = math.radians(-50 + index * 12.5)
        length = 6 if index % 2 == 0 else 3
        color = RED if index >= 7 else SCREEN_MARK_LIGHT
        for r in range(48, 48 + length):
            image.putpixel((pivot[0] + round(math.sin(angle) * r), pivot[1] - round(math.cos(angle) * r)), color)
    tiny_text(image, x + 6, y + h - 13, "VU", SCREEN_MARK)
    # La tapa negra de la aguja.
    disc(image, pivot[0], pivot[1] + 3, 9, BLACK, clip=lambda px, py: py <= y + h - 4)
    disc(image, pivot[0], pivot[1] + 3, 7.5, NAVY_DEEP, clip=lambda px, py: py <= y + h - 4)


def push_button(image, x, y, color, light):
    draw = ImageDraw.Draw(image)
    box(draw, x - 1, y - 1, x + 12, y + 12, fill=BLACK)
    box(draw, x, y, x + 11, y + 11, fill=GRAY)
    box(draw, x, y, x + 11, y, fill=GRAY_LIGHT)
    box(draw, x, y, x, y + 11, fill=GRAY_LIGHT)
    box(draw, x, y + 11, x + 11, y + 11, fill=GRAY_DARK)
    box(draw, x + 11, y, x + 11, y + 11, fill=GRAY_DARK)
    box(draw, x + 3, y + 3, x + 8, y + 8, fill=color)
    box(draw, x + 3, y + 3, x + 4, y + 3, fill=light)


def mixer_body():
    image = Image.new("RGBA", MIXER_SIZE, BLACK)
    draw = ImageDraw.Draw(image)
    w, h = MIXER_SIZE
    # La cara de arriba, el borde iluminado y el frente (el grosor del mixer, abajo).
    box(draw, 1, 1, w - 2, h - 9, fill=NAVY)
    box(draw, 1, 1, w - 2, 1, fill=NAVY_LIGHT)
    box(draw, 1, 1, 1, h - 9, fill=NAVY_LIGHT)
    box(draw, 1, h - 8, w - 2, h - 2, fill=NAVY_DEEP)
    box(draw, 1, h - 8, w - 2, h - 8, fill=BLACK)
    box(draw, 2, h - 7, w - 3, h - 7, fill=NAVY_LIGHT)
    # El bisel gris, como en el mixer del escritorio.
    box(draw, 5, 5, w - 6, h - 14, outline=GRAY)
    box(draw, 6, 6, w - 7, h - 15, outline=NAVY_DEEP)
    for cx, cy in ((12, 12), (w - 13, 12), (12, h - 21), (w - 13, h - 21)):
        screw(image, cx, cy)
    # El marco del LED de arriba.
    box(draw, 407, 13, 420, 26, fill=BLACK)
    box(draw, 408, 14, 419, 25, fill=GRAY_DARK)
    for cx, cy in KNOBS:
        knob(image, cx, cy, 24)
    for meter in METERS:
        vu_meter(image, *meter)
    # La ranura de las luces de ritmo (hasta 8 luces de 10 px con 4 de separación, centradas).
    box(draw, 162, STEP_TOP - 4, 278, STEP_TOP + 18, fill=BLACK)
    box(draw, 163, STEP_TOP - 3, 277, STEP_TOP + 17, fill=NAVY_DEEP)
    box(draw, 163, STEP_TOP + 17, 277, STEP_TOP + 17, fill=NAVY_LIGHT)
    # Los tres canales: un panel hundido con la ranura del fader y sus marcas.
    for index in range(3):
        x = CHANNEL_LEFT + index * (CHANNEL_W + CHANNEL_GAP)
        y = CHANNEL_TOP
        box(draw, x, y, x + CHANNEL_W - 1, y + CHANNEL_H - 1, fill=BLACK)
        box(draw, x + 1, y + 1, x + CHANNEL_W - 2, y + CHANNEL_H - 2, fill=NAVY_DEEPER)
        box(draw, x + 2, y + 2, x + CHANNEL_W - 3, y + CHANNEL_H - 3, fill=rgb("#121427"))
        box(draw, x + 2, y + CHANNEL_H - 3, x + CHANNEL_W - 3, y + CHANNEL_H - 3, fill=NAVY_LIGHT)
        cx = x + CHANNEL_W // 2
        top, bottom = y + FADER_TOP, y + FADER_TOP + FADER_HEIGHT
        box(draw, cx - 3, top - 2, cx + 2, bottom + 2, fill=BLACK)
        box(draw, cx - 1, top, cx, bottom, fill=NAVY_DEEP)
        for mark in range(6):
            my = round(top + mark * FADER_HEIGHT / 5)
            length = 6 if mark in (0, 5) else 4
            box(draw, cx - 9 - length, my, cx - 9, my, fill=GRAY_DARK)
            box(draw, cx + 8, my, cx + 8 + length, my, fill=GRAY_DARK)
        # El fondo del número de la señal.
        box(draw, x + 14, y + CHANNEL_H - 24, x + CHANNEL_W - 15, y + CHANNEL_H - 9, fill=BLACK)
        box(draw, x + 15, y + CHANNEL_H - 23, x + CHANNEL_W - 16, y + CHANNEL_H - 10, fill=NAVY_DEEP)
    # Adornos: botones de colores a la izquierda, barras de colores a la derecha y perillas chicas.
    colors = [(RED, rgb("#e46a6a")), (YELLOW, YELLOW_LIGHT), (GREEN, GREEN_LIGHT)]
    for row in range(3):
        for column in range(3):
            push_button(image, 26 + column * 18, 196 + row * 22, *colors[column])
    for row, (color, light) in enumerate([(GREEN, GREEN_LIGHT), (YELLOW, YELLOW_LIGHT), (BLUE, rgb("#8392ec")),
                                          (ORANGE, rgb("#d9844f"))]):
        box(draw, 365, 199 + row * 12, 414, 206 + row * 12, fill=BLACK)
        box(draw, 366, 200 + row * 12, 413, 205 + row * 12, fill=color)
        box(draw, 366, 200 + row * 12, 413, 200 + row * 12, fill=light)
    for cx, cy in ((44, 300), (70, 334), (370, 300), (396, 334)):
        knob(image, cx, cy, 11, angle_deg=random.Random(cx + cy).randint(-130, 130))
    # La pantalla del estado, abajo.
    box(draw, 22, 379, 417, 401, fill=BLACK)
    box(draw, 23, 380, 416, 400, outline=GRAY_DARK)
    box(draw, 24, 381, 415, 399, fill=rgb("#07121a"))
    box(draw, 24, 381, 415, 381, fill=TEAL_DARK)
    # El garabato del logo, como en el mixer del escritorio.
    for k in range(40):
        lx = 352 + k
        ly = 366 + round(3 * math.sin(k / 3.2)) + (1 if k > 20 else 0)
        box(draw, lx, ly, lx, ly + 1, fill=NAVY_LIGHT)
    return image


def mixer_fader_cap():
    """La perilla de un fader: Godot la sube o la baja según la señal del amigo."""
    image = Image.new("RGBA", (30, 13), BLACK)
    draw = ImageDraw.Draw(image)
    box(draw, 1, 1, 28, 10, fill=GRAY)
    box(draw, 1, 1, 28, 2, fill=GRAY_LIGHT)
    box(draw, 1, 9, 28, 10, fill=GRAY_DARK)
    box(draw, 1, 5, 28, 6, fill=BLACK)
    box(draw, 1, 11, 28, 11, fill=NAVY_DEEP)
    box(draw, 0, 12, 29, 12, fill=(0, 0, 0, 0))
    return image


# --- El cuaderno ----------------------------------------------------------------------------------------------------
# La hoja mide lo mismo que Page en scenes/ui/notebook_panel.tscn (449×696).

PAGE_SIZE = (449, 696)
PAPER_BOX = (14, 4, 441, 686)
MARGIN_X = 50
GRID_STEP = 11


def checker(x, y):
    return (x + y) % 2 == 0


def notebook_page():
    image = Image.new("RGBA", PAGE_SIZE, BLACK)
    draw = ImageDraw.Draw(image)
    w, h = PAGE_SIZE
    # La tapa verde, que asoma alrededor de la hoja.
    box(draw, 1, 1, w - 2, h - 2, fill=COVER)
    box(draw, 1, 1, w - 2, 1, fill=COVER_LIGHT)
    box(draw, w - 2, 1, w - 2, h - 2, fill=COVER_DARK)
    box(draw, 1, h - 2, w - 2, h - 2, fill=COVER_DARK)
    x0, y0, x1, y1 = PAPER_BOX
    # Las hojas de abajo, corridas.
    box(draw, x0 + 2, y0 + 2, x1 + 3, y1 + 4, fill=PAPER_EDGE)
    box(draw, x0 + 1, y0 + 1, x1 + 1, y1 + 2, fill=PAPER_SHADE)
    box(draw, x0, y0, x1, y1, fill=PAPER)
    # La cuadrícula y el margen rojo.
    for gx in range(x0 + 3, x1, GRID_STEP):
        box(draw, gx, y0 + 1, gx, y1 - 1, fill=GRID)
    for gy in range(y0 + 8, y1, GRID_STEP):
        box(draw, x0 + 1, gy, x1 - 1, gy, fill=GRID)
    box(draw, MARGIN_X, y0, MARGIN_X, y1, fill=MARGIN)
    # El papel envejecido en los bordes, con un tramado de 2 tonos.
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            edge = min(x1 - x, y1 - y, y - y0)
            if edge < 2 or (edge < 5 and checker(x, y)):
                image.putpixel((x, y), PAPER_SHADE)
    box(draw, x0, y0, x1, y0, fill=PAPER_EDGE)
    box(draw, x1, y0, x1, y1, fill=PAPER_EDGE)
    box(draw, x0, y1, x1, y1, fill=PAPER_EDGE)
    # La esquina doblada, abajo a la derecha.
    for k in range(12):
        for j in range(12 - k):
            image.putpixel((x1 - j, y1 - k), COVER if j + k < 10 else PAPER_EDGE)
    for k in range(11):
        image.putpixel((x1 - 11 + k, y1 - k), PAPER_EDGE)
        if k < 10:
            image.putpixel((x1 - 10 + k, y1 - k), PAPER_SHADE)
    coffee_stain(image, x1 - 26, y1 - 52)
    pencil_doodles(image)
    spiral(image)
    return image


def coffee_stain(image, cx, cy):
    """El anillo de una taza de café: un borde más oscuro, abierto en un tramo, y el interior apenas teñido."""
    stain = rgb("#a58658")
    inner = rgb("#cdbb98")
    rng = random.Random(7)
    for y in range(cy - 26, cy + 27):
        for x in range(cx - 26, cx + 27):
            if not (0 <= x < image.width and 0 <= y < image.height):
                continue
            here = image.getpixel((x, y))
            if here[:3] not in (PAPER[:3], PAPER_SHADE[:3], GRID[:3]):
                continue
            d = math.hypot(x - cx, y - cy)
            angle = math.degrees(math.atan2(y - cy, x - cx)) % 360
            wobble = 22 + 1.2 * math.sin(math.radians(angle * 3))
            if wobble - 1.5 <= d <= wobble + 0.6 and not 200 < angle < 245:
                image.putpixel((x, y), stain)
            elif d < wobble - 1.5 and checker(x, y) and rng.random() < 0.35:
                image.putpixel((x, y), inner)


def pencil_doodles(image):
    """Garabatos a lápiz en el margen izquierdo: una estrella, un ojo y unas rayas, como de alguien que espera."""
    star = [
        "....#....",
        "....#....",
        "...###...",
        "#########",
        ".#######.",
        "..#####..",
        "..##.##..",
        ".##...##.",
        "#.......#",
    ]
    eye = [
        "...#####...",
        ".##.....##.",
        "#...###...#",
        "#..#####..#",
        "#...###...#",
        ".##.....##.",
        "...#####...",
    ]
    stamp(image, 31, 90, star, {"#": PENCIL})
    stamp(image, 30, 520, eye, {"#": PENCIL})
    for k in range(4):
        box(ImageDraw.Draw(image), 33 + k * 3, 300, 33 + k * 3, 306, fill=PENCIL)
    ImageDraw.Draw(image).line([(31, 307), (45, 299)], fill=PENCIL)


def spiral(image):
    """La espiral a la izquierda: un agujero en la hoja por vuelta y el alambre que pasa por encima."""
    draw = ImageDraw.Draw(image)
    for cy in range(16, PAGE_SIZE[1] - 12, 14):
        box(draw, 21, cy - 2, 24, cy + 2, fill=HOLE)
        box(draw, 21, cy - 2, 24, cy - 2, fill=BLACK)
        # El alambre: sale de la tapa, sube por encima del borde y entra al agujero.
        draw.arc([2, cy - 5, 24, cy + 5], 180, 360, fill=BLACK, width=4)
        draw.arc([3, cy - 4, 23, cy + 4], 185, 355, fill=WIRE, width=2)
        draw.arc([4, cy - 4, 22, cy + 3], 210, 290, fill=WIRE_LIGHT, width=1)


def postit(fill, light, shade):
    """Una nota adhesiva para las pestañas del índice (textura 9-slice de 20×18, márgenes de 4)."""
    image = Image.new("RGBA", (20, 18), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    box(draw, 0, 0, 19, 16, fill=POSTIT_EDGE)
    box(draw, 1, 1, 18, 15, fill=fill)
    box(draw, 1, 1, 18, 2, fill=light)
    box(draw, 1, 13, 18, 15, fill=shade)
    box(draw, 1, 17, 19, 17, fill=rgb("#000000", 90))
    box(draw, 19, 1, 19, 17, fill=rgb("#000000", 90))
    return image


# --- La mancha de tinta ---------------------------------------------------------------------------------------------
# Mide lo mismo que InkBlot en scenes/ui/notebook_panel.tscn (417×594).

INK_SIZE = (417, 594)


def ink_blobs():
    """Las gotas que forman la mancha: (x, y, radio), en fracciones del ancho. Siempre las mismas."""
    rng = random.Random(23)
    w, h = INK_SIZE
    blobs = []
    for cx, cy, r in ((0.5, 0.3, 0.23), (0.47, 0.5, 0.27), (0.53, 0.7, 0.23), (0.33, 0.42, 0.15), (0.66, 0.56, 0.15),
                      (0.4, 0.78, 0.14)):
        blobs.append((cx * w, cy * h, r * w))
        for _ in range(7):
            angle = rng.uniform(0, 2 * math.pi)
            distance = rng.uniform(0.6, 1.1) * r * w
            blobs.append((cx * w + math.cos(angle) * distance, cy * h + math.sin(angle) * distance,
                          rng.uniform(0.25, 0.5) * r * w))
    # Brazos que salen del centro, como cuando una gota cae con fuerza: gotas cada vez más chicas en una línea.
    for k in range(15):
        angle = 2 * math.pi * k / 15 + rng.uniform(-0.15, 0.15)
        reach = rng.uniform(1.05, 1.4)
        for t in np.linspace(0.8, reach, 7):
            fraction = (t - 0.8) / (reach - 0.8)
            blobs.append((0.5 * w + math.cos(angle) * t * 0.31 * w, 0.5 * h + math.sin(angle) * t * 0.37 * h,
                          (0.05 - 0.036 * fraction) * w))
    return blobs


def ink_droplets():
    """Las salpicaduras sueltas alrededor: (x, y, radio, largo, ángulo). Las más lejanas son más chicas."""
    rng = random.Random(41)
    w, h = INK_SIZE
    center = (0.5 * w, 0.5 * h)
    drops = []
    for _ in range(46):
        angle = rng.uniform(0, 2 * math.pi)
        reach = rng.uniform(0.32, 0.5)
        x = center[0] + math.cos(angle) * reach * w * 1.05
        y = center[1] + math.sin(angle) * reach * h * 0.95
        size = rng.uniform(1.5, 6.0) * (1.2 - reach)
        drops.append((x, y, size, rng.uniform(1.0, 3.2), angle))
    return drops


def ink_mask(scale):
    """La mancha a `scale` de su tamaño final, como un campo de gotas que se funden (metaballs)."""
    w, h = INK_SIZE
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float64)
    field = np.zeros((h, w))
    cx, cy = 0.5 * w, 0.5 * h
    for bx, by, r in ink_blobs():
        bx, by, r = cx + (bx - cx) * scale, cy + (by - cy) * scale, r * scale
        # Cada gota aporta (1 - (d / 1.6r)²)³ y se apaga a 1,6 radios: así las vecinas se funden sin inflarse.
        falloff = np.clip(1 - ((xs - bx) ** 2 + (ys - by) ** 2) / (1.6 * r) ** 2, 0, None)
        field += falloff ** 3
    mask = field > 0.25
    for x, y, size, stretch, angle in ink_droplets():
        x, y = cx + (x - cx) * scale, cy + (y - cy) * scale
        dx, dy = xs - x, ys - y
        along = dx * math.cos(angle) + dy * math.sin(angle)
        across = -dx * math.sin(angle) + dy * math.cos(angle)
        mask |= (along / (size * stretch * max(scale, 0.4))) ** 2 + (across / (size * max(scale, 0.4))) ** 2 <= 1
    return mask


def paint_ink(mask):
    """Pinta la tinta: el cuerpo, un borde algo más claro (la tinta que se seca) y brillos de lo mojado."""
    h, w = mask.shape
    image = np.zeros((h, w, 4), dtype=np.uint8)
    image[mask] = INK
    inner = mask.copy()
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        inner &= np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
    image[mask & ~inner] = INK_EDGE
    # Brillo: donde la gota mira hacia arriba a la izquierda, a 3 píxeles del borde.
    shifted = np.roll(np.roll(mask, 4, axis=0), 4, axis=1)
    far = np.roll(np.roll(mask, 6, axis=0), 6, axis=1)
    shine = inner & ~shifted & far
    image[shine] = INK_SHINE
    return Image.fromarray(image, "RGBA")


def ink_drips():
    """Los chorreones que caen de la mancha: Godot los descubre de a poco, de arriba hacia abajo."""
    w, h = INK_SIZE
    full = ink_mask(1.0)
    image = np.zeros((h, w, 4), dtype=np.uint8)
    rng = random.Random(5)
    for fraction in (0.33, 0.41, 0.52, 0.6, 0.68):
        x = int(fraction * w)
        column = np.nonzero(full[:, x])[0]
        if len(column) == 0:
            continue
        top = column.max() - 10
        length = rng.randint(30, 110)
        half = rng.randint(2, 4)
        bottom = min(h - 8, top + length)
        for y in range(top, bottom):
            wiggle = round(math.sin(y / 9.0 + fraction * 10) * 0.8)
            image[y, x - half + wiggle:x + half + 1 + wiggle] = INK
            image[y, x - half + wiggle] = INK_EDGE
        bulb = half + 2
        for y in range(bottom - bulb, bottom + bulb + 1):
            for xx in range(x - bulb, x + bulb + 1):
                if (xx - x) ** 2 + (y - bottom) ** 2 <= bulb * bulb + bulb:
                    image[y, xx] = INK
        image[bottom - 1, x - 1] = INK_SHINE
    return Image.fromarray(image, "RGBA")


# --- El celular ampliado -------------------------------------------------------------------------------------------
# Mide lo mismo que PhoneView (260×520). La pantalla va de (14, 18) a (246, 496): ahí dibuja Godot.

PHONE_SIZE = (260, 520)
CASE = rgb("#26365a")          # una versión oscura del azul del celular del escritorio (phone_sprite)
CASE_LIGHT = rgb("#4c6ba7")
CASE_SHINE = rgb("#c2d5ed")
CASE_DARK = rgb("#151e33")


def rounded(image, x0, y0, x1, y1, radius, color):
    """Rectángulo lleno con las esquinas redondeadas, píxel a píxel."""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            cx = min(max(x, x0 + radius), x1 - radius)
            cy = min(max(y, y0 + radius), y1 - radius)
            if (x - cx) ** 2 + (y - cy) ** 2 <= radius * radius + radius * 0.6:
                image.putpixel((x, y), color)


def phone_frame():
    image = Image.new("RGBA", PHONE_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    w, h = PHONE_SIZE
    # Los botones de los lados: el volumen a la izquierda y el de encendido a la derecha.
    for y0, y1 in ((96, 124), (132, 160)):
        box(draw, 0, y0, 3, y1, fill=BLACK)
        box(draw, 1, y0 + 1, 3, y1 - 1, fill=CASE_LIGHT)
    box(draw, w - 4, 118, w - 1, 162, fill=BLACK)
    box(draw, w - 4, 119, w - 2, 161, fill=CASE_LIGHT)
    rounded(image, 2, 0, w - 3, h - 1, 20, BLACK)
    rounded(image, 3, 1, w - 4, h - 2, 19, CASE_DARK)
    rounded(image, 3, 1, w - 5, h - 3, 19, CASE)
    rounded(image, 5, 3, w - 6, h - 5, 17, CASE_LIGHT)
    rounded(image, 6, 4, w - 6, h - 5, 16, CASE)
    # Un brillo en el borde de arriba a la izquierda.
    for k in range(40):
        image.putpixel((24 + k, 4), CASE_SHINE if k < 30 else CASE_LIGHT)
    for k in range(30):
        image.putpixel((6, 26 + k), CASE_SHINE if k < 20 else CASE_LIGHT)
    # El vidrio negro alrededor de la pantalla, el parlante y la cámara.
    rounded(image, 9, 11, w - 10, h - 13, 12, BLACK)
    box(draw, 108, 5, 151, 8, fill=BLACK)
    box(draw, 109, 6, 150, 7, fill=CASE_DARK)
    for x in range(111, 149, 3):
        image.putpixel((x, 6), CASE_LIGHT)
    disc(image, 158, 7, 2.2, BLACK)
    image.putpixel((157, 6), CASE_SHINE)
    return image


# --- Las barras de arriba -------------------------------------------------------------------------------------------
# Miden lo mismo que StatBars (300×54); las medidas de las filas son las de scripts/ui/stat_bars.gd.

def hud_bars():
    """La placa de las barras de arriba: 320 px de ancho, para que los nombres quepan con la letra de 1080p (Plan 9.2)."""
    image = Image.new("RGBA", (320, 54), BLACK)
    draw = ImageDraw.Draw(image)
    box(draw, 1, 1, 318, 52, fill=NAVY)
    box(draw, 1, 1, 318, 1, fill=NAVY_LIGHT)
    box(draw, 1, 1, 1, 52, fill=NAVY_LIGHT)
    box(draw, 1, 52, 318, 52, fill=NAVY_DEEP)
    for row in range(3):
        top = 5 + row * 16
        box(draw, 112, top, 297, top + 11, fill=BLACK)
        box(draw, 113, top + 1, 296, top + 10, fill=NAVY_DEEPER)
        box(draw, 112, top + 11, 297, top + 11, fill=NAVY_LIGHT)
        # El marco de la luz de alerta: Godot la dibuja en (303, top + 2), de 8×8.
        box(draw, 301, top, 312, top + 11, fill=GRAY_DARK)
        box(draw, 302, top + 1, 311, top + 10, fill=BLACK)
    return image


def signal_bars():
    """Las barras de señal de una entrada del PC: 6 cuadros de 19×12, de 0 a 5 barras. Las llenas son claras y con
    sombra; las vacías, solo el borde. Sin señal, además, hay una x: no depende del color."""
    frame_w, frame_h = 19, 12
    image = Image.new("RGBA", (frame_w * 6, frame_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    full, shade, empty = rgb("#e8eefc"), rgb("#0d1430"), rgb("#9aa6d6")
    for frame in range(6):
        left = frame * frame_w
        for bar in range(5):
            x = left + bar * 4
            top = frame_h - 1 - (4 + bar * 2) + 1
            if bar < frame:
                box(draw, x + 1, top + 1, x + 3, frame_h - 1, fill=shade)
                box(draw, x, top, x + 2, frame_h - 2, fill=full)
            else:
                box(draw, x, top, x + 2, frame_h - 2, outline=empty)
        if frame == 0:
            for k in range(4):
                image.putpixel((left + k, k), full)
                image.putpixel((left + 3 - k, k), full)
    return image


# --- El menú, la pausa y el final de la noche -----------------------------------------------------------------------

def menu_frame():
    """El marco de los menús (textura 9-slice de 48×48, márgenes de 12): la placa del mixer, con su bisel y sus
    tornillos."""
    image = Image.new("RGBA", (48, 48), BLACK)
    draw = ImageDraw.Draw(image)
    box(draw, 1, 1, 46, 46, fill=NAVY)
    box(draw, 1, 1, 46, 1, fill=NAVY_LIGHT)
    box(draw, 1, 1, 1, 46, fill=NAVY_LIGHT)
    box(draw, 4, 4, 43, 43, outline=GRAY)
    box(draw, 5, 5, 42, 42, outline=NAVY_DEEP)
    box(draw, 2, 46, 46, 46, fill=NAVY_DEEP)
    box(draw, 46, 2, 46, 46, fill=NAVY_DEEP)
    for cx, cy in ((8, 8), (39, 8), (8, 39), (39, 39)):
        screw(image, cx, cy)
    return image


def menu_button(state):
    """Un botón de aparato (textura 9-slice de 32×20, márgenes de 5): normal, al pasar el mouse o apretado."""
    image = Image.new("RGBA", (32, 20), BLACK)
    draw = ImageDraw.Draw(image)
    if state == "pressed":
        box(draw, 1, 1, 30, 18, fill=NAVY_DEEP)
        box(draw, 1, 1, 30, 2, fill=NAVY_DEEPER)
        box(draw, 2, 17, 29, 17, fill=NAVY_LIGHT)
        return image
    box(draw, 1, 1, 30, 18, fill=NAVY_LIGHT)
    box(draw, 1, 1, 30, 1, fill=rgb("#3d4373"))
    box(draw, 1, 16, 30, 18, fill=NAVY_DEEP)
    box(draw, 1, 15, 30, 15, fill=rgb("#20233f"))
    if state == "hover":
        box(draw, 1, 1, 30, 18, outline=SCREEN_MARK_LIGHT)
    return image


# --- Todo junto -----------------------------------------------------------------------------------------------------

# Las marcas de la tabla de reglas del cuaderno (Plan 9.2): ✓ la acción correcta, ✗ las incorrectas y una calavera la de
# mayor riesgo. 9×9, en el lápiz pasta de la página: verde, gris y rojo.
MARKS = {
    "mark_check": ("#1d5a2c", [
        ".........",
        "........#",
        ".......##",
        "......##.",
        "#....##..",
        "##..##...",
        ".####....",
        "..##.....",
        ".........",
    ]),
    "mark_cross": ("#5c6470", [
        ".........",
        ".#.....#.",
        ".##...##.",
        "..##.##..",
        "...###...",
        "..##.##..",
        ".##...##.",
        ".#.....#.",
        ".........",
    ]),
    "mark_risk": ("#a32222", [
        "..#####..",
        ".#######.",
        "#..###..#",
        "#..###..#",
        "####.####",
        ".#######.",
        "..#.#.#..",
        "..#.#.#..",
        ".........",
    ]),
}


def mark(color, rows):
    """Una marca de la tabla del cuaderno, píxel a píxel."""
    image = Image.new("RGBA", (len(rows[0]), len(rows)), (0, 0, 0, 0))
    stamp(image, 0, 0, [row.replace("#", "a") for row in rows], {"a": rgb(color)})
    return image


# --- El chat (Plan 9.3) ---------------------------------------------------------------------------------------------
# Cada control del chat con su forma (pedido de Benja tras el primer testeo): las preguntas con un ícono por categoría y
# su estado, el cuaderno junto al nombre de la entidad, la señal del amigo en el botón de sincronizar y las respuestas
# como hojas del cuaderno.

# Los íconos de las preguntas, de 9×9 y en blanco: el botón les da el color de su letra. Ojo, parlante (la oreja no se
# lee a este tamaño), nube con niebla y huella de una pata.
QUESTION_ICONS = {
    "chat_icon_sight": [
        ".........",
        "...###...",
        ".##...##.",
        "#..###..#",
        "#..###..#",
        "#..###..#",
        ".##...##.",
        "...###...",
        ".........",
    ],
    "chat_icon_sound": [
        ".........",
        "...#...#.",
        "..##.#..#",
        "####..#.#",
        "####..#.#",
        "####..#.#",
        "..##.#..#",
        "...#...#.",
        ".........",
    ],
    "chat_icon_environment": [
        ".........",
        "...##....",
        "..####.#.",
        ".#######.",
        ".########",
        "#########",
        ".#######.",
        ".........",
        "##.###.##",
    ],
    "chat_icon_traces": [
        "..##.##..",
        "..##.##..",
        "##.....##",
        "##.....##",
        "...###...",
        "..#####..",
        ".#######.",
        ".#######.",
        "..##.##..",
    ],
}

# Los estados de una pregunta, de 9×9: ✓ verde (ya se preguntó y llegó entera) y estática (llegó tapada: se puede repetir).
STATE_ICONS = {
    "chat_icon_check": ({"a": rgb("#7ee08a")}, [
        ".........",
        "........a",
        ".......aa",
        "......aa.",
        "a....aa..",
        "aa..aa...",
        ".aaaa....",
        "..aa.....",
        ".........",
    ]),
    "chat_icon_static": ({"a": rgb("#8b97b8"), "b": rgb("#56637f")}, [
        "a.b.a.b.a",
        ".b.a.b.b.",
        "b.a.b.a.b",
        ".a.b.a.a.",
        "b.b.a.b.a",
        ".a.a.b.b.",
        "a.b.b.a.b",
        ".b.a.b.a.",
        "b.a.b.a.b",
    ]),
}

# El cuaderno junto al nombre de la entidad (11×11): la tapa verde con su etiqueta, la espiral y el canto de las hojas.
NOTEBOOK_ICON = ({
    "s": WIRE_LIGHT, "k": BLACK, "c": COVER_LIGHT, "d": COVER, "g": rgb("#2f8f62"), "l": LABEL, "p": PAPER,
}, [
    ".kkkkkkkkk.",
    "skggggggckp",
    ".kgcccccckp",
    "skgclllcckp",
    ".kgcccccckp",
    "skgccccccdp",
    ".kgccccccdp",
    "skgccccccdp",
    ".kgcccccddp",
    "skdddddddkp",
    ".kkkkkkkkpp",
])

# La señal del botón de sincronizar: 4 barritas de 3 px, de 3, 6, 9 y 12 de alto. Verdes con 70 o más, ámbar entre 30
# y 69 y rojas bajo 30, como los tramos de la estática.
SIGNAL_FRAME = (15, 12)
SIGNAL_COLORS = [
    (rgb("#7ee08a"), rgb("#1d5a2c")),
    (rgb("#ffb347"), rgb("#6e4410")),
    (rgb("#ff4d5e"), rgb("#5e1620")),
]
SIGNAL_EMPTY = rgb("#56637f")


def chat_signal():
    """5 cuadros (de 0 a 4 barritas) en 3 filas de color. Las llenas tienen sombra; las vacías, solo el borde. Sin señal
    hay una ×, para que no dependa del color."""
    w, h = SIGNAL_FRAME
    image = Image.new("RGBA", (w * 5, h * 3), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    for row, (fill, shade) in enumerate(SIGNAL_COLORS):
        for frame in range(5):
            left, top = frame * w, row * h
            for bar in range(4):
                x0 = left + bar * 4
                y0 = top + h - 3 * (bar + 1)
                if bar < frame:
                    box(draw, x0 + 1, y0 + 1, min(x0 + 3, left + w - 1), top + h - 1, fill=shade)
                    box(draw, x0, y0, x0 + 2, top + h - 2, fill=fill)
                else:
                    box(draw, x0, y0, x0 + 2, top + h - 2, outline=SIGNAL_EMPTY)
            if frame == 0:
                # La ×, en la esquina de arriba a la izquierda, donde no hay barritas.
                for k in range(5):
                    image.putpixel((left + k, top + k), fill)
                    image.putpixel((left + 4 - k, top + k), fill)
    return image


# Las respuestas son hojas del cuaderno: textura 9-slice de 19×19 con márgenes de 4. El centro (11×11) se repite como
# la cuadrícula de la hoja; el borde de abajo y el de la derecha llevan la sombra del papel.
SHEET_SIZE = 19
SHEET_MARGIN = 4
SHEETS = {
    "normal": {"paper": PAPER, "grid": GRID, "edge": POSTIT_EDGE, "shade": PAPER_EDGE, "light": None},
    "hover": {"paper": rgb("#e6e0cb"), "grid": rgb("#cfd0c6"), "edge": rgb("#ffb347"), "shade": PAPER_SHADE,
              "light": rgb("#f3eedd")},
    "pressed": {"paper": PAPER_SHADE, "grid": rgb("#b5b6ab"), "edge": POSTIT_EDGE, "shade": None, "light": None},
    "disabled": {"paper": rgb("#7d786b"), "grid": rgb("#737065"), "edge": rgb("#2a251b"), "shade": rgb("#6a6559"),
                 "light": None},
}


def answer_sheet(state):
    """Una hoja de respuesta: el papel con su cuadrícula, el borde y la sombra. Apretada, la sombra queda arriba."""
    colors = SHEETS[state]
    size, margin = SHEET_SIZE, SHEET_MARGIN
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    box(draw, 0, 0, size - 1, size - 1, fill=colors["edge"])
    box(draw, 1, 1, size - 2, size - 2, fill=colors["paper"])
    # La cuadrícula: una línea en la primera columna y la primera fila del centro, que se repiten.
    box(draw, margin, 1, margin, size - 2, fill=colors["grid"])
    box(draw, 1, margin, size - 2, margin, fill=colors["grid"])
    if colors["shade"] is not None:
        box(draw, 1, size - 2, size - 2, size - 2, fill=colors["shade"])
        box(draw, size - 2, 1, size - 2, size - 2, fill=colors["shade"])
    if colors["light"] is not None:
        box(draw, 1, 1, size - 3, 1, fill=colors["light"])
        box(draw, 1, 1, 1, size - 3, fill=colors["light"])
    if state == "pressed":
        box(draw, 1, 1, size - 2, 1, fill=PAPER_EDGE)
        box(draw, 1, 1, 1, size - 2, fill=PAPER_EDGE)
    return image


def chat_art():
    """Todo el arte del chat, como {nombre: imagen}."""
    art = {}
    for name, rows in QUESTION_ICONS.items():
        image = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
        stamp(image, 0, 0, rows, {"#": rgb("#ffffff")})
        art[name] = image
    for name, (palette, rows) in STATE_ICONS.items():
        image = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
        stamp(image, 0, 0, rows, palette)
        art[name] = image
    palette, rows = NOTEBOOK_ICON
    image = Image.new("RGBA", (11, 11), (0, 0, 0, 0))
    stamp(image, 0, 0, rows, palette)
    art["chat_icon_notebook"] = image
    art["chat_signal"] = chat_signal()
    for state in SHEETS:
        art[f"chat_answer_{state}"] = answer_sheet(state)
    return art


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    mixer_body().save(OUT / "mixer_body.png")
    mixer_fader_cap().save(OUT / "mixer_fader_cap.png")
    notebook_page().save(OUT / "notebook_page.png")
    for name, (color, rows) in MARKS.items():
        mark(color, rows).save(OUT / f"{name}.png")
    postit(POSTIT, POSTIT_LIGHT, POSTIT_SHADE).save(OUT / "notebook_tab.png")
    postit(POSTIT_LIGHT, rgb("#f6e8a6"), POSTIT).save(OUT / "notebook_tab_hover.png")
    postit(POSTIT_PINK, POSTIT_PINK_LIGHT, POSTIT_PINK_SHADE).save(OUT / "notebook_tab_selected.png")
    for index, scale in enumerate((0.45, 0.8, 1.0)):
        paint_ink(ink_mask(scale)).save(OUT / f"ink_blot_{index}.png")
    ink_drips().save(OUT / "ink_drips.png")
    phone_frame().save(OUT / "phone_frame.png")
    hud_bars().save(OUT / "hud_bars.png")
    signal_bars().save(OUT / "signal_bars.png")
    menu_frame().save(OUT / "menu_frame.png")
    for state in ("normal", "hover", "pressed"):
        menu_button(state).save(OUT / f"menu_button_{state}.png")
    for name, image in chat_art().items():
        image.save(OUT / f"{name}.png")
    print("Arte de interfaz en", OUT)


if __name__ == "__main__":
    main()
