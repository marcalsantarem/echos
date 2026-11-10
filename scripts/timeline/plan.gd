extends RefCounted
## O que o jogador monta: uma lista de slots de 0,5 s, cada um com uma ação e
## uma direção. É só dados; Simulator.bake() transforma isso em Timeline.

const SLOT_SEC := 0.5
const SLOT_FRAMES := 30  # SLOT_SEC * 60 ticks
const START_SLOTS := 6   # 3 s
const MAX_SLOTS := 24    # 12 s

var actions := PackedInt32Array()
var dirs := PackedVector2Array()


func _init(slots: int = START_SLOTS) -> void:
	var n := clampi(slots, 1, MAX_SLOTS)
	actions.resize(n)
	dirs.resize(n)
	dirs.fill(Vector2.RIGHT)


func slot_count() -> int:
	return actions.size()


func frame_count() -> int:
	return actions.size() * SLOT_FRAMES


func duration_sec() -> float:
	return actions.size() * SLOT_SEC


func set_slot(index: int, action: int, dir: Vector2 = Vector2.RIGHT) -> bool:
	if index < 0 or index >= actions.size():
		return false
	actions[index] = action
	dirs[index] = dir.normalized() if dir.length() > 0.0 else Vector2.RIGHT
	return true


## Acrescenta slots vazios (limitado a MAX_SLOTS). Retorna quantos entraram.
func add_slots(count: int) -> int:
	var added := mini(count, MAX_SLOTS - actions.size())
	if added <= 0:
		return 0
	var old := actions.size()
	actions.resize(old + added)
	dirs.resize(old + added)
	for i in range(old, old + added):
		actions[i] = 0
		dirs[i] = Vector2.RIGHT
	return added


func slot_of_frame(frame: int) -> int:
	return clampi(frame / SLOT_FRAMES, 0, actions.size() - 1)
