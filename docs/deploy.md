# Deploy Web (Echos)

Build e deploy rodam no GitHub Actions (`.github/workflows/deploy-web.yml`); o Netlify só hospeda (`netlify.toml` sem comando de build, deploy com `--no-build`).

## Passo a passo (validado em 2026-11-10)
1. Site Netlify `echosgame`. Segredos do repo `marcalsantarem/echos` (cadastrados pelo dono): `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`. Sem eles o deploy é pulado com aviso.
2. Push em `dev` -> CI: baixa Godot 4.7.2 e template `web_nothreads` (SHA512 conferido, com cache), importa, roda `tests/run_tests.gd`, exporta o preset "Web", injeta `window.ECHOS_BUILD` (sha, branch, data, run) e publica em `https://dev--echosgame.netlify.app`.
3. Release: o dono pede o PR `dev` -> `main`; após o merge, `git tag v0.x.0 && git push origin v0.x.0` na `main` publica `https://v0-x-0--echosgame.netlify.app` e cria a GitHub Release com o zip. Tag nunca vai para produção.

## PWA
- Manifesto e ícones em `web/pwa/` (pasta com `.gdignore`, fora do import e do pck). Ícones originais gerados por `python web/pwa/make_icons.py` (registrado em `assets/LICENSES.md`).
- O CI roda `web/copy_pwa.sh build/web` depois do export: copia manifesto e ícones e sobrescreve `index.icon.png`/`index.apple-touch-icon.png`. Sem service worker (não há modo offline).
- No iPhone: Safari > Compartilhar > Adicionar à Tela de Início. Falta confirmar num aparelho real.

## Local
- Export: `& $g --headless --path . --export-release "Web" build/web/index.html` (templates em `%APPDATA%\Godot\export_templates\4.7.2.stable`). `build/` é ignorado pelo git.
- Servir: `python -m http.server -d build/web` e abrir `http://localhost:8000`.

## Restrições
- Single-thread, renderer Compatibility (roda sem COOP/COEP e no Safari do iPhone). Alvo de desempenho: Safari do iPhone.
- Wasm/pck/js sem hash no nome: `Cache-Control: max-age=0, must-revalidate`.
- Áudio só toca após o primeiro toque do usuário (quando houver áudio, tela "toque para começar").
- Pouca Energia no iPhone limita o rAF a 30 fps; `Engine.time_scale` altera o passo de física (projéteis rápidos podem atravessar alvos).
- Evitar alocação por quadro; preferir pools/CPUParticles; manter .pck/.wasm enxutos.
