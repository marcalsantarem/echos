extends CanvasLayer
## Controles de toque: joystick virtual (desvio do personagem) e botão de Pulso.
##
## O joystick não lê o teclado: ele pressiona as ações move_* do InputMap com a
## força do eixo, então o PlayerController não precisa saber de toque. Só aparece
## em dispositivo com tela de toque (ou depois do primeiro toque).

signal pulse_pressed

const InputSetup = preload("res://scripts/input_setup.gd")

const STICK_RADIUS := 80.0
const STICK_CAPTURE := 120.0  # raio em que um toque novo "pega" o joystick
const DEADZONE := 0.18

var stick_center := Vector2(130, 440)

var _finger := -1
var _value := Vector2.ZERO
var _knob := Vector2.ZERO
var _pad: Control
var _pulse_button: Button


## Eixo normalizado (-1..1) para um deslocamento do centro; zero dentro da zona morta.
static func axis_from_offset(offset: Vector2, radius: float, deadzone: float) -> Vector2:
	var v := (offset / radius).limit_length(1.0)
	return Vector2.ZERO if v.length() < deadzone else v


func _ready() -> void:
	layer = 10
	InputSetup.ensure()
	var size := get_viewport().get_visible_rect().size
	stick_center = Vector2(130.0, size.y - 270.0)

	_pad = Control.new()
	_pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pad.draw.connect(_draw_pad)
	add_child(_pad)

	_pulse_button = Button.new()
	_pulse_button.text = "Pulso"
	_pulse_button.custom_minimum_size = Vector2(110, 110)
	_pulse_button.position = Vector2(size.x - 150.0, size.y - 325.0)
	_pulse_button.pressed.connect(func(): pulse_pressed.emit())
	add_child(_pulse_button)

	visible = DisplayServer.is_touchscreen_available()


func _exit_tree() -> void:
	release_all()


func show_controls() -> void:
	visible = true


## Segundos de recarga restantes (0 = pronto).
func set_pulse_cooldown(seconds: float) -> void:
	var cooling := seconds > 0.0
	_pulse_button.disabled = cooling
	_pulse_button.text = "%ds" % ceili(seconds) if cooling else "Pulso"


func release_all() -> void:
	_finger = -1
	_value = Vector2.ZERO
	_knob = Vector2.ZERO
	_apply()


func _input(event: InputEvent) -> void:
	var touch := event as InputEventScreenTouch
	if touch != null:
		if not visible:
			visible = true  # primeiro toque revela os controles em qualquer dispositivo
			return
		if touch.pressed:
			if _finger == -1 and touch.position.distance_to(stick_center) <= STICK_CAPTURE:
				_finger = touch.index
				_update(touch.position)
		elif touch.index == _finger:
			release_all()
		return
	var drag := event as InputEventScreenDrag
	if drag != null and drag.index == _finger:
		_update(drag.position)


func _update(pos: Vector2) -> void:
	_value = axis_from_offset(pos - stick_center, STICK_RADIUS, DEADZONE)
	_knob = (pos - stick_center).limit_length(STICK_RADIUS)
	_apply()


func _apply() -> void:
	_set_axis("move_right", "move_left", _value.x)
	_set_axis("move_down", "move_up", _value.y)
	if _pad != null:
		_pad.queue_redraw()


func _set_axis(positive: String, negative: String, v: float) -> void:
	if v > 0.0:
		Input.action_press(positive, v)
		Input.action_release(negative)
	elif v < 0.0:
		Input.action_press(negative, -v)
		Input.action_release(positive)
	else:
		Input.action_release(positive)
		Input.action_release(negative)


func _draw_pad() -> void:
	_pad.draw_arc(stick_center, STICK_RADIUS, 0.0, TAU, 40, Color(0.5, 0.9, 1.0, 0.35), 3.0)
	_pad.draw_circle(stick_center + _knob, 28.0, Color(0.5, 0.9, 1.0, 0.5 if _finger != -1 else 0.25))
