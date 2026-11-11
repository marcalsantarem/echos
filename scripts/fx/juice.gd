extends Node
## "Juice" de impacto: screen shake direcional e hit-stop de 0,05 s.
##
## O hit-stop pausa a árvore (relógio, jogador e inimigos congelam juntos, então a
## sincronia do loop é mantida) e retoma por um timer que ignora pausa e time_scale.
## Não usa Engine.time_scale: isso mudaria o passo de física. Tem recarga para não
## engasgar quando muitas mortes acontecem em sequência.

const HITSTOP_SEC := 0.05
const HITSTOP_COOLDOWN_MS := 200
const SHAKE_DECAY := 12.0
const SHAKE_MAX := 14.0

var target: Node2D  # nó que treme (a arena); a UI é CanvasLayer e não treme
var base_position := Vector2.ZERO

var _shake := 0.0
var _dir := Vector2.RIGHT
var _last_hitstop_ms := -100000
var _paused_by_me := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _exit_tree() -> void:
	# Se a cena for recarregada durante o hit-stop, nunca deixa a árvore pausada.
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false


## Força do tremor (px), na direção `dir` (ex.: do jogador para onde o golpe acertou).
func shake(dir: Vector2, strength: float) -> void:
	_shake = minf(maxf(_shake, strength), SHAKE_MAX)
	if dir.length_squared() > 0.0001:
		_dir = dir.normalized()


## Congela por HITSTOP_SEC. Retorna false se ainda estiver em recarga.
func hit_stop() -> bool:
	var now := Time.get_ticks_msec()
	if _paused_by_me or now - _last_hitstop_ms < HITSTOP_COOLDOWN_MS:
		return false
	_last_hitstop_ms = now
	_paused_by_me = true
	get_tree().paused = true
	get_tree().create_timer(HITSTOP_SEC, true, false, true).timeout.connect(_resume)
	return true


func _resume() -> void:
	if _paused_by_me and is_inside_tree():
		get_tree().paused = false
	_paused_by_me = false


func current_shake() -> float:
	return _shake


func _process(delta: float) -> void:
	if target == null:
		return
	if _shake > 0.05:
		target.position = base_position + _dir * randf_range(-1.0, 1.0) * _shake
		_shake *= exp(-SHAKE_DECAY * delta)
	elif _shake > 0.0:
		_shake = 0.0
		target.position = base_position
