extends RefCounted
## Registra as ações de input via código (idempotente), sem depender do editor.
## O personagem não é controlado ao vivo: WASD/setas só aplicam um pequeno desvio.

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"pulse": [KEY_SPACE],
	"restart": [KEY_R],
}


static func ensure() -> void:
	for action_name in BINDINGS:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key in BINDINGS[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action_name, ev)
