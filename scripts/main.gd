extends Node2D
## Monta a partida: planejamento -> execução em loop -> escalada.
##
## 1. Planejamento: monte o plano de slots (relógio parado). Enter executa.
## 2. Execução: o personagem repete o plano; WASD só dá pequenos desvios;
##    Espaço dispara o pulso eletromagnético (lentidão, recarga longa).
## 3. A cada 15 s a arena fecha, o loop ganha +1 s (2 slots vazios) e o plano
##    editado entra em vigor na próxima volta do loop.

const Timeline = preload("res://scripts/timeline/timeline.gd")
const Plan = preload("res://scripts/timeline/plan.gd")
const Simulator = preload("res://scripts/timeline/simulator.gd")
const LoopClock = preload("res://scripts/timeline/loop_clock.gd")
const Player = preload("res://scripts/player/player_controller.gd")
const WaveManager = preload("res://scripts/waves/wave_manager.gd")
const PlannerUI = preload("res://scripts/ui/planner_ui.gd")
const InputSetup = preload("res://scripts/input_setup.gd")

const ARENA_START := 300.0
const ARENA_MIN := 150.0
const ARENA_SHRINK := 20.0
const ESCALATION_SEC := 15.0
const GROW_SLOTS := 2  # +1 s
const PULSE_COOLDOWN := 12.0
const PULSE_SLOW_SEC := 3.0

var arena_radius := ARENA_START
var plan: RefCounted
var baked: RefCounted
var clock: Node
var player: Node2D
var waves: Node2D
var planner: CanvasLayer
var hud: Label

var _running := false
var _over := false
var _dirty := false
var _escalation_ticks := 0
var _pulse_cd := 0.0


func _ready() -> void:
	InputSetup.ensure()
	var size := get_viewport_rect().size
	position = Vector2(size.x / 2.0, size.y / 2.0 - 70.0)

	plan = Plan.new()
	_prefill_plan()

	clock = LoopClock.new()
	clock.running = false
	add_child(clock)
	clock.loop_wrapped.connect(_on_loop_wrapped)

	player = Player.new()
	player.arena_radius = arena_radius
	add_child(player)
	player.setup(clock, Simulator.bake(plan, arena_radius))
	player.died.connect(_on_player_died)

	waves = WaveManager.new()
	waves.arena_radius = arena_radius
	waves.target = player
	add_child(waves)

	planner = PlannerUI.new()
	add_child(planner)
	planner.setup(plan, clock)
	planner.plan_changed.connect(_on_plan_changed)
	planner.execute_pressed.connect(_start)

	var hud_layer := CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(16, 12)
	hud_layer.add_child(hud)
	add_child(hud_layer)

	_rebake(true)


## Coreografia inicial de exemplo.
func _prefill_plan() -> void:
	plan.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)
	plan.set_slot(1, Timeline.Action.SLASH)
	plan.set_slot(2, Timeline.Action.MOVE, Vector2.LEFT)
	plan.set_slot(3, Timeline.Action.SPEAR, Vector2.UP)
	plan.set_slot(4, Timeline.Action.DASH, Vector2.LEFT)
	plan.set_slot(5, Timeline.Action.PARRY)


func _start() -> void:
	if _running or _over:
		return
	_running = true
	clock.running = true
	waves.start()
	planner.hide_execute()


func _rebake(immediate: bool) -> void:
	baked = Simulator.bake(plan, arena_radius)
	player.arena_radius = arena_radius
	player.set_timeline(baked)
	if immediate:
		clock.reset(plan.frame_count())
	else:
		clock.request_loop_frames(plan.frame_count())
	queue_redraw()


func _on_plan_changed() -> void:
	if _running:
		_dirty = true  # entra em vigor na próxima volta do loop
	else:
		_rebake(true)


func _on_loop_wrapped() -> void:
	if _dirty:
		_dirty = false
		_rebake(false)


func _on_player_died() -> void:
	_over = true
	clock.running = false
	waves.stop()


func _physics_process(delta: float) -> void:
	if not _running or _over:
		return

	_escalation_ticks += 1
	if _escalation_ticks >= int(ESCALATION_SEC * Timeline.TICKS_PER_SECOND):
		_escalation_ticks = 0
		_escalate()

	_pulse_cd = maxf(0.0, _pulse_cd - delta)
	if _pulse_cd == 0.0 and Input.is_action_just_pressed("pulse"):
		_pulse_cd = PULSE_COOLDOWN
		get_tree().call_group("enemies", "slow", PULSE_SLOW_SEC)


func _escalate() -> void:
	arena_radius = maxf(ARENA_MIN, arena_radius - ARENA_SHRINK)
	waves.arena_radius = arena_radius
	if plan.add_slots(GROW_SLOTS) > 0:
		planner.refresh()
	clock.request_loop_frames(plan.frame_count())
	_dirty = true  # re-assa com a arena menor e o plano maior na próxima volta


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
		return
	var status := "Planeje e pressione Executar (Enter)" if not _running else \
		"Loop %d  %.1fs  |  Fecha em %.0fs" % [clock.loop_count, plan.duration_sec(),
		ESCALATION_SEC - float(_escalation_ticks) / Timeline.TICKS_PER_SECOND]
	hud.text = "%s\nVida %d  |  Onda %d  |  Inimigos %d  |  Pulso (Espaço): %s" % [
		status, player.health, waves.wave, waves.alive,
		"pronto" if _pulse_cd <= 0.0 else "%.0fs" % _pulse_cd]
	if _over:
		hud.text += "\nFIM DE JOGO — R reinicia"


func _draw() -> void:
	draw_arc(Vector2.ZERO, arena_radius, 0.0, TAU, 96, Color(0.35, 0.4, 0.6), 2.0)
	if baked != null and baked.length > 1:
		draw_polyline(baked.positions, Color(0.3, 1.0, 1.0, 0.35), 2.0)
		for f in baked.length:
			if baked.actions[f] != Timeline.Action.NONE:
				draw_circle(baked.positions[f], 4.0, Color(1.0, 0.8, 0.3))
