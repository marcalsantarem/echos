# Fluxo de git e releases (Echos)

Adotado em 2026-11-10 (decisão D-03), a partir do método do Project Anima.

## Branches
- `main`: protegida (o dono liga a proteção no GitHub). Sem push direto; só PR de `dev` para `main`, aberto **somente quando o dono pedir**, ao fechar um marco.
- `dev`: única branch de trabalho e única onde se faz commit. Não criar feature/fix/branch por versão sem pedido do dono.
- Só o líder (a sessão que fala com o dono) commita e dá push, agrupando o trabalho ao concluir uma etapa. Cada commit deixa o projeto abrindo sem erro e com os testes passando.
- Commits em português, curtos, no imperativo. Versões fechadas ficam só em **tag** (`v0.x.0`).

## Release
1. O dono pede o PR `dev` -> `main`; após o merge, o líder cria a tag na `main`: `git tag v0.x.0 && git push origin v0.x.0`.
2. O CI (`.github/workflows/deploy-web.yml`) testa, exporta e publica:
   - `dev` -> https://dev--echosgame.netlify.app
   - `main` -> https://echosgame.netlify.app (produção)
   - tag -> https://<tag normalizada>--echosgame.netlify.app (ex. `v0.1.0` -> `v0-1-0--echosgame.netlify.app`), nunca produção, mais uma GitHub Release com o zip do build.
3. Segredos do repo (só o dono cadastra): `NETLIFY_AUTH_TOKEN` e `NETLIFY_SITE_ID`. Sem eles o CI testa e exporta, mas pula o deploy com aviso.

## Regras de trabalho
- Task: pequena, verificável, um dono, critério de "pronto quando", pertence a um marco (ver `backlog.md`). Tasks que mexem nos mesmos arquivos não rodam em paralelo.
- Trabalho delegado a especialista (subagente) exige briefing em `docs/briefings/BRF-xxx_<entrega>.md` (modelo em `_modelo.md`). Especialista não commita nem mexe em `project.godot`/Input Map sem autorização no briefing; o líder valida (suíte completa) antes de commitar.
- Fonte da verdade: dono > `00_biblia_projeto.md` > `decisoes.md`. Itens `[Proposta]`/`[A definir]` não são regra: perguntar antes.
- Fechar marco: validação (testes + jogo aberto), líder fecha com o aval do dono; a tag só sai quando o dono pedir. Ao fechar etapa, reportar duas listas: concluídas (ID e descrição) e próximas (ID, descrição, responsável).
- Economia de tokens: respostas curtas, ler só trechos, commit por etapa, filtrar saídas longas.

## Armadilhas conhecidas (Godot/GDScript)
- `const` com `PackedInt32Array` não compila.
- Em scripts `-s`, autoloads só por `/root/Nome`.
- `--import` pode deixar lixo `.import`/cache; `.godot/` já está no `.gitignore`.
