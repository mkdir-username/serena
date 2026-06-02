# Fork notes — username/serena

Локальный форк `oraios/serena`. База = этот форк (editable-install), как форк codegraph.
Upstream отслеживается через remote `upstream` + еженедельное уведомление (`scripts/check-upstream.sh`).

## Remotes
- `upstream` = https://github.com/oraios/serena.git
- (origin — добавить при заведении своего github-форка: `git remote add origin <url>`)

## Baseline
- Форкнуто от `oraios/serena` @ `c9abd9f7` (Merge PR #1539, версия `1.5.4.dev0`, между upstream-тегами v1.5.3 и v1.5.4).

## Кастомные патчи (на ветке `main`)
| Commit | Файл | Что |
|--------|------|-----|
| (rename-wait) | `src/solidlsp/ls.py` `request_rename_symbol_edit` (~:3095) | +1 строка: `self._wait_for_cross_file_references_if_needed()` перед `send.rename`. rename был единственным cross-file LSP-запросом без ожидания индексации → терял re-export specifier'ы в barrel-файлах (`export { X } from './m'`). Паритет с references/definition/implementation (`:1459`). |

**Корень (доказано live LSP-probe):** НЕ `providePrefixAndSuffixTextForRename` (эта гипотеза рефутирована — флаг ничего не меняет, ts-language-server сам инлайнит `X_V2 as X` в `newText`). Чистый race: rename летел до готовности tsserver program. Upstream-worthy bug-fix.

## Установка (база = форк)
```bash
uv tool install --editable ~/Docs/serena --force   # binary serena → форк, правки активны сразу
```
Wiring Claude Code: `~/.claude.json` → `mcpServers.serena.command = /Users/username/.local/bin/serena` (НЕ менять — binary уже указывает на форк после editable-install).

## Rollback (вернуться на upstream)
```bash
uv tool install --from git+https://github.com/oraios/serena serena --force
```

## Upstream sync (cherry-pick поверх кастома)
```bash
git fetch upstream
git log --oneline HEAD..upstream/main        # что нового
git rebase upstream/main                      # перенести кастомные коммиты поверх
# конфликт в ls.py request_rename_symbol_edit → разрешить, сохранив строку wait
uv tool install --editable ~/Docs/serena --force   # переустановить после sync
```
Уведомление о новых upstream-релизах: `scripts/check-upstream.sh` (launchd, еженедельно).

## Проверка фикса
```bash
cd /tmp/serena-rename-probe && PYTHONPATH=~/Docs/serena/src \
  /Users/username/.local/share/uv/tools/serena-agent/bin/python probe_verify.py
# RESULT: PASS — barrel re-export included
```
