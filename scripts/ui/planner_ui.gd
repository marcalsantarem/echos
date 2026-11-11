extends CanvasLayer
## Barra de planejamento na parte inferior: paleta de ações + slots de 0,5 s.
## Clique/toque num slot aplica a ação selecionada (com a direção escolhida);
## clique direito, ou o modo "Girar slot" (toque), gira a direção do slot em 45°. Teclas 1-6 selecionam a ação,
## Enter inicia a execução.

const Timeline = preload("res://scripts/timeline/timeline.gd")

signal plan_changed
signal execute_pressed

const ACTION_NAMES := ["Aguardar", "Mover", "Dash", "Corte Circular", "Parry", "Lança"]
const DIR_ARROWS := ["→", "↘", "↓", "↙", "←", "↖", "↑", "↗"]
const TOUCH_HEIGHT := 44.0  # alvo de toque confortável
const DIRECTIONAL := [Timeline.Action.MOVE, Timeline.Action.DASH, Timeline.Action.SPEAR]

var plan: RefCounted
var clock: Node
var selected_action: int = Timeline.Action.MOVE
var dir_index := 0

var _slots_box: HBoxContainer
var _palette_buttons: Array[Button] = []
var _slot_buttons: Array[Button] = []
var rotate_mode := false

var _dir_button: Button
var _rotate_button: Button
var _execute_button: Button


func setup(plan_ref: RefCounted, clock_ref: Node) -> void:
	plan = plan_ref
	clock = clock_ref
	_build()
	refresh()


func hide_execute() -> void:
	_execute_button.hide()


func _build() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var palette := HBoxContainer.new()
	vbox.add_child(palette)
	var group := ButtonGroup.new()
	for a in ACTION_NAMES.size():
		var b := Button.new()
		b.text = "%d %s" % [a + 1, ACTION_NAMES[a]]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = (a == selected_action)
		b.custom_minimum_size = Vector2(0, TOUCH_HEIGHT)
		b.pressed.connect(_select_action.bind(a))
		palette.add_child(b)
		_palette_buttons.append(b)

	_dir_button = Button.new()
	_dir_button.custom_minimum_size = Vector2(0, TOUCH_HEIGHT)
	_dir_button.pressed.connect(_cycle_dir)
	palette.add_child(_dir_button)
	_update_dir_text()

	# Sem botão direito no toque: neste modo, tocar num slot gira a direção dele.
	_rotate_button = Button.new()
	_rotate_button.text = "↻ Girar slot"
	_rotate_button.toggle_mode = true
	_rotate_button.custom_minimum_size = Vector2(0, TOUCH_HEIGHT)
	_rotate_button.toggled.connect(func(on: bool): rotate_mode = on)
	palette.add_child(_rotate_button)

	_execute_button = Button.new()
	_execute_button.text = "▶ Executar (Enter)"
	_execute_button.custom_minimum_size = Vector2(0, TOUCH_HEIGHT)
	_execute_button.pressed.connect(func(): execute_pressed.emit())
	palette.add_child(_execute_button)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 84)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	_slots_box = HBoxContainer.new()
	scroll.add_child(_slots_box)


## Reconstrói os botões de slot (chamar quando o plano ganhar slots).
func refresh() -> void:
	for b in _slot_buttons:
		_slots_box.remove_child(b)
		b.queue_free()
	_slot_buttons.clear()
	for i in plan.slot_count():
		var b := Button.new()
		b.custom_minimum_size = Vector2(92, 68)
		b.pressed.connect(_assign.bind(i))
		b.gui_input.connect(_slot_input.bind(i))
		_slots_box.add_child(b)
		_slot_buttons.append(b)
		_update_slot_text(i)


func _update_slot_text(i: int) -> void:
	var action: int = plan.actions[i]
	var text := "%d\n%s" % [i + 1, ACTION_NAMES[action]]
	if action in DIRECTIONAL:
		text += " " + DIR_ARROWS[_dir_to_index(plan.dirs[i])]
	_slot_buttons[i].text = text


func _dir_to_index(dir: Vector2) -> int:
	return posmod(roundi(dir.angle() / (PI / 4.0)), 8)


func _select_action(action: int) -> void:
	selected_action = action
	_palette_buttons[action].button_pressed = true


func _cycle_dir() -> void:
	dir_index = (dir_index + 1) % 8
	_update_dir_text()


func _update_dir_text() -> void:
	_dir_button.text = "Direção: " + DIR_ARROWS[dir_index]


func _assign(i: int) -> void:
	if rotate_mode:
		_rotate_slot(i)
		return
	plan.set_slot(i, selected_action, Vector2.from_angle(dir_index * PI / 4.0))
	_update_slot_text(i)
	plan_changed.emit()


func _rotate_slot(i: int) -> void:
	plan.set_slot(i, plan.actions[i], plan.dirs[i].rotated(PI / 4.0))
	_update_slot_text(i)
	plan_changed.emit()


func _slot_input(event: InputEvent, i: int) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
		_rotate_slot(i)


func _process(_delta: float) -> void:
	if clock == null or _slot_buttons.is_empty():
		return
	var current: int = plan.slot_of_frame(clock.frame) if clock.running else -1
	for i in _slot_buttons.size():
		_slot_buttons[i].modulate = Color(1, 1, 0.4) if i == current else Color.WHITE


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var k: int = key.keycode
	if k >= KEY_1 and k < KEY_1 + ACTION_NAMES.size():
		_select_action(k - KEY_1)
	elif (k == KEY_ENTER or k == KEY_KP_ENTER) and _execute_button.visible:
		execute_pressed.emit()
