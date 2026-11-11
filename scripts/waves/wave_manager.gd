extends Node2D
## Gerencia ondas: spawna inimigos em pontos aleatórios da borda da arena
## circular (centrada na posição deste nó). A contagem cresce exponencialmente
## (base_count * growth_factor^(onda-1), limitada a max_count). A próxima onda
## começa após limpar a atual.

const Enemy = preload("res://scripts/waves/enemy.gd")

signal wave_started(wave: int, enemy_count: int)
signal wave_cleared(wave: int)
## Inimigo morto pelo jogador/ecos (posição global e tipo), para estilhaços e hit-stop.
signal enemy_killed(pos: Vector2, kind: int)

@export var arena_radius := 300.0
@export var base_count := 3
@export var growth_factor := 1.4
@export var max_count := 80
@export var delay_between_waves := 2.0

var rng := RandomNumberGenerator.new()
var target: Node2D  # alvo dos inimigos (jogador)
var wave := 0
var alive := 0

var _running := false
var _cooldown := 0.0


func _ready() -> void:
	if rng.seed == 0:
		rng.randomize()


func start() -> void:
	_running = true
	_cooldown = 0.0


func stop() -> void:
	_running = false


func enemies_in_wave(wave_number: int) -> int:
	return mini(roundi(base_count * pow(growth_factor, wave_number - 1)), max_count)


func _physics_process(delta: float) -> void:
	if not _running or alive > 0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		spawn_wave()


## Spawna a próxima onda e retorna os inimigos criados.
func spawn_wave() -> Array[Node2D]:
	wave += 1
	var count := enemies_in_wave(wave)
	var spawned: Array[Node2D] = []
	for i in count:
		spawned.append(spawn_enemy())
	wave_started.emit(wave, count)
	return spawned


func spawn_enemy() -> Node2D:
	var enemy: Node2D = Enemy.new()
	enemy.kind = rng.randi_range(0, Enemy.Kind.size() - 1)
	enemy.speed = rng.randf_range(45.0, 75.0)
	enemy.target = target
	add_child(enemy)
	enemy.position = random_edge_point()
	alive += 1
	enemy.tree_exited.connect(_on_enemy_gone, CONNECT_ONE_SHOT)
	enemy.died.connect(_on_enemy_died)
	return enemy


## Ponto local (relativo ao centro da arena) exatamente sobre a borda.
func random_edge_point() -> Vector2:
	return Vector2.from_angle(rng.randf() * TAU) * arena_radius


func _on_enemy_died(enemy: Node2D, by_player: bool) -> void:
	if by_player:
		enemy_killed.emit(enemy.global_position, enemy.kind)


func _on_enemy_gone() -> void:
	alive -= 1
	if alive <= 0:
		alive = 0
		_cooldown = delay_between_waves
		wave_cleared.emit(wave)
