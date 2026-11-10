extends RefCounted
## Simulação determinística: Plan -> Timeline. Sem física nem aleatoriedade,
## então o mesmo plano sempre gera exatamente a mesma coreografia.

const Timeline = preload("res://scripts/timeline/timeline.gd")
const Plan = preload("res://scripts/timeline/plan.gd")

const MOVE_SPEED := 150.0     # px/s durante um slot de Mover
const DASH_DISTANCE := 200.0  # px, percorridos nos primeiros DASH_FRAMES do slot
const DASH_FRAMES := 10

## Frame (dentro do slot) em que o efeito da ação acontece.
const EVENT_FRAME := {
	Timeline.Action.SLASH: 6,
	Timeline.Action.PARRY: 0,
	Timeline.Action.SPEAR: 4,
}


## Gera a timeline a partir de `origin`. Bater na parede (raio da arena) é
## marcado uma vez por encontro (borda de subida), não a cada frame.
static func bake(plan: RefCounted, arena_radius: float, origin: Vector2 = Vector2.ZERO) -> RefCounted:
	var timeline: RefCounted = Timeline.new(plan.frame_count())
	var pos := origin
	var was_on_wall := false
	for slot in plan.slot_count():
		var action: int = plan.actions[slot]
		var dir: Vector2 = plan.dirs[slot]
		for i in Plan.SLOT_FRAMES:
			var step := Vector2.ZERO
			if action == Timeline.Action.MOVE:
				step = dir * MOVE_SPEED / Timeline.TICKS_PER_SECOND
			elif action == Timeline.Action.DASH and i < DASH_FRAMES:
				step = dir * DASH_DISTANCE / DASH_FRAMES
			pos += step

			var on_wall := pos.length() > arena_radius
			if on_wall:
				pos = pos.limit_length(arena_radius)

			var event: int = Timeline.Action.NONE
			if EVENT_FRAME.get(action, -1) == i:
				event = action
			timeline.record(slot * Plan.SLOT_FRAMES + i, pos, event, dir, on_wall and not was_on_wall)
			was_on_wall = on_wall
	return timeline
