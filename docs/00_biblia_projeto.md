# Bíblia do projeto: Echo Blade

## Conceito
Roguelike tático de ação em tela única (top-down), arena circular fechada. Você NÃO controla o personagem em tempo real: monta uma sequência de ações em slots de 0,5 s (começa com 6 = 3 s) e o personagem a executa em loop contra ondas de inimigos que crescem exponencialmente. Você só dá pequenos desvios (WASD/joystick) e usa uma habilidade de suporte de recarga longa (pulso eletromagnético).

## Ciclo
1. Planejamento: monta a coreografia (relógio parado).
2. Execução: o loop roda; inimigos geométricos surgem da borda; bater na parede custa vida.
3. Escalada: a cada 15 s a arena fecha e o loop ganha +1 s (2 slots vazios para preencher). Edições entram na próxima volta.
4. (Futuro) Mutações a cada 3 ondas e upgrades entre ondas. Runs de 3 a 5 minutos.

## Visual e sensação (alvo)
Cyber-Zen: dojo cibernético com neon sobre vidro escuro e traços de tinta (sumi-e); rastros de luz, cortes de pincelada, inimigos que se estilhaçam; hit-stop e screen shake direcional.

## Tecnologia
Godot 4.7 + GDScript. Alvo principal: navegador (Web single-thread, Compatibility), com o Safari do iPhone como referência de desempenho; depois mobile. Detalhes de arquitetura em `CLAUDE.md`.

## Time e comando
- O dono fala só com o líder (a sessão principal do Claude Code neste repositório).
- O líder quebra o trabalho, escreve briefings, delega a especialistas (subagentes) quando útil, revisa, integra, registra decisões e commita.
- Papéis de especialista: Gameplay, UI, VFX, Arte, Áudio, Plataforma/deploy, QA, Conteúdo. Cada um só altera suas pastas e nunca commita.
- Especialistas não pedem trabalho uns aos outros: pedem ao líder.
- Fonte da verdade: dono > esta Bíblia > `decisoes.md`.

## Fora de escopo por ora
Monetização, exportação de replay (GIF/TikTok 9:16), multiplayer e chefes (ver `decisoes.md`, itens [Proposta]).
