extends RefCounted
## Resolução de ações ofensivas, compartilhada entre jogador e ecos.

const Timeline = preload("res://scripts/timeline/timeline.gd")
const Projectile = preload("res://scripts/combat/projectile.gd")

const SLASH_RADIUS := 90.0   # Corte Circular: ao redor
const PARRY_RADIUS := 55.0
const SPEAR_SPEED := 700.0


## Executa o efeito de `action` em `origin` (posição global). `host` fornece a
## árvore e o pai onde projéteis são criados.
static func perform(host: Node, action: int, origin: Vector2, facing: Vector2) -> void:
	match action:
		Timeline.Action.SLASH:
			strike(host.get_tree(), origin, facing, SLASH_RADIUS, false)
		Timeline.Action.PARRY:
			strike(host.get_tree(), origin, facing, PARRY_RADIUS, false)
		Timeline.Action.SPEAR:
			var parent := host.get_parent()
			if parent == null:
				return
			var spear: Node2D = Projectile.new()
			spear.velocity = facing * SPEAR_SPEED
			parent.add_child(spear)
			spear.global_position = origin


## Mata inimigos dentro de `radius`. Se `half_plane` for true, só atinge
## os que estão à frente de `facing`; false atinge ao redor.
static func strike(tree: SceneTree, origin: Vector2, facing: Vector2, radius: float, half_plane: bool) -> int:
	var kills := 0
	for node in tree.get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		var offset := enemy.global_position - origin
		if offset.length() > radius:
			continue
		if half_plane and offset.dot(facing) < 0.0:
			continue
		if enemy.has_method("die"):
			enemy.die()
			kills += 1
	return kills
