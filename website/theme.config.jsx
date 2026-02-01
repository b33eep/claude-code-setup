export default {
  logo: <strong>Claude Code Setup</strong>,
  project: {
    link: 'https://github.com/b33eep/claude-code-setup'
  },
  docsRepositoryBase: 'https://github.com/b33eep/claude-code-setup/tree/main/website',
  darkMode: false,
  nextThemes: {
    defaultTheme: 'dark',
    forcedTheme: 'dark'
  },
  footer: {
    text: 'MIT License - Claude Code Setup'
  },
  head: (
    <>
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <meta name="description" content="Claude Code Setup - Persistent memory for Claude Code via Markdown files" />
    </>
  ),
  useNextSeoProps() {
    return {
      titleTemplate: '%s - Claude Code Setup'
    }
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true
  },
  toc: {
    backToTop: true
  },
  feedback: {
    content: null
  },
  editLink: {
    component: null
  },
  navigation: {
    prev: true,
    next: true
  }
}
