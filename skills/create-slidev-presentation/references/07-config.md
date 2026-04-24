# Configuration Reference

## Minimal Project Scaffold (manual)

If `pnpm create slidev` isn't available or the user wants a precise setup, do this manually:

```bash
mkdir my-deck && cd my-deck
pnpm init
pnpm add -D @slidev/cli @slidev/theme-seriph playwright-chromium
```

Create `package.json`:

```json
{
  "name": "my-deck",
  "type": "module",
  "scripts": {
    "build": "slidev build",
    "dev": "slidev --open",
    "export": "slidev export"
  },
  "dependencies": {
    "@slidev/cli": "^52.0.0",
    "@slidev/theme-seriph": "latest",
    "playwright-chromium": "latest"
  }
}
```

Create `slides.md` (see `assets/starter-deck.md` for content).

Run `pnpm dev`.

## Project Structure

A complete Slidev project looks like this:

```
my-deck/
├── slides.md              # the deck
├── package.json
├── pages/                 # optional: split long decks into chapters
│   ├── intro.md
│   └── demo.md
├── components/            # optional: Vue components used in slides
│   └── MyWidget.vue
├── layouts/               # optional: custom layouts
│   └── dual-pane.vue
├── public/                # static assets (images, fonts)
│   └── cover.jpg
├── snippets/              # code snippets imported via <<< @/...
│   └── demo.ts
├── styles/                # global CSS / UnoCSS overrides
│   └── index.ts
└── netlify.toml           # if deploying to Netlify
```

Only `slides.md` and `package.json` are required; everything else is optional and created on demand.

## Complete Headmatter Schema

Every option that can appear in the headmatter YAML block. Only `title` and `theme` are commonly set; the rest default sensibly.

```yaml
---
# === Identity ===
title: Presentation Title        # browser tab, PDF metadata
titleTemplate: '%s - Slidev'     # placeholder %s = title
info: |                          # markdown, shown in info panel
  Long description
  Multi-line supported
author: Speaker Name
keywords: [tag1, tag2]           # comma-separated in meta tag

# === Appearance ===
theme: seriph                    # built-in, npm package, or ./local-theme
colorSchema: auto                # auto | light | dark
background: https://cover.sli.dev/default.jpg  # default cover bg
class: text-center               # class for the first slide
aspectRatio: 16/9                # 16/9 (default), 4/3, 1/1, custom like 1.85
canvasWidth: 980                 # virtual width in px, content scales from this

# === Fonts ===
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google               # google | none
  weights: '400,500,600,700'
  italic: false
  fallbacks: true                # include system fallbacks
  local: 'Arial'                 # local-only font to try first

# === Locale ===
lang: en                         # applies <html lang="...">

# === Features ===
mdc: true                        # enable MDC attribute syntax
lineNumbers: false               # show line numbers in all code blocks
monaco: dev                      # dev | true | false
monacoTypesSource: local         # local | cdn | none
twoslash: true                   # pre-processed type info
download: true                   # show PDF download in SPA build
transition: slide-left           # default slide transition
record: dev                      # dev | true | false — enable camera recording
drawings:
  enabled: true                  # drawing tool available in presenter
  persist: false                 # save drawings to local storage
  presenterOnly: false           # hide drawings from audience
  syncAll: true                  # sync across all open tabs

# === Code highlighting ===
highlighter: shiki               # only supported highlighter in v52+
shiki:
  theme: 'vitesse-dark'          # single theme
  # OR themes:
  themes:
    light: 'vitesse-light'
    dark: 'vitesse-dark'
  langs: ['ts', 'go', 'py']      # pre-load languages

# === Diagrams ===
mermaid:
  theme: 'dark'

plantuml:
  server: 'https://www.plantuml.com/plantuml'

# === Export ===
exportFilename: my-talk          # filename without extension
export:
  format: pdf                    # pdf | png | md | pptx
  timeout: 30000                 # ms
  dark: false
  withClicks: false              # expand each click as its own page
  withHidden: false              # include slides marked hide: true
  executablePath: /usr/bin/chromium  # override Playwright browser

# === Presenter & nav ===
presenter: true                  # enable presenter mode
selectable: false                # allow text selection in main view
remoteAssets: true               # download remote assets to build

# === Build ===
hideInToc: false                 # default for TOC

# === Custom data ===
defaults:                        # default per-slide frontmatter
  layout: default
  transition: slide-left
---
```

