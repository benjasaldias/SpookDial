class_name WaveData
extends Resource
## Una ola armada a mano, en el plan de olas de una noche (NightData.wave_plan; docs/26 §3.2). Así se arma la noche 1 de
## Normal, para que lo que llega no llegue todo junto (pedido de Benja tras el primer testeo, 11 de noviembre).
## Las llegadas se alternan: consulta, video, consulta… Lo que sobra va al final.
## La última ola del plan es la final: llega lo más tarde posible, para que su última consulta alcance a terminar antes de
## las 06:00.

@export_group("Llegadas")
## Consultas de la ola.
@export_range(0, 6) var requests := 1
## Videos de la ola: cada uno llega después de la consulta que lo precede (envíos programados de la cuota).
@export_range(0, 4) var videos := 0
## Segundos entre dos consultas seguidas, o entre un video y lo que sigue (mínimo y máximo, al azar).
@export var spacing := Vector2(4, 8)
## Un video llega cuando a la consulta anterior le quedan estos segundos…
@export var video_time_left := 30.0
## …o, si ya no queda ninguna consulta abierta, estos segundos después (mínimo y máximo, al azar).
@export var video_after_answer := Vector2(3, 6)
## Segundos de calma antes de la ola (mínimo y máximo, al azar): la primera los cuenta desde las 00:00, y las demás desde
## que se resolvió la anterior. La final no los usa.
@export var calm_before := Vector2(40, 60)

@export_group("En la ola")
## Llegan de 3 a 15 s después de que empieza la ola (BalanceData.wave_event_delay).
@export var interferences := 0
@export var incidents := 0
@export var hands := 0

@export_group("En la calma que sigue")
## Screamers ambientales de la calma que sigue a la ola.
@export var calm_scares := 0
## Visitas de la criatura de la ventana en esa calma.
@export var calm_creatures := 0


## Las llegadas, en orden: false es una consulta y true, un video.
func arrivals() -> Array[bool]:
	var order: Array[bool] = []
	for index in maxi(requests, videos):
		if index < requests:
			order.append(false)
		if index < videos:
			order.append(true)
	return order
