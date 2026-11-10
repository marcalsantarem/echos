extends RefCounted
## Resultado "assado" (baked) de um Plan: posição, ação, direção e batida na
## parede por tick de física. Duração variável (padrão 3 s = 180 ticks a 60 Hz).
## Buffers pré-alocados: gravar/reproduzir não aloca nada por frame.

const TICKS_PER_SECOND := 60
const DEFAULT_FRAMES := 180

enum Action { NONE, MOVE, DASH, SLASH, PARRY, SPEAR }

var frame_count: int
var positions := PackedVector2Array()
var actions := PackedInt32Array()
var facings := PackedVector2Array()
var wall_hits := PackedByteArray()
## Quantidade de frames gravados (o maior índice gravado + 1).
var length := 0


func _init(frames: int = DEFAULT_FRAMES) -> void:
	frame_count = maxi(frames, 1)
	positions.resize(frame_count)
	actions.resize(frame_count)
	facings.resize(frame_count)
	facings.fill(Vector2.RIGHT)
	wall_hits.resize(frame_count)


func duration_sec() -> float:
	return float(frame_count) / TICKS_PER_SECOND


## Grava um frame. Retorna false se o índice estiver fora da janela.
## `action` só é registrada no frame em que começa (evento de 1 frame).
func record(frame: int, pos: Vector2, action: int = Action.NONE, facing: Vector2 = Vector2.RIGHT, wall_hit: bool = false) -> bool:
	if frame < 0 or frame >= frame_count:
		return false
	positions[frame] = pos
	actions[frame] = action
	facings[frame] = facing
	wall_hits[frame] = 1 if wall_hit else 0
	length = maxi(length, frame + 1)
	return true


func is_full() -> bool:
	return length >= frame_count


func is_empty() -> bool:
	return length == 0


## Posição no frame; se a gravação for parcial, mantém a última posição.
func position_at(frame: int) -> Vector2:
	if length == 0:
		return Vector2.ZERO
	return positions[clampi(frame, 0, length - 1)]


func facing_at(frame: int) -> Vector2:
	if length == 0:
		return Vector2.RIGHT
	return facings[clampi(frame, 0, length - 1)]


func action_at(frame: int) -> int:
	if frame < 0 or frame >= length:
		return Action.NONE
	return actions[frame]


func wall_at(frame: int) -> bool:
	return frame >= 0 and frame < length and wall_hits[frame] == 1


func clear() -> void:
	positions.fill(Vector2.ZERO)
	actions.fill(Action.NONE)
	facings.fill(Vector2.RIGHT)
	wall_hits.fill(0)
	length = 0
