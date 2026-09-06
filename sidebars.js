/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: '01. Контекст',
      collapsed: false,
      items: [
        'context/problem',
        'context/scope',
        'context/actors',
        'context/glossary',
      ],
    },
    {
      type: 'category',
      label: '02. Требования',
      items: [
        'requirements/functional',
        'requirements/non-functional',
        'requirements/acceptance',
        'requirements/traceability',
      ],
    },
    {
      type: 'category',
      label: '03. Процессы',
      items: [
        'processes/overview',
        'processes/p01-disruption',
        'processes/p02-alternatives',
        'processes/p03-rebooking',
        'processes/p04-pii-purge',
        'processes/dmn',
      ],
    },
    {
      type: 'category',
      label: '04. Архитектура',
      items: [
        'architecture/c1-context',
        'architecture/c2-containers',
        'architecture/c3-orchestrator',
        'architecture/dynamic-irops',
        'architecture/resilience',
        'architecture/adr',
      ],
    },
    {
      type: 'category',
      label: '05. Данные',
      items: [
        'data/erd',
        'data/time-and-timezones',
        'data/pii-lifecycle',
      ],
    },
    {
      type: 'category',
      label: '06. API',
      items: [
        'api/events',
        'api/sync',
        {
          type: 'link',
          label: 'REST API (спецификация)',
          href: '/api/rest',
        },
        'api/async',
      ],
    },
    'risks',
  ],
};

export default sidebars;
