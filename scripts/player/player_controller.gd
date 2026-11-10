extends Node2D
## Personagem: NÃO é controlado em tempo real. Executa em loop a Timeline
## "assada" do plano, lendo o frame do LoopClock. O jogador só pode aplicar um
## pequeno desvio (nudge) com WASD/setas.
##
## Coordenadas: `position` é o espaço da arena (centro = origem local do pai).

signal health_changed(hp: int)
signal died

const Timeline = preload("res://scripts/timeline/timeline.gd")
const InputSetup = preload("res://scripts/input_setup.gd")
const Combat = preload("res://scripts/combat/combat.gd")

const WALL_DAMAGE := 5

@export var max_health := 100
@export var arena_radius := 300.0
@export var nudge_speed := 140.0
@export var nudge_max := 45.0

var clock: Node  # LoopClock
var baked: RefCounted  # Timeline
var health := 100
var nudge := Vector2.ZERO

var _last_frame := -1
var _facing := Vector2.RIGHT
var _flash_left := 0
var _flash_action := Timeline.Action.NONE
var _dead := false


func _ready() -> void:
	InputSetup.ensure()
	health = max_health


func setup(loop_clock: Node, timeline: RefCounted) -> void:
	clock = loop_clock
	set_timeline(timeline)


func set_timeline(timeline: RefCounted) -> void:
	baked = timeline
	_last_frame = -1
	if baked != null and clock != null:
		position = baked.position_at(clock.frame) + nudge


func is_dead() -> bool:
	return _dead


func take_damage(amount: int) -> void:
	if _dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health)
	if health == 0:
		_dead = true
		died.emit()
		queue_redraw()


func _physics_process(delta: float) -> void:
	if clock == null or baked == null or _dead:
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	nudge = (nudge + dir * nudge_speed * delta).limit_length(nudge_max)

	var f: int = clock.frame
	position = (baked.position_at(f) + nudge).limit_length(arena_radius)
	_facing = baked.facing_at(f)

	# Eventos disparam uma vez por frame (evita repetir enquanto o relógio está parado).
	if f != _last_frame:
		_last_frame = f
		var action: int = baked.action_at(f)
		if action != Timeline.Action.NONE:
			Combat.perform(self, action, global_position, _facing)
			_flash_left = 10
			_flash_action = action
		if baked.wall_at(f):
			take_damage(WALL_DAMAGE)

	if _flash_left > 0:
		_flash_left -= 1
	queue_redraw()


func _draw() -> void:
	var body := Color(0.95, 0.95, 1.0) if not _dead else Color(1, 0.2, 0.2)
	draw_circle(Vector2.ZERO, 12.0, body)
	draw_line(Vector2.ZERO, _facing * 18.0, Color(1, 0.8, 0.3), 2.0)
	if _flash_left > 0:
		match _flash_action:
			Timeline.Action.SLASH:
				draw_arc(Vector2.ZERO, Combat.SLASH_RADIUS, 0.0, TAU, 48, Color(1, 0.4, 0.3), 3.0)
			Timeline.Action.PARRY:
				draw_arc(Vector2.ZERO, Combat.PARRY_RADIUS, 0.0, TAU, 32, Color(0.4, 1, 0.5), 3.0)
			Timeline.Action.DASH:
				draw_circle(Vector2.ZERO, 18.0, Color(1, 1, 1, 0.3))
