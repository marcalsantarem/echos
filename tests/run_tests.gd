extends SceneTree
## Testes headless, sem dependências externas.
## Rodar: godot --headless --path . -s tests/run_tests.gd
## Um único teste: ... -s tests/run_tests.gd -- test_nome

const Timeline = preload("res://scripts/timeline/timeline.gd")
const Plan = preload("res://scripts/timeline/plan.gd")
const Simulator = preload("res://scripts/timeline/simulator.gd")
const LoopClock = preload("res://scripts/timeline/loop_clock.gd")
const Player = preload("res://scripts/player/player_controller.gd")
const EchoPlayer = preload("res://scripts/echo/echo_player.gd")
const Combat = preload("res://scripts/combat/combat.gd")
const WaveManager = preload("res://scripts/waves/wave_manager.gd")
const Enemy = preload("res://scripts/waves/enemy.gd")
const PlannerUI = preload("res://scripts/ui/planner_ui.gd")
const OverlayUI = preload("res://scripts/ui/overlay_ui.gd")

var _failures := 0
var _checks := 0
var _done := false


## Os testes rodam no primeiro frame (a árvore já está ativa, _ready e física funcionam).
func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	_run()
	return true


func _run() -> void:
	var only := ""
	var user_args := OS.get_cmdline_user_args()
	if user_args.size() > 0:
		only = user_args[0]

	for m in get_script().get_script_method_list():
		var name: String = m.name
		if not name.begins_with("test_"):
			continue
		if only != "" and name != only:
			continue
		print("• ", name)
		call(name)

	print("\n%d checagens, %d falhas" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures += 1
		printerr("  FALHOU: ", msg)


func _orphans() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))


func _objects() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))


# --- Timeline -------------------------------------------------------------

func test_timeline_default_is_three_seconds() -> void:
	var t := Timeline.new()
	check(t.frame_count == 180 and is_equal_approx(t.duration_sec(), 3.0), "padrão 180 frames = 3 s")
	check(ProjectSettings.get_setting("physics/common/physics_ticks_per_second") == Timeline.TICKS_PER_SECOND, "projeto roda a 60 ticks de física")


func test_timeline_variable_length_and_bounds() -> void:
	var t := Timeline.new(240)
	check(is_equal_approx(t.duration_sec(), 4.0), "240 frames = 4 s")
	check(t.record(0, Vector2(1, 2), Timeline.Action.DASH, Vector2.UP), "frame 0 aceito")
	check(t.record(239, Vector2(3, 4), Timeline.Action.PARRY), "último frame aceito")
	check(not t.record(240, Vector2.ONE), "frame 240 rejeitado")
	check(not t.record(-1, Vector2.ONE), "frame -1 rejeitado")
	check(t.is_full(), "cheia")
	check(t.position_at(0) == Vector2(1, 2) and t.facing_at(0) == Vector2.UP, "posição/direção frame 0")
	check(t.action_at(239) == Timeline.Action.PARRY, "ação no último frame")
	t.clear()
	check(t.is_empty() and t.action_at(0) == Timeline.Action.NONE, "clear zera")


func test_timeline_partial_holds_last_position() -> void:
	var t := Timeline.new()
	for f in 10:
		t.record(f, Vector2(f, 0))
	check(t.position_at(150) == Vector2(9, 0), "mantém última posição em gravação parcial")


# --- Plan -----------------------------------------------------------------

func test_plan_slots_and_growth() -> void:
	var p := Plan.new()
	check(p.slot_count() == 6 and p.frame_count() == 180 and is_equal_approx(p.duration_sec(), 3.0), "plano inicial: 6 slots = 3 s")
	check(p.set_slot(2, Timeline.Action.DASH, Vector2(0, 5)), "set_slot válido")
	check(p.dirs[2] == Vector2.DOWN, "direção normalizada")
	check(not p.set_slot(6, Timeline.Action.DASH), "slot fora do intervalo rejeitado")
	check(p.add_slots(2) == 2 and p.frame_count() == 240, "+2 slots = +1 s")
	check(Plan.new(23).add_slots(5) == 1, "limitado a MAX_SLOTS")
	check(p.slot_of_frame(0) == 0 and p.slot_of_frame(30) == 1 and p.slot_of_frame(9999) == 7, "slot_of_frame")


