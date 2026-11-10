extends Node2D
## Lança: voa em linha reta, perfura até `pierce` inimigos e some após `life`.

var velocity := Vector2.ZERO
var life := 1.0
var pierce := 3
var hit_radius := 26.0


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or enemy.is_queued_for_deletion():
			continue
		if enemy.global_position.distance_to(global_position) <= hit_radius and enemy.has_method("die"):
			enemy.die()
			pierce -= 1
			if pierce <= 0:
				queue_free()
				return
	if life <= 0.0:
		queue_free()


func _draw() -> void:
	var dir := velocity.normalized()
	draw_line(-dir * 16.0, dir * 8.0, Color(1.0, 0.85, 0.3), 3.0)
