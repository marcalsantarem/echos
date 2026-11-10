extends Node2D
## Inimigo geométrico simples: caminha até o alvo, causa dano de contato e morre.

signal died(enemy: Node2D)

enum Kind { TRIANGLE, SQUARE, HEXAGON }

const SIDES := {Kind.TRIANGLE: 3, Kind.SQUARE: 4, Kind.HEXAGON: 6}
const COLORS := {
	Kind.TRIANGLE: Color(1.0, 0.45, 0.4),
	Kind.SQUARE: Color(1.0, 0.75, 0.3),
	Kind.HEXAGON: Color(0.8, 0.5, 1.0),
}
const SLOW_FACTOR := 0.3
const CONTACT_RADIUS := 18.0

var kind := Kind.TRIANGLE
var speed := 60.0
var contact_damage := 10
var target: Node2D  # sem alvo, vai à origem global
var _dead := false
var _slow_left := 0.0


func _ready() -> void:
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	var dest := Vector2.ZERO
	var has_target := target != null and is_instance_valid(target)
	if has_target:
		dest = target.global_position
	var s := speed
	if _slow_left > 0.0:
		_slow_left -= delta
		s *= SLOW_FACTOR
	global_position = global_position.move_toward(dest, s * delta)
	if has_target and global_position.distance_to(dest) <= CONTACT_RADIUS and target.has_method("take_damage"):
		target.take_damage(contact_damage)
		die()


## Pulso eletromagnético: reduz a velocidade por `seconds`.
func slow(seconds: float) -> void:
	_slow_left = maxf(_slow_left, seconds)


func die() -> void:
	if _dead:
		return
	_dead = true
	died.emit(self)
	queue_free()


func _draw() -> void:
	var sides: int = SIDES[kind]
	var pts := PackedVector2Array()
	for i in sides:
		pts.append(Vector2.from_angle(TAU * i / sides - PI / 2.0) * 14.0)
	draw_colored_polygon(pts, COLORS[kind])
