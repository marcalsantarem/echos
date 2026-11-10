extends CanvasLayer
## Tela cheia de título ("Toque para começar") e de fim de jogo ("Jogar de novo").
## Clique/toque em qualquer ponto confirma (o toque vira clique do mouse no Godot);
## Enter/Espaço também. No fim de jogo há uma pequena trava para um toque
## perdido do jogo não reiniciar a partida sem querer.

signal confirmed

const GAME_OVER_LOCK_MS := 700

var lock_ms := 0

var _shown_at := 0
var _title: Label
var _sub: Label
var _hint: Label


func _ready() -> void:
	layer = 20
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.05, 0.08, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_gui_input)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	_title = _make_label(52, Color(0.8, 0.95, 1.0))
	_sub = _make_label(22, Color(0.7, 0.8, 0.9))
	_hint = _make_label(26, Color(1.0, 0.85, 0.4))
	box.add_child(_title)
	box.add_child(_sub)
	box.add_child(_hint)


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func show_title() -> void:
	_title.text = "ECHO BLADE"
	_sub.text = "Monte a coreografia. O loop faz o resto."
	_hint.text = "Toque para começar"
	lock_ms = 0
	_open()


func show_game_over(wave: int) -> void:
	_title.text = "FIM DE JOGO"
	_sub.text = "Você chegou à onda %d" % wave
	_hint.text = "Toque para jogar de novo"
	lock_ms = GAME_OVER_LOCK_MS
	_open()


func hide_overlay() -> void:
	visible = false


func is_open() -> bool:
	return visible


## Confirma se estiver aberto e fora da trava. Retorna true se emitiu `confirmed`.
func confirm() -> bool:
	if not visible or Time.get_ticks_msec() - _shown_at < lock_ms:
		return false
	confirmed.emit()
	return true


func _open() -> void:
	_shown_at = Time.get_ticks_msec()
	visible = true


func _on_gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		confirm()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not visible or key == null or not key.pressed or key.echo:
		return
	var k: int = key.keycode
	if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SPACE:
		confirm()
		get_viewport().set_input_as_handled()
