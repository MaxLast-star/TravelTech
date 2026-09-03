# TravelTech IROPS

Проектная документация к кейсу «Альфред, друг Бэтмена»: система отслеживания сбоев рейсов
и автоматического перепланирования поездки.

Сайт: https://MaxLast-star.github.io/TravelTech/

## Стек документации

Docusaurus 3 в режиме docs-only. Диаграммы BPMN рендерятся через `bpmn-js`,
схемы — через `@docusaurus/theme-mermaid`, REST-контракт — через `redocusaurus`.

## Структура

| Путь | Содержимое |
|---|---|
| `docs/` | Страницы документации |
| `static/bpmn/` | Исходники `.bpmn` и `.dmn` — открываются в Camunda Modeler, они же отдаются вьюверу |
| `static/api/` | `openapi.yaml`, `asyncapi.yaml` |
| `src/components/BpmnViewer/` | Компонент-обёртка над bpmn-js |
| `architecture/` | `workspace.dsl` для Structurizr |
| `db/` | `schema.dbml` |

Диаграммы и спеки лежат в `static/`, поэтому источник правды один: Camunda Modeler и
Structurizr работают с теми же файлами, которые отдаёт сайт.

## Запуск

```powershell
npm install
npm start
```

Сайт поднимется на http://localhost:3000.

## Публикация

Пуш в `main` запускает `.github/workflows/deploy.yml`.

Один раз перед первым деплоем: Settings → Pages → Source → **GitHub Actions**.

## Встраивание диаграммы в страницу

```mdx
import BpmnViewer from '@site/src/components/BpmnViewer';

<BpmnViewer file="/bpmn/p01-disruption.bpmn" />
```

Путь задаётся от корня `static/`. `baseUrl` подставляется автоматически, поэтому
одинаково работает и локально, и на GitHub Pages. Страницы с импортом компонента
имеют расширение `.mdx`.

## Соглашения об идентификаторах

| Сущность | Формат ID | Пример |
|---|---|---|
| Функциональное требование | `FR-<ДОМЕН>-<NN>` | `FR-ALT-03` |
| Нефункциональное требование | `NFR-<КАТ>-<NN>` | `NFR-PERF-01` |
| Процесс и задача | `P-<NN>`, `P-<NN>.T<n>` | `P-01.T4` |
| Компонент архитектуры | `C-<ИМЯ>` | `C-ORCH` |
| Критерий приёмки | `AC-<ID требования>-<n>` | `AC-ALT-03-1` |
| Событие | `<домен>.<событие>.v<N>` | `disruption.detected.v1` |

`id` элементов в Camunda Modeler задаются вручную по этому формату — на них ссылается
матрица трассировки.