# --- Simulator ------------------------------------------------------------

func test_simulator_move_and_dash_distances() -> void:
	var p := Plan.new(2)
	p.set_slot(0, Timeline.Action.MOVE, Vector2.RIGHT)
	p.set_slot(1, Timeline.Action.DASH, Vector2.DOWN)
	var t: RefCounted = Simulator.bake(p, 1000.0)
	check(t.frame_count == 60 and t.is_full(), "timeline com 60 frames")
	check(t.position_at(29).is_equal_approx(Vector2(75, 0)), "Mover: 150 px/s por 0,5 s = 75 px")
	check(t.position_at(59).is_equal_approx(Vector2(75, 200)), "Dash: 200 px")


func test_simulator_events_at_expected_frames() -> void:
	var p := Plan.new(3)
	p.set_slot(0, Timeline.Action.SLASH)
	p.set_slot(1, Timeline.Action.PARRY)
	p.set_slot(2, Timeline.Action.SPEAR)
	var t: RefCounted = Simulator.bake(p, 1000.0)
	var events := 0
	for f in t.frame_count:
		if t.action_at(f) != Timeline.Action.NONE:
			events += 1
	check(events == 3, "um evento por ação")
	check(t.action_at(6) == Timeline.Action.SLASH, "Corte no frame 6 do slot 0")
	check(t.action_at(30) == Timeline.Action.PARRY, "Parry no frame 0 do slot 1")
	check(t.action_at(64) == Timeline.Action.SPEAR, "Lança no frame 4 do slot 2")


func test_simulator_is_deterministic() -> void:
	var p := Plan.new()
	p.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)
	p.set_slot(1, Timeline.Action.MOVE, Vector2(1, 1))
	p.set_slot(2, Timeline.Action.SLASH)
	var a: RefCounted = Simulator.bake(p, 300.0)
	var b: RefCounted = Simulator.bake(p, 300.0)
	check(a.positions == b.positions and a.actions == b.actions and a.wall_hits == b.wall_hits, "mesmo plano gera mesma timeline")


func test_simulator_wall_clamp_and_edge_trigger() -> void:
	var p := Plan.new(2)
	p.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)  # 200 px com raio 100 => bate na parede
	var t: RefCounted = Simulator.bake(p, 100.0)
	var hits := 0
	var inside := true
	for f in t.frame_count:
		if t.wall_at(f):
			hits += 1
		if t.position_at(f).length() > 100.0 + 0.001:
			inside = false
	check(inside, "nunca sai do raio da arena")
	check(hits == 1, "batida na parede marcada uma única vez (borda de subida), foi %d" % hits)


# --- Relógio / sincronia ---------------------------------------------------

func test_clock_wraps_and_applies_pending_length_on_wrap() -> void:
	var clock := LoopClock.new()
	clock.reset(60)
	var wraps := [0]
	clock.loop_wrapped.connect(func(): wraps[0] += 1)
	clock.request_loop_frames(120)
	for i in 59:
		clock.step()
	check(clock.frame == 59 and clock.loop_frames == 60 and wraps[0] == 0, "duração só muda na volta")
	clock.step()
	check(clock.frame == 0 and wraps[0] == 1 and clock.loop_frames == 120, "volta aplica 120 frames")
	for i in 120:
		clock.step()
	check(wraps[0] == 2 and clock.loop_count == 2, "segundo ciclo com 120 frames")
	clock.free()


