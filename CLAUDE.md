# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Echo Blade: top-down roguelike in Godot 4.7 (GDScript), single circular arena, neon/dark "cyber-zen dojo" look. The player does NOT steer in real time: they fill a bottom timeline of **0.5 s slots** (starts at 6 = 3 s) with actions, then the character **executes that plan in an endless loop** while the player only nudges small deviations (WASD) and fires one long-cooldown support skill (pulse, Space). Every 15 s the arena shrinks and the loop grows +1 s (2 empty slots to fill). Enemies (geometric shapes) spawn on the arena edge in exponentially growing waves. Walls cost health.

Not built yet (from the concept doc): roguelike mutations (Loop Espelhado, Eco Autônomo, Sobrecarga de Lâmina), upgrades (Fantasma, Lâmina Vampírica, Overclock Temporal), bosses, replay/GIF export (9:16), audio, native mobile export. `EchoPlayer` (ghost replaying a Timeline) exists as the base for "Eco Autônomo" but Main does not spawn it.

## Workflow (adopted by the owner, 2026-11-10; details in `docs/git-workflow.md`)

- Work and commit only on `dev`; never push to `main` (protected; PR `dev`→`main` only when the owner asks). No other branches. Closed versions live only as tags `v0.x.0`, created on `main` when the owner asks. Commit messages: Portuguese, short, imperative; one commit per finished stage, project opening cleanly and tests green.
- Roadmap in `docs/marcos.md`, tasks in `docs/backlog.md` (only the current milestone is broken into tasks), owner decisions in `docs/decisoes.md` (`[Proposta]`/`[A definir]` are NOT rules: ask first), game bible in `docs/00_biblia_projeto.md`. Delegated work needs a briefing (`docs/briefings/_modelo.md`).
- CI (`.github/workflows/deploy-web.yml`): on push to `dev`/`main` and any tag it runs the tests, exports preset "Web" and deploys to Netlify site `echosgame` (`dev--echosgame.netlify.app`, prod on `main`, `<tag>--echosgame.netlify.app` for tags). Deploy is skipped with a warning until the owner sets repo secrets `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID`. Never type or store secrets.
- Web constraints: single-thread export, Compatibility renderer, Safari on iPhone is the performance target; avoid per-frame allocations.
- Owner's standing request: always end a stage/report listing the next tasks from `docs/backlog.md` (ID, description, owner), plus what was completed.
- Keep answers and reports short; read only what is needed; filter long outputs.

## Commands

Godot is not on PATH. Set `$g = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64.exe"` (PowerShell) and run from the repo root:

- Run the game: `& $g --path .`
- Import/refresh (needed after adding files, before first headless run): `& $g --headless --path . --import`
- All tests: `& $g --headless --path . -s tests/run_tests.gd` (exit code 1 on any failure)
- Single test: `& $g --headless --path . -s tests/run_tests.gd -- test_wave_spawns_on_arena_edge`
- Smoke-run main scene: `& $g --headless --path . --quit-after 300`

Tests are a dependency-free `SceneTree` script: any method named `test_*` in `tests/run_tests.gd` is discovered automatically. They run in the first `_process` frame (not `_initialize`), because nodes added to `root` during `_initialize` are not yet in the tree (no `_ready`, no physics space). Memory-leak tests compare `Performance.OBJECT_COUNT` / `OBJECT_ORPHAN_NODE_COUNT` before and after many cycles; free nodes with `free()` (not `queue_free()`) inside tests so counts are synchronous.

## Architecture

Data flow: **Plan** (what the player authored) -> `Simulator.bake` -> **Timeline** (per-tick result) -> **Player** executes it, driven by **LoopClock**.

