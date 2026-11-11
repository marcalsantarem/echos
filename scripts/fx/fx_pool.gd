extends Node2D
## Pool fixo de explosões de cacos (CPUParticles2D, barato no Safari/iPhone).
## Nenhuma instância é criada durante a partida: burst() reaproveita as do pool.

const POOL_SIZE := 12

var _pool: Array[CPUParticles2D] = []
var _next := 0
var _fade: Gradient


func _ready() -> void:
	_fade = Gradient.new()
	_fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_fade.offsets = PackedFloat32Array([0.0, 1.0])
	for i in POOL_SIZE:
		var p := _make_particles()
		add_child(p)
		_pool.append(p)


func _make_particles() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 14
	p.lifetime = 0.55
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 230.0
	p.damping_min = 40.0
	p.damping_max = 90.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color_ramp = _fade
	return p


## Estilhaça em `pos` (posição global) com a cor `color`.
func burst(pos: Vector2, color: Color) -> void:
	if _pool.is_empty():
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.global_position = pos
	p.color = color
	p.restart()
	p.emitting = true


func pool_size() -> int:
	return _pool.size()