func test_echo_replays_in_sync_with_clock() -> void:
	var clock := LoopClock.new()
	var t := Timeline.new()
	for f in t.frame_count:
		t.record(f, Vector2(f * 2, -f))
	var echo := EchoPlayer.new()
	root.add_child(echo)
	echo.setup(clock, t)
	var ok := true
	for tick in t.frame_count * 3:  # três ciclos completos
		echo._physics_process(0.0)
		if echo.position != t.position_at(tick % t.frame_count):
			ok = false
		clock.step()
	check(ok, "eco segue a gravação tick a tick por 3 ciclos")
	root.remove_child(echo)
	echo.free()
	clock.free()


# --- Player (executor) -----------------------------------------------------

func test_player_follows_baked_timeline_and_takes_wall_damage() -> void:
	var clock := LoopClock.new()
	clock.reset(60)
	var p := Plan.new(2)
	p.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)
	var t: RefCounted = Simulator.bake(p, 100.0)
	var player := Player.new()
	root.add_child(player)
	player.arena_radius = 100.0
	player.setup(clock, t)
	var hp := player.health
	var in_sync := true
	for f in 60:
		player._physics_process(1.0 / 60.0)
		if not player.position.is_equal_approx(t.position_at(f)):
			in_sync = false
		clock.step()
	check(in_sync, "posição do jogador == timeline em todos os frames")
	check(player.health == hp - Player.WALL_DAMAGE, "uma batida na parede = %d de dano" % Player.WALL_DAMAGE)
	# Segundo ciclo: mesma coreografia, mesmo dano.
	for f in 60:
		player._physics_process(1.0 / 60.0)
		clock.step()
	check(player.health == hp - 2 * Player.WALL_DAMAGE, "ciclo seguinte repete a batida")
	root.remove_child(player)
	player.free()
	clock.free()


func test_player_death_emits_once() -> void:
	var player := Player.new()
	root.add_child(player)
	var deaths := [0]
	player.died.connect(func(): deaths[0] += 1)
	player.take_damage(1000)
	player.take_damage(10)
	check(player.is_dead() and player.health == 0 and deaths[0] == 1, "morre uma vez")
	root.remove_child(player)
	player.free()


# --- Combate ---------------------------------------------------------------

func test_slash_kills_only_enemies_in_radius() -> void:
	var near := Enemy.new()
	var far := Enemy.new()
	root.add_child(near)
	root.add_child(far)
	near.global_position = Vector2(50, 0)
	far.global_position = Vector2(300, 0)
	Combat.perform(root, Timeline.Action.SLASH, Vector2.ZERO, Vector2.RIGHT)
	check(near.is_queued_for_deletion(), "inimigo próximo morre")
	check(not far.is_queued_for_deletion(), "inimigo distante sobrevive")
	near.free()
	far.free()


func test_spear_flies_and_pierces() -> void:
	var host := Node2D.new()
	root.add_child(host)
	var e1 := Enemy.new()
	var e2 := Enemy.new()
	root.add_child(e1)
	root.add_child(e2)
	e1.global_position = Vector2(100, 0)
	e2.global_position = Vector2(100, 200)
	Combat.perform(host, Timeline.Action.SPEAR, Vector2.ZERO, Vector2.RIGHT)
	var spear := root.get_child(root.get_child_count() - 1)
	check(spear.velocity.x > 0.0, "lança foi criada voando para a direita")
	spear._physics_process(0.15)
	check(e1.is_queued_for_deletion() and not e2.is_queued_for_deletion(), "lança acerta quem está na linha")
	spear._physics_process(2.0)
	check(spear.is_queued_for_deletion(), "lança some após o tempo de vida")
	spear.free()
	e1.free()
	e2.free()
	host.free()


# --- Planner UI ------------------------------------------------------------

func test_planner_assigns_actions_and_tracks_slots() -> void:
	var plan := Plan.new()
	var ui := PlannerUI.new()
	root.add_child(ui)
	ui.setup(plan, null)
	var changed := [0]
	ui.plan_changed.connect(func(): changed[0] += 1)
	ui.selected_action = Timeline.Action.DASH
	ui.dir_index = 2  # ↓
	ui._assign(3)
	check(plan.actions[3] == Timeline.Action.DASH and plan.dirs[3].is_equal_approx(Vector2.DOWN), "slot recebe ação e direção")
	check(changed[0] == 1, "plan_changed emitido")
	plan.add_slots(2)
	ui.refresh()
	check(ui._slot_buttons.size() == 8, "refresh cria botões para os novos slots")
	root.remove_child(ui)
	ui.free()