## Per-Slide Frontmatter

Any field from headmatter can be overridden per slide, plus slide-only fields:

```yaml
---
# --- Per-slide-only ---
layout: two-cols                 # see 02-layouts.md
src: ./pages/chapter-2.md        # import external markdown as slides
hide: true                       # omit from deck
clicks: 10                       # total clicks this slide consumes
hideInToc: true                  # skip this slide in <Toc />
routeAlias: solutions            # name for <Link to="...">
preload: false                   # skip preloading (for heavy iframe slides)
zoom: 0.8                        # scale all content (0–∞)

# --- Overrides of headmatter ---
class: text-center text-white
background: /special-bg.jpg
transition: fade
clicks: 5

# --- Layout-specific options ---
# (for layout: image-left / image-right / image)
image: /screenshot.png
backgroundSize: contain          # cover | contain

# (for layout: iframe / iframe-left / iframe-right)
url: https://example.com
---
```

## `slidev.config.ts` — Advanced Configuration

For settings that can't live in YAML, create `slidev.config.ts` at the project root:

```ts
import { defineConfig } from '@slidev/types'

export default defineConfig({
  // Any headmatter field also works here
  title: 'My Deck',

  // Disable features for faster reload
  disabledFeatures: ['katex'],

  // Custom transformers
  shikiSetup: async (shiki) => {
    // configure Shiki, e.g. load custom themes
  },

  mermaidSetup: () => ({
    theme: 'dark',
  }),

  // Hook into Vite
  vite: {
    optimizeDeps: {
      include: ['my-heavy-dep'],
    },
  },
})
```

## `.gitignore`

```gitignore
node_modules
.slidev
.remote-assets
dist
*.log
```

## `.npmrc` (optional, recommended)

```ini
auto-install-peers=true
shamefully-hoist=true
```

Avoids occasional Slidev addon install issues with strict pnpm.

## Environment Setup

### Slidev requires:

- Node.js ≥ 20.12.0 (Node 24 recommended — `create-slidev`'s own `engines.node` pins this floor)
- A package manager: `pnpm` (recommended), `npm`, or `yarn`

### For PDF export:

- `playwright-chromium` as a dev dependency
- Approximately 200 MB disk for Playwright browsers

```bash
pnpm add -D playwright-chromium
pnpm exec playwright install chromium
```

### For Monaco with full type info:

- TypeScript ≥ 5.0 in `devDependencies`
- Project-local `tsconfig.json` (even a minimal one)

```bash
pnpm add -D typescript
```

Minimal `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true
  }
}
```

## Slide-Level Field Cheatsheet

| Field | Purpose | Example |
|---|---|---|
| `layout` | Which layout Vue component to use | `cover`, `two-cols`, `none` |
| `class` | Root class on the slide element | `text-center text-white` |
| `background` | Background image or gradient | `/hero.jpg`, `linear-gradient(...)` |
| `transition` | Transition into this slide | `fade`, `slide-up` |
| `clicks` | Force total click count | `10` |
| `clicksStart` | First click number (default 0) | `2` |
| `hide` | Skip the slide entirely | `true` |
| `hideInToc` | Skip in TOC component | `true` |
| `routeAlias` | Name for <Link to="..."> | `summary` |
| `preload` | Preload this slide on deck open | `false` |
| `src` | Import external md file | `./pages/intro.md` |
| `zoom` | Scale all content | `0.85` |
| `level` | Custom TOC nesting | `2` |
| `dragPos` | Enable draggable positions | `{ foo: [100, 200, 150] }` |

## Reusable Defaults

Define once in headmatter, apply to all slides:

```yaml
defaults:
  layout: default
  transition: slide-left
  class: px-8
```

Per-slide frontmatter still overrides these.
