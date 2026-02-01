import nextra from 'nextra'

const withNextra = nextra({
  theme: 'nextra-theme-docs',
  themeConfig: './theme.config.jsx',
  defaultShowCopyCode: true
})

export default withNextra({
  output: 'export',
  images: {
    unoptimized: true
  },
  basePath: '/claude-code-setup'
})