# --- Overlay (título / fim de jogo) ----------------------------------------

func test_overlay_title_confirms_on_click_without_keyboard() -> void:
	var ui := OverlayUI.new()
	root.add_child(ui)
	var confirmed := [0]
	ui.confirmed.connect(func(): confirmed[0] += 1)
	check(not ui.is_open() and not ui.confirm(), "fechado não confirma")
	ui.show_title()
	check(ui.is_open(), "título aparece")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	ui._on_gui_input(click)  # toque/clique em qualquer ponto
	check(confirmed[0] == 1, "clique confirma o título")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	ui._on_gui_input(release)
	check(confirmed[0] == 1, "soltar o botão não confirma de novo")
	ui.hide_overlay()
	check(not ui.is_open(), "esconde")
	root.remove_child(ui)
	ui.free()


func test_overlay_game_over_has_lock_against_stray_taps() -> void:
	var ui := OverlayUI.new()
	root.add_child(ui)
	var confirmed := [0]
	ui.confirmed.connect(func(): confirmed[0] += 1)
	ui.show_game_over(7)
	check(ui._sub.text.contains("7"), "mostra a onda alcançada")
	check(ui.lock_ms == OverlayUI.GAME_OVER_LOCK_MS, "trava ativa no fim de jogo")
	check(not ui.confirm() and confirmed[0] == 0, "toque imediato é ignorado")
	ui.lock_ms = 0  # simula o tempo passado
	check(ui.confirm() and confirmed[0] == 1, "depois da trava, confirma")
	root.remove_child(ui)
	ui.free()


func test_main_scene_title_then_game_over_flow() -> void:
	var main_script: GDScript = load("res://scripts/main.gd")
	main_script.skip_title = false
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	check(main.overlay.is_open(), "partida abre com a tela de título")
	check(main.overlay.confirm() and not main.overlay.is_open(), "toque fecha o título")
	main.player.take_damage(1000)
	check(main.overlay.is_open() and main._over, "morte abre o fim de jogo")
	main_script.skip_title = true
	root.remove_child(main)
	main.free()
	main_script.skip_title = false


# --- Vazamentos de memória ------------------------------------------------

func test_timeline_is_freed_when_unreferenced() -> void:
	var t := Timeline.new()
	var ref: WeakRef = weakref(t)
	t = null
	check(ref.get_ref() == null, "Timeline (RefCounted) liberada sem referências")


func test_bake_replay_cycles_do_not_leak() -> void:
	var clock := LoopClock.new()
	var plan := Plan.new()
	plan.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)
	plan.set_slot(1, Timeline.Action.MOVE, Vector2.UP)
	var objects_before := _objects()
	var orphans_before := _orphans()
	for cycle in 300:
		var t: RefCounted = Simulator.bake(plan, 300.0)
		var echo := EchoPlayer.new()
		root.add_child(echo)
		echo.setup(clock, t)
		for f in t.frame_count:
			clock.frame = f
			echo._physics_process(0.0)
		root.remove_child(echo)
		echo.free()
	check(_objects() == objects_before, "contagem de objetos estável (antes %d, depois %d)" % [objects_before, _objects()])
	check(_orphans() == orphans_before, "nenhum nó órfão novo")
	clock.free()


