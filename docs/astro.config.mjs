import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// @astrojs/sitemap v3.7.3 crashes on Astro 4.x when `base` is set because it
// references `_routes` populated by `astro:routes:resolved`, a hook that only
// exists in Astro 5+.  Registering a no-op integration with the same name
// prevents Starlight from injecting the broken version automatically.
const noopSitemap = { name: '@astrojs/sitemap', hooks: {} };

const SITE_BASE = '/docker-templates';

// Astro's `base` option only prefixes assets/routes it generates itself — it
// never rewrites literal hrefs written in Markdown/MDX content. Starlight's
// own sidebar/TOC/pagination links are correctly base-prefixed through its
// internal pathWithBase() helper, but hand-authored links in page content
// (e.g. `[Prerequisites](/prerequisites/)`) are not, and 404 once deployed
// under a subpath. This mirrors pathWithBase() for content-authored links.
function remarkBasePrefixInternalLinks() {
  return (tree) => {
    const visit = (node) => {
      if (node.type === 'link' && typeof node.url === 'string') {
        const isRootRelative = node.url.startsWith('/') && !node.url.startsWith('//');
        const alreadyPrefixed =
          node.url === SITE_BASE || node.url.startsWith(SITE_BASE + '/');
        if (isRootRelative && !alreadyPrefixed) {
          node.url = SITE_BASE + node.url;
        }
      }
      if (Array.isArray(node.children)) {
        node.children.forEach(visit);
      }
    };
    visit(tree);
  };
}

export default defineConfig({
  site: 'https://gmbalaa14.github.io',
  base: SITE_BASE,
  markdown: {
    remarkPlugins: [remarkBasePrefixInternalLinks],
  },
  integrations: [
    noopSitemap,
    starlight({
      title: 'Docker Templates',
      description: 'Curated Docker Compose templates for self-hosted services',
      social: {
        github: 'https://github.com/gmbalaa14/docker-templates',
      },
      components: {
        Footer: './src/components/Footer.astro',
      },
      sidebar: [
        {
          label: 'Getting Started',
          items: [
            { label: 'Introduction', link: '/' },
            { label: 'When to Use', link: '/when-to-use/' },
            { label: 'Prerequisites', link: '/prerequisites/' },
          ],
        },
        {
          label: 'Architecture & Design',
          items: [
            { label: 'Architecture', link: '/architecture/' },
            { label: 'Networking Deep Dive', link: '/networking/' },
          ],
        },
        {
          label: 'Operations',
          items: [
            { label: 'Security Hardening', link: '/security/' },
            { label: 'Upgrade Guide', link: '/upgrade-guide/' },
            { label: 'Environment Variables', link: '/env-reference/' },
            { label: 'Multi-Template Combinations', link: '/combinations/' },
          ],
        },
        {
          label: 'Support',
          items: [
            { label: 'Troubleshooting', link: '/troubleshooting/' },
            { label: 'Glossary', link: '/glossary/' },
          ],
        },
        {
          label: 'Templates',
          items: [
            { label: 'Datalust Seq', link: '/templates/datalust-seq/' },
            { label: 'Headroom', link: '/templates/headroom/' },
            { label: 'Homarr', link: '/templates/homarr/' },
            { label: 'Jenkins', link: '/templates/jenkins/' },
            { label: 'Nginx Proxy Manager', link: '/templates/nginx-proxy-manager/' },
            { label: 'Portainer', link: '/templates/portainer/' },
            { label: 'SonarQube', link: '/templates/sonarqube/' },
            {
              label: 'Kafka',
              items: [
                { label: 'Overview', link: '/templates/kafka/' },
                { label: 'Kafka UI', link: '/templates/kafka/kafka-ui/' },
                { label: 'Cluster with Auth', link: '/templates/kafka/cluster-with-auth/' },
                { label: 'Cluster without Auth', link: '/templates/kafka/cluster-without-auth/' },
              ],
            },
          ],
        },
      ],
    }),
  ],
});
