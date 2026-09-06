---
title: Матрица трассировки
---

# Матрица трассировки

Каждое требование связано с процессом, интерфейсом, данными, компонентом архитектуры
и способом проверки. Матрица нужна для двух вопросов: «на чём держится это требование»
и «зачем в решении эта таблица, этот шаг, этот контейнер».

Прочерк в ячейке означает, что опоры нет. Все прочерки перечислены и объяснены
в разделе [Пробелы](#пробелы) — молча их в матрице не остаётся.

Сокращения в колонках: `P-xx.Tn` — шаг процесса, `C-*` — контейнер или компонент
архитектуры, имена вида `disruption.detected.v1` — каналы шины, остальное в колонке
интерфейса — операции REST. Таблицы ERD даны без имени схемы, если оно очевидно
из контекста.

## Функциональные требования

Критерий приёмки у каждого ФТ один и называется по требованию: `FR-ALT-03` проверяется
сценарием `AC-ALT-03-1`. Полные тексты — в [критериях приёмки](./acceptance.md), в
матрице колонка сокращена до номера сценария.

### Приём статусов рейсов

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-ING-01` три типа источников | — | вебхук `flightStatusPushed`, `flight.status.received.v1` | `status_source`, `flight_status_event` | `C-INGEST` | `AC-ING-01-1` |
| `FR-ING-02` два времени и ранг источника | — | `flight.status.received.v1` | `flight_status_event` | `C-INGEST` | `AC-ING-02-1` |
| `FR-ING-03` дубли, опоздания, противоречия | — | `flight.status.received.v1` | `flight_status_event`, `flight_state` | `C-DETECT` | `AC-ING-03-1` |
| `FR-ING-04` порог свежести | — | `getBooking`, поле `freshness` | `flight_state.stale_after` | `C-DETECT` | `AC-ING-04-1` |

### Детекция сбоя

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-DET-01` типы сбоя | `P-01.S1` | `disruption.detected.v1` | `disruption` | `C-DETECT` | `AC-DET-01-1` |
| `FR-DET-02` misconnect по MCT | — | `disruption.detected.v1` | `mct_rule`, `disruption_impact.applied_mct_minutes` | `C-DETECT` | `AC-DET-02-1` |
| `FR-DET-03` повторный сбой | `P-01.SUB1`, `P-01.T7` | `disruption.detected.v1` с `supersedes_disruption_id` | `disruption.supersedes_disruption_id`, `processed_event` | `C-ORCH-INBOX` | `AC-DET-03-1` |

### Оценка влияния

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-IMP-01` затронутые элементы и класс влияния | `P-01.T1`, `P-01.G1` | `getDisruption` | `disruption_impact`, `disruption.impact_class` | `C-ORCH-IMPACT` | `AC-IMP-01-1` |
| `FR-IMP-02` невозвратные и сумма потерь | `P-01.T1` | `getDisruption` | `disruption_impact.is_non_refundable`, `.estimated_loss_minor` | `C-ORCH-IMPACT` | `AC-IMP-02-1` |

### Подбор альтернатив

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-ALT-01` подбор и ранжирование | `P-02.T1`, `P-02.T2`, `P-02.T7` | `listAlternatives` | `alternative_search`, `alternative`, `alternative_segment` | `C-ALT` | `AC-ALT-01-1` |
| `FR-ALT-02` проверка MCT | `P-02.T3` | `listAlternatives` | `constraint_check`, `mct_rule` | `C-ALT` | `AC-ALT-02-1` |
| `FR-ALT-03` проверка багажа | `P-02.T5` | `listAlternatives` | `constraint_check`, `alternative.baggage_pieces` | `C-ALT` | `AC-ALT-03-1` |
| `FR-ALT-04` проверка транзитной визы | `P-02.T4` | `listAlternatives` | `constraint_check`, `traveller.citizenship_country` | `C-ALT` | `AC-ALT-04-1` |
| `FR-ALT-05` проверка таймзон | `P-02.T3` | `listAlternatives` | `airport.timezone`, `alternative_segment` | `C-ALT` | `AC-ALT-05-1` |
| `FR-ALT-06` разница тарифа и вынужденность | `P-02.T9` | `listAlternatives` | `alternative.fare_difference_minor`, `.is_involuntary` | `C-ALT` | `AC-ALT-06-1` |
| `FR-ALT-07` проверки до показа | `P-02.SUB1`, `P-02.G2` | `listAlternatives` | `constraint_check`, `alternative.verdict` | `C-ALT` | `AC-ALT-07-1` |
| `FR-ALT-08` перенос активностей | `P-02.T8` | — | — | `C-ALT` | `AC-ALT-08-1` |

### Уведомления

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-NTF-01` лестница каналов, одно активное | `P-01.E1`, `P-01.M2` | `disruption.notified.v1`, `decision.requested.v1` | `notification.supersedes_notification_id`, `channel_preference` | `C-NOTIFY` | `AC-NTF-01-1` |
| `FR-NTF-02` переход по подтверждению доставки | `P-01.B2`, `P-01.E4` | `notification.delivery.reported.v1`, `decision.reminded.v1` | `delivery_attempt.sent_at`, `.confirmed_at` | `C-NOTIFY` | `AC-NTF-02-1` |
| `FR-NTF-03` состав уведомления | `P-01.M2` | `decision.requested.v1` | `notification.respond_by`, `airport.timezone` | `C-NOTIFY` | `AC-NTF-03-1` |
| `FR-NTF-04` оффлайн видит решение при входе | `P-01.M3` | `getDisruption` | `notification`, `decision.reason` | `C-API`, `C-ORCH-STATE` | `AC-NTF-04-1` |
| `FR-NTF-05` адресация в группе | `P-01.M3` | `plan.updated.v1`, `listParticipants` | `notification.participation_id`, `plan_version` | `C-PLAN`, `C-NOTIFY` | `AC-NTF-05-1` |

### Принятие решения

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-DEC-01` выбор от путешественника или организатора | `P-01.T3` | `submitDecision`, `decision.submitted.v1` | `decision`, `organizer_mandate` | `C-ORCH-DECISION` | `AC-DEC-01-1` |
| `FR-DEC-02` ack-окно и авто-политика | `P-01.B1`, `P-01.T4` | `decision.submitted.v1` | `disruption.ack_deadline_at`, `auto_policy.scope` | `C-ORCH-DECISION` | `AC-DEC-02-1` |
| `FR-DEC-03` доплата только с согласия | `P-01.T4`, DMN `auto-rebooking-policy` строка 1 | `putBookingAutoPolicy` | `auto_policy.payer_consent_at`, `.max_surcharge_minor` | `C-ORCH-DECISION` | `AC-DEC-03-1` |
| `FR-DEC-04` эскалация с контекстом | `P-01.G4`, `P-01.T6`, `P-01.E3` | `listDisruptions` | `decision.source`, `constraint_check.reason` | `C-ORCH-DECISION`, `C-WEB` | `AC-DEC-04-1` |
| `FR-DEC-05` поздний ответ | `P-01.SUB2`, `P-01.T8`, `P-01.M4` | ошибка `decision-already-applied` | `decision.applied_at` | `C-ORCH-DECISION` | `AC-DEC-05-1` |

### Перебронирование

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-REB-01` один билет на сбой | `P-03.T1`, `P-03.T4`, `P-03.T5` | вебхук `rebookingCompleted` | `rebooking.operation_key` | `C-REBOOK` | `AC-REB-01-1` |
| `FR-REB-02` тариф, доплата, возврат | `P-03.G1`, `P-03.T2`, `P-03.G3`, `P-03.T6` | `getDisruptionSettlement` | `rebooking.is_involuntary`, `.fare_difference_minor`, `.refund_minor` | `C-REBOOK` | `AC-REB-02-1` |
| `FR-REB-03` компенсация при неуспехе | `P-03.M1`, `P-03.C1`–`C3`, `P-01.B3` | — | `rebooking.state`, `.failure_reason` | `C-REBOOK` | `AC-REB-03-1` |
| `FR-REB-04` повторы и отказ перевозчика | `P-03.B6`, `P-03.T8` | — | `rebooking.attempts`, `.failure_reason` | `C-REBOOK` | `AC-REB-04-1` |

### Обновление плана поездки

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-PLN-01` замена сегментов и версия плана | `P-03.T7` | `plan.updated.v1`, `getTripPlan`, `listPlanVersions` | `plan_version`, `plan_item`, `segment.replaced_by_segment_id` | `C-PLAN` | `AC-PLN-01-1` |
| `FR-PLN-02` зависимые элементы | `P-02.T6`, `P-03.T3` | `getTripPlan` | `plan_item.state` | `C-PLAN` | `AC-PLN-02-1` |
| `FR-PLN-03` невозвратный элемент | — | `getTripPlan` | `plan_item.is_refundable` | `C-PLAN` | `AC-PLN-03-1` |

### Групповые поездки

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-GRP-01` роль на участии | — | `listParticipants` | `trip_participation.role` | `C-PLAN`, `C-API` | `AC-GRP-01-1` |
| `FR-GRP-02` мандат на момент выбора | `P-01.M2`, `P-01.T3` | `grantMandate`, `revokeMandate` | `organizer_mandate`, `decision.mandate_id` | `C-ORCH-DECISION` | `AC-GRP-02-1` |
| `FR-GRP-03` отказ от общего решения | — | `optOutOfGroupDecision` | `decision.source` | `C-API`, `C-ORCH-DECISION` | `AC-GRP-03-1` |
| `FR-GRP-04` неуспех у одного не откатывает остальных | — | `submitGroupDecision` | `rebooking` по одному на бронирование | `C-REBOOK` | `AC-GRP-04-1` |

### Паспортные данные

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Приёмка |
|---|---|---|---|---|---|
| `FR-PII-01` отдельный контур | `P-04.S1`, `P-04.T1` | — | схема `pii` целиком | `C-PII`, `C-VAULT` | `AC-PII-01-1` |
| `FR-PII-02` наружу ссылка и маска | — | `getBooking`; метода чтения документа нет | `travel_document.mask`, `booking.pii_document_ref` | `C-API`, `C-PII` | `AC-PII-02-1` |
| `FR-PII-03` срок удержания и удаление | `P-04.I1`, `P-04.T2`, `P-04.T4`, `P-04.M1` | `getPurgeReport`, `pii.purge.mismatch.v1` | `travel_document.retention_due_at`, `purge_run`, `purge_record` | `C-RETENT` | `AC-PII-03-1` |
| `FR-PII-04` журнал доступа | `P-04.T5` | — | `document_access_log` | `C-PII` | `AC-PII-04-1` |
| `FR-PII-05` доступ оператора на срок | — | — | `access_grant` | `C-PII` | `AC-PII-05-1` |
| `FR-PII-06` минимум полей провайдеру | `P-03.T4` | внутренний интерфейс `C-PII` | состав колонок `travel_document` | `C-REBOOK`, `C-PII` | `AC-PII-06-1` |
| `FR-PII-07` досрочное удаление | — | `deleteTravelDocument` | `travel_document`, `purge_record` | `C-PII`, `C-RETENT` | `AC-PII-07-1` |

## Нефункциональные требования

У НФТ нет сценария в Gherkin: вместо него в последней колонке стоит способ проверки
из [нефункциональных требований](./non-functional.md), где у каждого записаны число и
порог.

| Требование | Процесс | Интерфейс или топик | Таблицы | Компонент | Способ проверки |
|---|---|---|---|---|---|
| `NFR-PERF-01` время до детекции | `P-01.S1` | `flight.status.received.v1` → `disruption.detected.v1` | `flight_status_event.event_at`, `.ingest_at` | `C-INGEST`, `C-DETECT` | нагрузочный тест 2000 сообщений/с |
| `NFR-PERF-02` время до уведомления | `P-01.M2` | `decision.requested.v1` | `notification.created_at` | `C-ORCH`, `C-NOTIFY` | нагрузочный тест, дашборд сценария |
| `NFR-PERF-03` отклик операций | `P-02` целиком | `listAlternatives`, `getTripPlan` | — | `C-ALT`, `C-API` | нагрузочный тест с эмуляцией внешних систем |
| `NFR-REL-01` сообщение не теряется | — | все каналы `C-BUS` | `outbox_event`, `processed_event` | `C-BUS`, `C-ORCH-STATE` | chaos-тест с падением обработчика |
| `NFR-REL-02` восполнение после связи | — | — | `flight_state.recomputed_at` | `C-INGEST` | отключение источника на 30 минут |
| `NFR-REL-03` деградация вместо отказа | `P-02.B2`, повторы `P-03` | — | `alternative_search.outcome` | `C-ALT`, `C-REBOOK`, `C-NOTIFY` | chaos-тест по каждой внешней системе |
| `NFR-REL-04` устаревший статус | — | `getBooking`, поле `freshness` | `flight_state.stale_after` | `C-DETECT` | приостановка потока по одному сегменту |
| `NFR-REL-05` сбой без завершающего состояния | `P-01.E1`–`E3` | — | `disruption.state`, `.closed_at` | `C-ORCH-STATE` | ежесуточная сверка, алерт |
| `NFR-SEC-01` доступ к контуру | — | — | `access_grant`, `travel_document.key_version` | `C-PII`, `C-VAULT` | доступ от неразрешённого субъекта |
| `NFR-SEC-02` журнал неизменяем | — | — | `document_access_log` | `C-VAULT` | ревью прав, попытка изменения записи |
| `NFR-SEC-03` ПДн не покидают контур | — | конверт события без реквизитов документа | `travel_document`, `mask` | `C-PII` | поиск по шаблонам на каждой сборке |
| `NFR-COMP-01` срок удержания соблюдён | `P-04` целиком | `getPurgeReport` | `retention_due_at`, `purge_record` | `C-RETENT` | ежесуточная сверка, учения по восстановлению |
| `NFR-COMP-02` требования 152-ФЗ | `P-04.T4` | `createTravelDocument` | `consent` | `C-PII` | ревью размещения, реестр передач |
| `NFR-COMP-03` только нужные поля | — | — | состав колонок `travel_document` | `C-PII` | ревью схемы при каждом изменении |
| `NFR-OBS-01` основание решения | `P-01.T4`, `P-01.T6` | `getDisruption` | `decision.source`, `.reason`, `.mandate_id` | `C-ORCH-STATE` | автотест на решение без основания |
| `NFR-OBS-02` метрики и алерты | `P-04.M1` | `pii.purge.mismatch.v1` | `purge_run.overdue_left_count` | все контейнеры | учебное срабатывание каждого алерта |
| `NFR-SCAL-01` объём и пики | — | партиции `flight.status.received.v1` | `flight_status_event` | `C-INGEST`, `C-BUS` | нагрузочный тест по каждому режиму |
| `NFR-SCAL-02` порядок при масштабировании | — | ключ `booking_id` у `disruption.detected.v1` | `disruption` | `C-BUS`, `C-DETECT` | перемешанный порядок доставки |
| `NFR-SCAL-03` новый источник | — | `flight.status.received.v1` | `status_source` | `C-INGEST` | добавление тестового источника |

## Пробелы

Тридцать шесть прочерков на 64 требования, и распределены они неравномерно:
двадцать два в колонке процессов, двенадцать в интерфейсе, два в таблицах.
Колонки компонента и критерия приёмки заполнены у всех требований без исключения —
требования, которое не лежит ни в одном контейнере или которое нечем проверить,
в решении нет.

Четыре причины закрывают тридцать два прочерка из тридцати шести.

**Приём и детекция не смоделированы процессом.** `P-01` стартует сообщением
`disruption.detected.v1`, то есть уже после того, как сбой установлен. Всё, что до
этого — приём из трёх источников, дедупликация, разрешение противоречий, порог
свежести, — конвейер обработки сообщений, для которого BPMN не предназначен. Так
остались без процесса `FR-ING-01`–`04`, `FR-DET-02`, `NFR-REL-01`, `NFR-REL-02`,
`NFR-REL-04`, `NFR-SCAL-01`–`03`. Опора у них есть в трёх остальных колонках.

**Свойство данных или прав — не шаг процесса.** Роль на участии, состав полей
документа, права на контур ПДн, неизменяемость журнала: `FR-GRP-01`, `FR-PII-02`,
`FR-PII-05`, `FR-PII-07`, `NFR-SEC-01`–`03`, `NFR-COMP-03`. Проверяются ревью схемы
и прав доступа, что и стоит в колонке проверки.

**Отсутствие метода бывает выполнением требования.** `FR-PII-01`, `FR-PII-04`,
`NFR-SEC-01`, `NFR-SEC-02`, `NFR-COMP-03`, `FR-PII-05` держатся ровно на том, что
наружу ничего не выходит: внешнего метода чтения паспортных данных нет, журнал
доступа наружу не отдаётся. Прочерк здесь — это и есть закрытое требование.

**Поведение при отказе снаружи не видно.** `FR-REB-03`, `FR-REB-04`, `NFR-REL-02`,
`NFR-REL-03`, `NFR-REL-05` описывают, что система делает, когда провайдер молчит.
Клиенту видно только конечное состояние сбоя, отдельного метода у компенсации и
повторов нет и не нужно.

Оставшиеся четыре — настоящие дыры:

| Пробел | Что отсутствует | Что делать |
|---|---|---|
| `FR-ALT-08` перенос активностей | Ни таблицы, ни поля в ответе. Требование держится на одном шаге `P-02.T8` | Добавить предложенные переносы в схему `alternative` и в ответ `listAlternatives` — либо снять требование как не следующее из условия |
| `FR-PLN-03` невозвратный элемент | Данные и метод есть, шага нет: `P-03` не спрашивает путешественника о невозвратной активности | Шаг после `P-03.T7` или отдельный запрос из `P-01` |
| `FR-GRP-03` отказ участника от общего решения | Операция REST есть, в BPMN ветки нет | Оставить и сказать прямо: ветка повторила бы шаги `P-01` целиком, отличаясь только адресатом |
| `FR-GRP-04` частичный неуспех в группе | То же: операция есть, в процессе не показано | Пометка на `P-01.T5` о том, что вызов идёт по одному на бронирование |

Последние два — сознательный размен читаемости диаграммы на полноту матрицы.
Групповая механика лежит в требованиях, в данных и в трёх операциях REST; в `P-01`
она выражена одной точкой `P-01.M2` «Запросить решение у ответственного».

## Покрытие условий кейса

Шесть обязательных условий приёмочного чек-листа и требования, которыми каждое закрыто.
Ни одно не подразумевается: у каждого есть требование с критерием приёмки,
таблица в модели данных и контейнер, который за него отвечает.

| Условие | Требования | Где видно в решении |
|---|---|---|
| Данные приходят с задержкой | `FR-ING-02`, `FR-ING-03`, `FR-ING-04`, `FR-DET-03`, `NFR-REL-04` | `flight_status_event` с двумя временами, `flight_state.stale_after`, `C-DETECT` |
| Пользователь может быть оффлайн | `FR-NTF-01`, `FR-NTF-02`, `FR-NTF-04`, `FR-DEC-02`, `FR-DEC-03`, `FR-DEC-05` | Лестница каналов и ack-окно в `P-01`, DMN `auto-rebooking-policy`, `P-01.SUB2` |
| Багаж, визы, таймзоны | `FR-ALT-02`–`FR-ALT-05`, `FR-ALT-07` | Подпроцесс проверок `P-02.SUB1`, таблица `constraint_check`, `C-ALT` |
| Паспортные данные не дольше нужного | `FR-PII-01`–`FR-PII-07`, `NFR-COMP-01` | `P-04`, схема `pii` в отдельном инстансе, `C-RETENT` |
| Групповые поездки | `FR-GRP-01`–`FR-GRP-04`, `FR-NTF-05` | `trip_participation.role`, `organizer_mandate`, `C-PLAN` |
| Отказы внешних API | `FR-REB-03`, `FR-REB-04`, `FR-DEC-04`, `NFR-REL-02`, `NFR-REL-03` | Сага с компенсациями в `P-03`, [отказоустойчивость](../architecture/resilience.md) |
