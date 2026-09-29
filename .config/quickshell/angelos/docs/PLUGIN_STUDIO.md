# Мастер плагинов / Plugin Studio

## Как пользоваться

1. **Настройки → System → Разработка → Режим разработчика.**
   В настройках и меню «Пуск» появится **Мастер плагинов**.
2. Выбери, как подключаться:
   - **Claude · вход через браузер** или **Codex · вход через ChatGPT** — без
     API-ключа. Мастер использует установленные `claude` (Claude Code) или
     `codex` и твою подписку. Кнопка **Войти через браузер** открывает терминал с
     `claude auth login` / `codex login`, они сами открывают браузер; затем
     **Проверить вход**. angelOS не видит токены входа.
     Claude запускается без инструментов, MCP и пользовательских настроек/хуков
     (`--tools "" --strict-mcp-config --setting-sources ""`), API-ключ из окружения
     убирается, чтобы шла именно подписка. Codex — без shell, веб-поиска, MCP,
     computer use и приложений, песочница только на чтение, в пустой временной папке.
     Запросы расходуют лимиты подписки. Модель можно оставить пустой.
   - **OpenAI API** или **Anthropic API** — вставь API-ключ и нажми
     **Сохранить ключ**; запросы оплачиваются отдельно через API. Нужна модель с
     поддержкой structured outputs.
3. Опиши идею. Мастер объяснит, что будет делать плагин, предложит размеры,
   настройки, источники данных и зависимости. Если нужны уточнения, ответь
   в поле запроса; кнопки вариантов ответа добавляют текст в это поле.
4. Нажми **План подходит — создать плагин**. Получишь полные файлы плагина,
   описание и результаты проверки. Можно уточнить план, пересоздать плагин
   или открыть файлы и отредактировать их в своём редакторе.
5. Просмотри код, затем нажми **Установить**. Плагин включится и появится в
   **Настройки → Плагины**. Для виджета можно сразу добавить экземпляр на
   текущий экран; позднее его можно добавить через настройки виджетов или ПКМ.

ИИ получает [контракт генерации](STUDIO_CONTRACT.md), [API плагинов](PLUGINS.md)
и исходники основных компонентов angelOS. Виджеты используют текущую тему,
`Theme.u`, стандартные элементы управления и переключатель языка. Рамку,
перетаскивание и размещение на мониторе обеспечивает оболочка.

Диалог, план и последний результат сохраняются между перезапусками.
Закрытие окна настроек не прерывает запрос. Набранный, но ещё не отправленный
текст сохраняется при переходе между страницами до перезапуска оболочки.
**Новый плагин** начинает отдельный диалог; уже установленные плагины остаются.
Выключение режима разработчика скрывает мастер и отменяет запрос к ИИ,
но установленные плагины продолжают работать.

## Пример с лимитами Codex

«Хочу виджет с оставшимися токенами Codex» требует уточнения источника:
API-ключ сам по себе не даёт остаток лимита подписки ChatGPT/Codex.
Контракт запрещает выдумывать такой endpoint или выдавать rate limit за
баланс. Мастер должен уточнить метрику и предложить доступный источник,
пользовательский экспорт либо явно обозначенный собственный бюджет.
Учёт токенов последнего запроса в самом мастере — расход API-запроса,
а не остаток подписки.

## Файлы и проверка

- Ключи: `~/.config/angelos/studio/credentials.json`, права `0600`,
  каталог `0700`. Их можно удалить кнопкой в мастере. Это локальный файл,
  не системное зашифрованное хранилище.
- Диалог и черновики: `~/.local/state/angelos/studio/`.
- Установленные плагины: `~/.config/angelos/plugins/<id>/`.
- В обычном `settings.json` хранятся только режим разработчика, провайдер,
  модель и лимит ответа. Эти пользовательские каталоги не публикуются.

Ключ передаётся worker-процессу через stdin, а провайдеру — только в заголовке
авторизации. Модели отправляются диалог, документация angelOS и файлы черновика
при исправлении; пользовательские файлы автоматически не сканируются.
Ключи не передаются генерируемому плагину.

До установки сгенерированный код не запускается. Проверяются manifest,
точки встраивания, имена/размеры файлов, синтаксис QML через **Qt 6 qmlformat**,
Python, JSON и shell. Проверка синтаксиса не гарантирует правильную работу
импортов, внешних сервисов или поведения. После установки код работает с
правами текущего пользователя.

Установка не заменяет существующий ID и не запускает установочные скрипты.
После ручных правок нужно нажать **Проверить ещё раз**: установка сверяет
файлы с просмотренным результатом. Сейчас мастер создаёт новые плагины;
обновление уже установленного плагина под тем же ID выполняется вручную.

При ошибке синтаксиса доступно **Исправить с ИИ**. При неполном ответе
увеличь лимит ответа или упрости задачу. Ошибка 401 означает отклонённый
ключ, 404 — недоступную модель, 429 — ограничение API. Автоматических платных
повторных запросов нет. Отмена останавливает локальное ожидание; уже
отправленный запрос провайдер мог учесть.

## English

Enable **Settings → System → Development → Developer mode**. Open
**Plugin Studio** in Settings or Start and pick a connection:

- **Claude · browser sign-in** / **Codex · ChatGPT sign-in** use the local
  `claude` or `codex` CLI and your subscription — no API key. **Sign in via
  browser** opens a terminal with `claude auth login` / `codex login`; then
  **Check sign-in**. angelOS never sees the tokens. Claude runs with no tools,
  MCP or user settings/hooks; Codex without shell, web search, MCP or computer
  use, read-only, in an empty temporary folder.
- **OpenAI API** / **Anthropic API** need an API key (separate API billing).
  The model must support structured outputs.

Describe the plugin, answer any questions, review its proposed behavior,
size, data sources and settings, then approve generation. Review the files
before clicking **Install**. Installation enables the plugin and optionally
adds its desktop widget to the current screen. Manage it in **Settings →
Plugins**. Turning off developer mode hides Studio without disabling plugins.

Studio sends the conversation and angelOS's plugin contract/component sources
to the selected provider. A repair request also includes the draft files.
Credentials are stored separately in a local `0600` file and passed via stdin,
never command-line arguments or generated plugin settings.

The conversation and draft survive restarts; unsent input survives navigating
between Settings pages during the current shell session. Closing Settings
does not cancel an active request.

Drafts are checked without executing them. The checks cover manifest structure,
file paths, required entry points and QML/Python/JSON/shell syntax. They do not
prove runtime correctness. Installed plugins run as your desktop user. Existing
plugin IDs are never overwritten. After editing files externally, use
**Recheck files** before installing. Studio creates new plugins; updating an
installed ID is currently a manual operation.

For “remaining Codex tokens,” Studio must clarify the actual metric and data
source instead of inventing a subscription-balance API. Its own token counter
shows the last API request's usage, not a subscription's remaining allowance.

## Development

`scripts/plugin-studio.py` uses the Python standard library. The providers use
OpenAI Responses (`text.format`, JSON Schema, `store: false`) and Anthropic
Messages (`output_config.format`, JSON Schema). Provider endpoints are fixed;
redirects never forward credentials.

Run `python3 scripts/test-plugin-studio.py` from the repository root for offline
provider/validation/installation tests, or `./scripts/check.sh` for all checks.
