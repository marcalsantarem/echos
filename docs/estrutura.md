# Estrutura do código

## Pastas e dependências
- `scripts/timeline/`: dados e simulação puros (Plan, Simulator, Timeline, LoopClock). Não conhecem UI, cena nem inimigos.
- `scripts/combat/`, `scripts/player/`, `scripts/echo/`, `scripts/waves/`: partida. Dependem de `timeline/`; não conhecem a UI.
- `scripts/ui/`: só liga sinais e exibe; não contém regra de jogo.
- `scripts/main.gd`: orquestra a partida (única peça que conhece todas).
- `tests/`: suíte headless; um arquivo com erro de parse não roda: confira que o teste novo aparece entre os executados.
- Balanceamento (dano, velocidades, raios) deve migrar para `Resource` `.tres` em vez de constantes espalhadas (a fazer, quando o conteúdo crescer).
- Autoloads só para serviços globais; em scripts `-s` acessar por `/root/Nome`.

## Convenções
- Identificadores de código em inglês; docs, commits e conversa em pt-BR.
- Ids de conteúdo em snake_case com prefixo: `enemy_`, `skill_`, `ui_`, `sfx_`, `mus_`.
- Scripts se referenciam por `preload("res://...")`, sem `class_name` (headless não depende do cache de classes).
- Warnings do GDScript são erros: evitar `:=` com valor `Variant`.
- Aceleração/atalhos nunca alteram recompensa: nada na economia depende de tempo real.