- **Plan** (`scripts/timeline/plan.gd`): `actions`/`dirs` arrays, one entry per 0.5 s slot (`SLOT_FRAMES = 30`, `MAX_SLOTS = 24`). Pure data; `add_slots()` is how the loop grows.
- **Simulator** (`scripts/timeline/simulator.gd`): static, deterministic, no physics. Moves/dashes/clamps to the arena radius, places one-frame action events at fixed offsets within a slot (`EVENT_FRAME`), and flags wall hits on the rising edge only (one hit per wall contact, not per frame). Re-bake whenever the plan or arena radius changes.
- **Timeline** (`scripts/timeline/timeline.gd`): `RefCounted`, variable `frame_count` (default 180 = 3 s × 60 Hz; the project's physics tick rate must stay 60), preallocated packed arrays (positions, actions, facings, wall_hits). Actions are stored only on the frame they start.
- **LoopClock** (`scripts/timeline/loop_clock.gd`): single source of truth for time. Counts physics ticks, has `process_physics_priority = 100` so it advances *after* the player/echoes read `clock.frame` in the same tick. Loop length changes only on wrap via `request_loop_frames()`; `reset()` is for the (stopped) planning phase. Never index a timeline with wall-clock time.
- **PlayerController** (`scripts/player/player_controller.gd`): a plain `Node2D` (no physics body) that sets `position` from `baked.position_at(clock.frame) + nudge` and fires events via `Combat.perform` once per frame (guards against re-firing while the clock is stopped).
- **Main** (`scripts/main.gd`): planning phase (clock stopped, edits re-bake immediately) -> Enter starts execution -> edits during execution set `_dirty` and are re-baked on `loop_wrapped`. Escalation every 15 s shrinks the arena, adds slots and marks dirty. `PlannerUI` (`scripts/ui/planner_ui.gd`) and `OverlayUI` (`scripts/ui/overlay_ui.gd`: title "toque para começar" and game over, click/tap/Enter confirms, 700 ms lock on game over) are built entirely in code. `Main.skip_title` is a `static var` so "play again" (`reload_current_scene`) skips the title.
- **Touch** (`scripts/ui/touch_controls.gd`): virtual stick presses the `move_*` InputMap actions (so the player code is input-agnostic) and a Pulse button; shown on touch devices or after the first touch. Planner has a "Girar slot" toggle instead of right-click.
- **Juice** (`scripts/fx/`): `Juice` = directional shake of Main + 0.05 s hit-stop by pausing the tree (never `Engine.time_scale`; it has a cooldown and un-pauses on exit); `FxPool` = fixed pool of 12 `CPUParticles2D` for enemy shards. Enemies emit `died(enemy, by_player)`, WaveManager relays `enemy_killed`; Main batches same-tick kills (hit-stop only for 2+). Player trail is a preallocated ring buffer. Keep it allocation-free per frame.
- **PWA**: `web/pwa/` (manifest, icons from `make_icons.py`, `.gdignore`), copied into the build by `web/copy_pwa.sh` in CI.
- **Combat** (`scripts/combat/combat.gd`) is shared by player and echoes; `Projectile` is the pierce-3 spear. **WaveManager** spawns `Enemy` nodes on the edge (local offset from its own position), count = `base_count * growth_factor^(wave-1)` capped at `max_count`, next wave after `alive` hits 0 via `tree_exited`. Seed `wm.rng.seed` for deterministic tests.

Conventions:
- Arena space = Main's local space (centre at the origin). Use `position` for timeline coordinates and `global_position` for combat/distance checks; WaveManager and the echo container must stay at identity offset inside Main.
- Scripts reference each other with `preload("res://...")` constants, not `class_name`, so headless runs don't depend on the editor's global class cache. Input actions are registered in code (`scripts/input_setup.gd`), not in `project.godot`.
- GDScript warnings are treated as errors: avoid `:=` when the value is a `Variant` (annotate the type instead).

Controls: click/tap a slot to assign the selected action (keys 1-6 select it), right-click (or "Girar slot" mode on touch) rotates a slot's direction, "Direção" button sets the direction for new assignments, Enter/"Executar" starts, WASD or virtual stick nudges, Space or Pulse button, R or tap on game over restarts.