func test_player_rebake_cycles_do_not_leak() -> void:
	var clock := LoopClock.new()
	var plan := Plan.new()
	plan.set_slot(0, Timeline.Action.DASH, Vector2.RIGHT)
	var player := Player.new()
	root.add_child(player)
	player.setup(clock, Simulator.bake(plan, 300.0))
	var objects_before := _objects()
	for cycle in 50:
		for i in plan.frame_count():
			player._physics_process(1.0 / 60.0)
			clock.step()
		player.set_timeline(Simulator.bake(plan, 300.0))  # a anterior deve ser liberada
		plan.add_slots(1) if cycle % 10 == 0 and plan.slot_count() < 12 else 0
	check(_objects() == objects_before, "re-bakes repetidos não acumulam objetos (antes %d, depois %d)" % [objects_before, _objects()])
	root.remove_child(player)
	player.free()
	clock.free()


# --- WaveManager ----------------------------------------------------------

func test_wave_spawns_on_arena_edge() -> void:
	var wm := WaveManager.new()
	wm.arena_radius = 300.0
	wm.rng.seed = 12345
	root.add_child(wm)
	wm.global_position = Vector2(100, 50)
	var spawned := wm.spawn_wave()
	check(spawned.size() == wm.base_count, "primeira onda tem base_count inimigos")
	var on_edge := true
	for e in spawned:
		if absf(e.position.length() - 300.0) > 0.01:
			on_edge = false
	check(on_edge, "todos os inimigos nascem na borda do círculo")
	var angles := {}
	for e in spawned:
		angles[snappedf(e.position.angle(), 0.01)] = true
	check(angles.size() > 1, "posições variam (aleatórias)")
	root.remove_child(wm)
	wm.free()


func test_wave_growth_is_exponential_and_capped() -> void:
	var wm := WaveManager.new()
	check(wm.enemies_in_wave(1) == 3, "onda 1 = base_count")
	check(wm.enemies_in_wave(2) == 4 and wm.enemies_in_wave(3) == 6, "cresce por growth_factor")
	check(wm.enemies_in_wave(5) > 2 * wm.enemies_in_wave(3) - 1, "crescimento acelera (não linear)")
	check(wm.enemies_in_wave(100) == wm.max_count, "limitado a max_count")
	wm.free()


func test_wave_is_deterministic_with_seed() -> void:
	var a := WaveManager.new()
	var b := WaveManager.new()
	a.rng.seed = 7
	b.rng.seed = 7
	check(a.random_edge_point() == b.random_edge_point(), "mesma seed gera mesmo ponto")
	a.free()
	b.free()


func test_wave_counts_alive_and_clears() -> void:
	var wm := WaveManager.new()
	wm.rng.seed = 1
	root.add_child(wm)
	var cleared := [0]
	wm.wave_cleared.connect(func(_w): cleared[0] += 1)
	var spawned := wm.spawn_wave()
	check(wm.alive == spawned.size(), "alive == inimigos spawnados")
	for e in spawned:
		wm.remove_child(e)  # dispara tree_exited de forma síncrona
		e.free()
	check(wm.alive == 0 and cleared[0] == 1, "onda limpa quando todos saem")
	root.remove_child(wm)
	wm.free()


func test_enemy_contact_damages_target_and_dies() -> void:
	var player := Player.new()
	root.add_child(player)
	player.global_position = Vector2(500, 500)
	var e := Enemy.new()
	root.add_child(e)
	e.target = player
	e.global_position = Vector2(505, 500)
	var hp := player.health
	e._physics_process(0.016)
	check(player.health == hp - e.contact_damage and e.is_queued_for_deletion(), "contato causa dano e remove o inimigo")
	e.free()
	root.remove_child(player)
	player.free()


func test_wave_cycles_do_not_leak() -> void:
	var wm := WaveManager.new()
	wm.rng.seed = 99
	wm.max_count = 10
	root.add_child(wm)
	var objects_before := _objects()
	var orphans_before := _orphans()
	for i in 100:
		for e in wm.spawn_wave():
			wm.remove_child(e)
			e.free()
	check(_objects() == objects_before, "ondas repetidas não acumulam objetos (antes %d, depois %d)" % [objects_before, _objects()])
	check(_orphans() == orphans_before, "nenhum nó órfão novo")
	root.remove_child(wm)
	wm.free()
