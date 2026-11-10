extends Node
## Relógio único do loop. Conta ticks de física 0..loop_frames-1 e emite
## loop_wrapped. Executor e ecos leem `frame` no mesmo tick de física, então
## nunca perdem sincronia.
##
## Prioridade alta (roda por último no tick): quem lê `frame` vê o tick atual e
## só depois o relógio avança. Ao dar a volta, emite loop_wrapped.
##
## A duração do loop muda só na volta (request_loop_frames), nunca no meio dele.

const Timeline = preload("res://scripts/timeline/timeline.gd")

signal loop_wrapped

var frame := 0
var loop_count := 0
var loop_frames := Timeline.DEFAULT_FRAMES
var running := true

var _pending_loop_frames := 0


func _init() -> void:
	process_physics_priority = 100


func _physics_process(_delta: float) -> void:
	if running:
		step()


func step() -> void:
	frame += 1
	if frame >= loop_frames:
		frame = 0
		loop_count += 1
		if _pending_loop_frames > 0:
			loop_frames = _pending_loop_frames
			_pending_loop_frames = 0
		loop_wrapped.emit()


## Aplica a nova duração na próxima volta do loop.
func request_loop_frames(frames: int) -> void:
	_pending_loop_frames = 0 if frames == loop_frames else maxi(frames, 1)


## Reinicia imediatamente (usado na fase de planejamento).
func reset(frames: int) -> void:
	loop_frames = maxi(frames, 1)
	_pending_loop_frames = 0
	frame = 0
