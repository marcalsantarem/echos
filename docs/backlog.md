# Backlog

Reflete o estado real confirmado pelo líder. Status: a fazer | em andamento | em validação | feita | bloqueada.
Task = pequena, verificável, um dono, com "pronto quando" testável.

## M1 - v0.1.0 Vertical slice

| ID | Título | Dono | Status | Pronto quando | Deps |
|----|--------|------|--------|---------------|------|
| T-001 | Núcleo: Plan, Simulator, Timeline, LoopClock, Player, WaveManager, planner UI e testes | Gameplay | feita | 62 checagens passando; cena roda sem erro | - |
| T-002 | Pipeline de deploy Web (Actions + Netlify, export preset, shell) | Plataforma | feita (falta medir no iPhone) | push em `dev` publica `dev--echosgame.netlify.app` que abre e roda (confirmado pelo dono) | segredos do dono |
| T-003 | Tela inicial "toque para começar" e fim de jogo com reinício por toque/clique | UI | feita (falta testar no navegador e no iPhone) | jogável no navegador sem teclado para iniciar/reiniciar | T-002 |
| T-004 | Juice básico: hit-stop 0,05 s, screen shake, rastro do personagem, estilhaços dos inimigos | VFX | feita (falta ver e medir FPS no iPhone) | hit-stop 0,05 s em grupo (2+ mortes), tremor direcional, rastro ciano, estilhaços em pool de 12 CPUParticles2D; sem alocação por quadro | T-002 |
| T-005 | Controles de toque: planejar com toque (slots/paleta) e desvio por joystick virtual | UI | a fazer | planejável e jogável num iPhone | T-003 |
| T-006 | Ícones/manifesto PWA e favicon | Plataforma | a fazer | `copy_pwa` equivalente no CI; instalável | T-002 |
