extends RefCounted
## Un chat guionado en curso (decisión de Benja, sesión 16): el amigo escribe sus líneas y Matías responde las
## suyas con un botón. Cada línea del amigo llega LINE_DELAY segundos después de la anterior, como si
## escribiera. Lógica pura: RequestManager la avanza y escribe las líneas en el chat.

## Segundos que tarda el amigo en escribir cada línea.
const LINE_DELAY := 2.5

var data: ChatScriptData
var friend_index := 0
## La próxima línea, contada desde la primera.
var next_line := 0

var _wait_left := LINE_DELAY


func _init(script_data: ChatScriptData, script_friend: int) -> void:
	data = script_data
	friend_index = script_friend


func is_done() -> bool:
	return next_line >= data.lines.size()


## La línea de Matías que espera su botón, o null.
func pending_reply() -> ChatLineData:
	if is_done():
		return null
	var line := data.lines[next_line]
	return line if line.speaker == ChatLineData.Speaker.PLAYER else null


## Matías respondió. Devuelve su línea, o null si no había nada que responder.
func reply() -> ChatLineData:
	var line := pending_reply()
	if line != null:
		next_line += 1
		_wait_left = LINE_DELAY
	return line


## Avanza `delta` segundos. Devuelve la línea del amigo que llega ahora, o null. Mientras espera la respuesta
## de Matías, no avanza.
func advance(delta: float) -> ChatLineData:
	if is_done() or pending_reply() != null:
		return null
	_wait_left -= delta
	if _wait_left > 0.0:
		return null
	var line := data.lines[next_line]
	next_line += 1
	_wait_left = LINE_DELAY
	return line
