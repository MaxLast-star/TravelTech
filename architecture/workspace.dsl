workspace "TravelTech IROPS" "Отслеживание сбоев рейсов и перепланирование поездки" {

    !identifiers hierarchical

    model {
        traveller = person "Путешественник" "Роль в конкретной поездке — организатор или участник — хранится на участии, а не на человеке." "Human"
        operator = person "Оператор поддержки" "Разбирает сбои, которые система не закрыла автоматически. Доступ к паспортным данным — по конкретному сбою, с обоснованием, на срок." "Human"

        statusAggregator = softwareSystem "Провайдер статусов рейсов" "Агрегатор статусов по подписке на бронирования. Широкое покрытие, средняя точность." "External"
        carrierGds = softwareSystem "Перевозчик или GDS" "Push об изменении и служебные рассылки по своим рейсам. Наивысший ранг достоверности, неполное покрытие." "External"
        bookingProvider = softwareSystem "Провайдер бронирования" "Поиск рейсов, удержание места, выпуск билета по PNR, отмена и возврат." "External"
        constraintsRef = softwareSystem "Справочник ограничений" "Визовые правила, MCT по парам терминалов, багажные нормы тарифов." "External"
        paymentGateway = softwareSystem "Платёжный шлюз" "Авторизация доплаты разницы тарифа и проведение возврата." "External"
        deliveryChannels = softwareSystem "Провайдеры каналов доставки" "Push, SMS, электронная почта, мессенджер. Возвращают статус доставки." "External"
        groundSuppliers = softwareSystem "Поставщики наземных услуг" "Отели, трансферы, активности. Принимают отмену и перенос брони." "External"
        monitoring = softwareSystem "Мониторинг и алерты" "Дашборды сценария и интеграций, приём алертов о расхождении удержания ПДн." "External"

        irops = softwareSystem "TravelTech IROPS" "Отслеживает статусы рейсов, детектирует сбой, подбирает альтернативы с учётом багажа, виз и таймзон, доводит решение и обновляет план поездки." {

            web = container "C-WEB. Клиентское приложение" "План поездки, карточка сбоя, выбор альтернативы, предпочтения по каналам, авто-политика. Раздел консоли оператора — очередь эскалаций и ручной разбор." "React, TypeScript" "UI"
            api = container "C-API. API-шлюз" "Аутентификация, авторизация в паре «человек и поездка», идемпотентность мутаций, версионирование внешнего контракта. Наружу отдаёт ссылку и маску вместо паспортных данных." "Kotlin, REST, WebSocket" "Edge"

            ingest = container "C-INGEST. Адаптер источников статусов" "Приём из трёх типов источников, нормализация в единую модель статуса сегмента, проставление event_at, ingest_at, источника и ранга достоверности." "Kotlin, webhook, poll, IMAP" "Service"
            detect = container "C-DETECT. Сервис детекции" "Дедупликация, разрешение противоречий по рангу и event_at, порог свежести, текущее состояние сегмента, детекция типов сбоя и misconnect. Единственный писатель схемы status." "Kotlin, Kafka Streams" "Service"

            orch = container "C-ORCH. Оркестратор сбоев" "Состояние процесса, жизненный цикл сбоя, ack-окно, авто-политика, эскалация, основание решения. Единственный писатель схемы disruption. В таблицы плана поездки не пишет." "Camunda 8 (Zeebe), BPMN, DMN" "Core" {
                inbox = component "C-ORCH-INBOX. Приёмник событий" "Подписка на входящие события, таблица обработанных событий, корреляция по booking_id и disruption_id." "Kotlin, Kafka consumer"
                engine = component "C-ORCH-ENGINE. Движок процессов" "Исполнение BPMN P-01…P-03, таймеры ack-окна и напоминания, ожидание сообщений, вызов таблиц решений." "Zeebe"
                impact = component "C-ORCH-IMPACT. Оценщик влияния" "P-01.T1: затронутые элементы плана и участники поимённо, класс влияния. Читает план через C-PLAN, своих таблиц маршрута не имеет." "Kotlin, job worker"
                decision = component "C-ORCH-DECISION. Менеджер решения" "Ack-окно и лестница таймеров, проверка мандата организатора, авто-политика, сборка пакета эскалации, поведение при ответе после закрытия окна." "Kotlin, job worker, DMN"
                state = component "C-ORCH-STATE. Состояние сбоя и outbox" "Жизненный цикл сбоя, решение и его основание, связь повторного сбоя с исходным. Пишет схему disruption и публикует исходящие события транзакционным outbox." "Kotlin, JPA, outbox relay"
            }

            alternatives = container "C-ALT. Сервис подбора альтернатив" "P-02: опрос провайдеров, окно сбора, проверки MCT, виз, багажа и таймзон, разница тарифа и признак вынужденности, ранжирование. Единственный писатель схемы alternative." "Kotlin, job worker, DMN" "Service"
            rebooking = container "C-REBOOK. Сервис перебронирования" "P-03: холд места, авторизация доплаты, выпуск по PNR с ключом операции, отмена старого билета, возврат, компенсации саги." "Kotlin, job worker" "Service"

            planning = container "C-PLAN. Сервис плана поездки" "Поездка, участие и роли, мандаты, бронирования, сегменты, версии плана, пересчёт временной шкалы. Единственный писатель схемы trip." "Kotlin, REST, outbox" "Core"
            notify = container "C-NOTIFY. Сервис уведомлений" "Лестница каналов, приём статусов доставки, одно активное уведомление на сбой, локальное время в тексте. Единственный писатель схемы notification." "Kotlin, адаптеры каналов" "Service"

            pii = container "C-PII. Сервис контура ПДн" "Единственная точка чтения и записи паспортных данных, выдача ссылки и маски, журнал доступа, выдача оператору доступа по обоснованию на срок." "Kotlin, выделенный сетевой сегмент" "PII"
            retention = container "C-RETENT. Планировщик удержания ПДн" "P-04: расчёт и перенос срока удержания, физическое удаление, отчёт об удалении, ежесуточная сверка и алерт о расхождении. Права — только удаление и подсчёт." "Kotlin, планировщик, job worker" "PII"

            bus = container "C-BUS. Шина событий" "12 каналов каталога, ключи партиционирования, доставка не менее одного раза, retention сырых статусов." "Apache Kafka" "Infrastructure"
            db = container "C-DB. Основное хранилище" "Схемы status, disruption, alternative, trip, notification. У каждой схемы ровно один сервис-писатель." "PostgreSQL" "Database"
            vault = container "C-VAULT. Хранилище контура ПДн" "Отдельный инстанс, отдельный ключ шифрования с ротацией, физическое удаление, неизменяемый журнал доступа." "PostgreSQL" "Database"

            # Люди и вход
            traveller -> web "Смотрит план, отвечает на уведомление, выбирает альтернативу"
            operator -> web "Разбирает очередь эскалаций"
            web -> api "Запросы интерфейса" "HTTPS, REST и WebSocket"
            api -> planning "Читает поездку, план и состав участников" "REST"
            api -> notify "Задаёт предпочтения по каналам" "REST"
            api -> pii "Ссылка и маска паспортных данных, запрос доступа по обоснованию" "REST"
            api -> bus "Публикует decision.submitted.v1"

            # Приём и детекция
            statusAggregator -> ingest "Статусы по подписке на бронирования" "Webhook и опрос"
            carrierGds -> ingest "Push об изменении и служебные рассылки" "Webhook, IMAP"
            ingest -> bus "Публикует flight.status.received.v1, ключ flight_key"
            bus -> detect "Доставляет flight.status.received.v1"
            detect -> db "Пишет статусы сегментов добавлением записей" "JDBC"
            detect -> planning "Читает бронирования и сегменты, затронутые рейсом" "REST"
            detect -> constraintsRef "MCT для детекции misconnect" "REST"
            detect -> bus "Публикует disruption.detected.v1, ключ booking_id"

            # Оркестрация
            bus -> orch "Доставляет disruption.detected.v1, decision.submitted.v1, notification.delivery.reported.v1"
            orch -> db "Пишет состояние сбоя, решение и его основание" "JDBC"
            orch -> planning "Читает план поездки и участников для оценки влияния" "REST"
            orch -> alternatives "Подбор альтернатив, P-02" "gRPC, job worker"
            orch -> rebooking "Перебронирование, P-03" "gRPC, job worker"
            orch -> bus "Публикует disruption.notified.v1, decision.requested.v1, decision.reminded.v1, disruption.resolved.v1"

            # Подбор
            alternatives -> bookingProvider "Запрос альтернативных рейсов" "REST"
            alternatives -> constraintsRef "MCT, транзитные визы, багажные нормы" "REST"
            alternatives -> groundSuppliers "Доступность переноса трансферов и активностей" "REST"
            alternatives -> planning "Читает план для оценки каскада" "REST"
            alternatives -> db "Пишет варианты и результат каждой проверки" "JDBC"

            # Перебронирование
            rebooking -> bookingProvider "Холд места, выпуск по PNR, отмена старого билета" "REST"
            rebooking -> paymentGateway "Авторизация доплаты и возврат разницы тарифа" "REST"
            rebooking -> groundSuppliers "Перенос и восстановление наземных броней" "REST"
            rebooking -> pii "Минимальный набор полей документа для выпуска перевозки" "REST, mTLS"
            rebooking -> planning "Фиксирует новые сегменты и новую версию плана" "REST"

            # План и уведомления
            planning -> db "Пишет поездку, план и версии" "JDBC"
            planning -> bus "Публикует plan.updated.v1, trip.completed.v1"
            bus -> notify "Доставляет события уведомлений"
            notify -> deliveryChannels "Отправка по лестнице каналов" "REST"
            deliveryChannels -> notify "Статус доставки" "Webhook"
            notify -> db "Пишет уведомления и статусы доставки" "JDBC"
            notify -> bus "Публикует notification.delivery.reported.v1"

            # Контур ПДн
            pii -> vault "Чтение, запись, журнал доступа" "JDBC"
            bus -> retention "Доставляет trip.completed.v1"
            retention -> vault "Физическое удаление по сроку и подсчёт остатка" "JDBC"
            retention -> bus "Публикует pii.purge.mismatch.v1"
            bus -> monitoring "Алерт о расхождении удержания ПДн"

            # Компоненты оркестратора
            bus -> orch.inbox "Входящие события"
            orch.inbox -> orch.engine "Корреляция сообщения с экземпляром процесса"
            orch.engine -> orch.impact "P-01.T1"
            orch.engine -> orch.decision "P-01.T3, P-01.T4, граничные таймеры"
            orch.engine -> orch.state "Переходы жизненного цикла сбоя"
            orch.engine -> alternatives "Call activity P-02"
            orch.engine -> rebooking "Call activity P-03"
            orch.impact -> planning "Читает план поездки"
            orch.impact -> orch.state "Класс влияния и перечень затронутых элементов"
            orch.decision -> orch.state "Решение и его основание"
            orch.state -> db "Схема disruption"
            orch.state -> bus "Исходящие события из outbox"
        }

        # Отношения уровня C1
        traveller -> irops "Узнаёт о сбое и выбирает альтернативу"
        operator -> irops "Разбирает эскалации"
        statusAggregator -> irops "Статусы рейсов по подписке"
        carrierGds -> irops "Push об изменении и служебные рассылки"
        irops -> bookingProvider "Поиск альтернатив, выпуск и отмена билетов"
        irops -> constraintsRef "MCT, визовые правила, багажные нормы"
        irops -> paymentGateway "Авторизация доплаты и возврат"
        irops -> deliveryChannels "Отправка уведомлений по лестнице каналов"
        irops -> groundSuppliers "Отмена и перенос наземных броней"
        irops -> monitoring "Метрики сценария и алерты"
    }

    views {
        systemContext irops "C1" "Системный контекст. Кто и какие внешние системы участвуют в сценарии сбоя." {
            include *
            exclude monitoring
            autolayout lr
        }

        container irops "C2-Flow" "Поток обработки сбоя. Контейнеры на пути события от источника статусов до уведомления." {
            include traveller irops.web irops.api irops.ingest irops.detect irops.bus irops.orch irops.alternatives irops.rebooking irops.planning irops.notify statusAggregator carrierGds bookingProvider constraintsRef paymentGateway groundSuppliers deliveryChannels
            autolayout tb
        }

        container irops "C2-Data" "Владение данными и контур паспортных данных. У каждой схемы ровно один писатель." {
            include irops.detect irops.orch irops.alternatives irops.planning irops.notify irops.rebooking irops.api irops.db irops.pii irops.retention irops.vault irops.bus
            autolayout tb
        }

        component irops.orch "C3" "Компоненты оркестратора сбоев. Остальные контейнеры не раскрываются." {
            include *
            autolayout tb
        }

        dynamic irops "D1" "Отмена рейса: от статуса провайдера до применённой альтернативы." {
            statusAggregator -> irops.ingest "Рейс отменён"
            irops.ingest -> irops.bus "flight.status.received.v1"
            irops.bus -> irops.detect "Дедупликация, ранг источника, решение по event_at"
            irops.detect -> irops.bus "disruption.detected.v1, ключ booking_id"
            irops.bus -> irops.orch "Старт экземпляра P-01"
            irops.orch -> irops.planning "План поездки и участники"
            irops.orch -> irops.alternatives "P-02: рейсы, MCT, визы, багаж"
            irops.orch -> irops.bus "decision.requested.v1"
            irops.bus -> irops.notify "Лестница каналов, ack-окно 20 минут"
            irops.notify -> deliveryChannels "Push первым каналом"
            traveller -> irops.web "Выбирает альтернативу"
            irops.web -> irops.api "Отправляет выбор"
            irops.api -> irops.bus "decision.submitted.v1"
            irops.bus -> irops.orch "Корреляция по disruption_id"
            irops.orch -> irops.rebooking "P-03: выпуск по PNR, отмена старого"
            irops.rebooking -> irops.planning "Новые сегменты, новая версия плана"
            irops.orch -> irops.bus "disruption.resolved.v1"
            autolayout lr
        }

        styles {
            element "Human" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Core" {
                background #1168bd
                color #ffffff
            }
            element "UI" {
                shape WebBrowser
                background #438dd5
                color #ffffff
            }
            element "Edge" {
                background #438dd5
                color #ffffff
            }
            element "PII" {
                background #438dd5
                color #ffffff
            }
            element "Infrastructure" {
                shape Pipe
                background #438dd5
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            relationship "Relationship" {
                routing Orthogonal
                thickness 2
                color #707070
            }
        }
    }
}
