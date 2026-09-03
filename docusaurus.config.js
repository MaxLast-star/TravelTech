// @ts-check
import path from 'path';
import {fileURLToPath} from 'url';
import {themes as prismThemes} from 'prism-react-renderer';

const siteDir = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'TravelTech IROPS',
  tagline: 'Отслеживание сбоев рейсов и автоматическое перепланирование поездки',

  url: 'https://MaxLast-star.github.io',
  baseUrl: '/TravelTech/',
  organizationName: 'MaxLast-star',
  projectName: 'TravelTech',
  deploymentBranch: 'gh-pages',
  trailingSlash: false,

  onBrokenLinks: 'warn',

  i18n: {
    defaultLocale: 'ru',
    locales: ['ru'],
  },

  markdown: {
    mermaid: true,
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  themes: ['@docusaurus/theme-mermaid'],

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.js',
          routeBasePath: '/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      },
    ],
    [
      'redocusaurus',
      {
        specs: [
          {
            id: 'rest',
            spec: path.join(siteDir, 'static', 'api', 'openapi.yaml'),
            route: '/api/rest',
          },
        ],
        theme: {
          primaryColor: '#3b5bdb',
        },
      },
    ],
  ],

  themeConfig: {
    colorMode: {
      respectPrefersColorScheme: true,
    },
    mermaid: {
      theme: {light: 'neutral', dark: 'dark'},
    },
    navbar: {
      title: 'TravelTech IROPS',
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'docsSidebar',
          position: 'left',
          label: 'Документация',
        },
        {
          to: '/api/rest',
          label: 'REST API',
          position: 'left',
        },
        {
          href: 'https://github.com/MaxLast-star/TravelTech',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [],
      copyright: `Кейс «Альфред, друг Бэтмена» · ${new Date().getFullYear()}`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
    },
  },
};

export default config;
