extends Node2D
## Eco (base da mutação "Eco Autônomo"): fantasma que reproduz ciclicamente uma
## Timeline, lendo o frame do LoopClock (mesmo tick de física = sincronia exata).

const Timeline = preload("res://scripts/timeline/timeline.gd")
const Combat = preload("res://scripts/combat/combat.gd")

var clock: Node  # LoopClock
var timeline: RefCounted

var _facing := Vector2.RIGHT
var _flash_left := 0
var _flash_action := Timeline.Action.NONE
var _last_frame := -1


func setup(loop_clock: Node, recorded: RefCounted) -> void:
	clock = loop_clock
	timeline = recorded
	position = timeline.position_at(0)


func _physics_process(_delta: float) -> void:
	if clock == null or timeline == null:
		return
	var f: int = clock.frame
	position = timeline.position_at(f)
	_facing = timeline.facing_at(f)

	if f != _last_frame:
		_last_frame = f
		var action: int = timeline.action_at(f)
		if action != Timeline.Action.NONE:
			_flash_left = 10
			_flash_action = action
			if is_inside_tree():
				Combat.perform(self, action, global_position, _facing)

	if _flash_left > 0:
		_flash_left -= 1
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 12.0, Color(0.4, 0.7, 1.0, 0.6))
	draw_line(Vector2.ZERO, _facing * 18.0, Color(0.6, 0.9, 1.0), 2.0)
	if _flash_left > 0:
		match _flash_action:
			Timeline.Action.SLASH:
				draw_arc(Vector2.ZERO, Combat.SLASH_RADIUS, 0.0, TAU, 48, Color(0.4, 0.7, 1.0), 3.0)
			Timeline.Action.PARRY:
				draw_arc(Vector2.ZERO, Combat.PARRY_RADIUS, 0.0, TAU, 32, Color(0.4, 0.7, 1.0), 3.0)
