extends RefCounted
## Los íconos de Snapgram, píxel por píxel (# es un píxel encendido). Son provisionales hasta el arte de Benja
## y solo decoran: ninguno responde a los clics, salvo el rayo de la linterna, que es del celular y no de Snapgram.

const SIZE := 11

const HEART: Array[String] = [
	"..##...##..",
	".#..#.#..#.",
	"#....#....#",
	"#.........#",
	"#.........#",
	".#.......#.",
	"..#.....#..",
	"...#...#...",
	"....#.#....",
	".....#.....",
]
const COMMENT: Array[String] = [
	"...#####...",
	".##.....##.",
	"#.........#",
	"#.........#",
	"#.........#",
	"#.........#",
	"#.........#",
	".##.....##.",
	"..#.####...",
	"..##.......",
	"..#........",
]
const SEND: Array[String] = [
	"..........#",
	"........##.",
	"......##.#.",
	"....##..#..",
	"..##...#...",
	"##....#....",
	"..##.#.....",
	"....##.....",
	"....#......",
	"...#.......",
	"...........",
]
const BOOKMARK: Array[String] = [
	"#########",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#.......#",
	"#...#...#",
	"#..#.#..#",
	"#.#...#.#",
	"##.....##",
	"#.......#",
]
const HOME: Array[String] = [
	".....#.....",
	"....#.#....",
	"...#...#...",
	"..#.....#..",
	".#.......#.",
	"#.........#",
	".#.......#.",
	".#.......#.",
	".#..###..#.",
	".#..#.#..#.",
	".####.####.",
]
const SEARCH: Array[String] = [
	"...###.....",
	"..#...#....",
	".#.....#...",
	".#.....#...",
	".#.....#...",
	"..#...#....",
	"...###.#...",
	"........#..",
	".........#.",
	"..........#",
	"...........",
]
const NEW_POST: Array[String] = [
	"###########",
	"#.........#",
	"#....#....#",
	"#....#....#",
	"#....#....#",
	"#.#######.#",
	"#....#....#",
	"#....#....#",
	"#....#....#",
	"#.........#",
	"###########",
]
const VIDEOS: Array[String] = [
	"###########",
	"#.........#",
	"#...#.....#",
	"#...##....#",
	"#...###...#",
	"#...####..#",
	"#...###...#",
	"#...##....#",
	"#...#.....#",
	"#.........#",
	"###########",
]
const PROFILE: Array[String] = [
	"...#####...",
	"..#######..",
	".#########.",
	"###########",
	"###########",
	"###########",
	"###########",
	"###########",
	".#########.",
	"..#######..",
	"...#####...",
]


## Dibuja un ícono con su esquina superior izquierda en `corner`.
## El rayo de la linterna, en la barra superior del celular: su flash espanta a la Mano (decisión de Benja, 11 de
## noviembre).
const FLASHLIGHT: Array[String] = [
	".....####..",
	"....####...",
	"...####....",
	"..####.....",
	".#########.",
	"....####...",
	"...####....",
	"..####.....",
	".###.......",
	".##........",
	"#..........",
]


static func draw_icon(canvas: CanvasItem, icon: Array[String], corner: Vector2, color: Color) -> void:
	for row in icon.size():
		var line := icon[row]
		for column in line.length():
			if line[column] == "#":
				canvas.draw_rect(Rect2(corner + Vector2(column, row), Vector2.ONE), color)
