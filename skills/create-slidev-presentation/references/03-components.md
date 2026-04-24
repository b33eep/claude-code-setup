# Components Reference

Slidev ships built-in Vue components usable directly as HTML tags in markdown. Themes and addons can add more. Custom components go in `components/` and are auto-imported.

## Click Animations

### `<v-clicks>` — Reveal children one click at a time

```markdown
<v-clicks>

- First point
- Second point
- Third point

</v-clicks>
```

Each direct child of `<v-clicks>` consumes one click. Blank lines above/below the tag are required for markdown list parsing to work.

### `<v-click>` — Reveal one element

```markdown
<v-click>

This paragraph appears on the first click.

</v-click>

<v-click>

This one on the second click.

</v-click>
```

### `v-click` directive — reveal without a wrapper tag

```markdown
<div v-click>Appears on click 1</div>
<div v-click="2">Appears on click 2</div>
<div v-click="[2, 4]">Visible from click 2 to click 4</div>
<div v-click.hide>Disappears on click 1</div>
<div v-click.hide="3">Disappears on click 3</div>
```

Form `v-click="[enter, leave]"` brackets the element to a click range.

### `<v-after>` — Appear one click after the previous

```markdown
<v-click>First</v-click>
<v-after>Right after</v-after>
```

Syntactic sugar for "the next click after whatever came before."

### `<v-mark>` — Highlight text as if with a marker

```markdown
The important <v-mark>word</v-mark> gets underlined on click.
```

Variants: `<v-mark type="underline">`, `type="box"`, `type="circle"`, `type="highlight"`, `type="strike-through"`. Color via `color="red"`.

## Motion Animations

### `v-motion` — Animate element entrance

```markdown
<div
  v-motion
  :initial="{ x: -80, opacity: 0 }"
  :enter="{ x: 0, opacity: 1 }"
>
  Slides in from left
</div>
```

Works with `:initial`, `:enter`, `:leave`, `:click-1`, `:click-2` (etc.) for per-click state.

```markdown
<div
  v-motion
  :initial="{ y: 0, scale: 1 }"
  :click-1="{ y: -20, scale: 1.2 }"
  :click-2="{ y: 0, scale: 1, rotate: 360 }"
>
  Click to bounce, click again to spin
</div>
```

## Navigation

### `<Link>` — Jump to another slide

```markdown
<Link to="42">Jump to slide 42</Link>
<Link to="deep-dive">Jump to aliased slide</Link>
<Link to="5" title="Deep dive section">Go deeper</Link>
```

Accepts numeric index or a `routeAlias` defined on a target slide.

### `<Toc>` — Auto-generated table of contents

```markdown
<Toc
  maxDepth="2"
  minDepth="1"
  columns="2"
  listClass="text-sm"
/>
```

Scans the deck for H1/H2 headings and produces clickable links. `columns` splits into multiple columns.

## Media

### `<Youtube>` — Embed YouTube video

```markdown
<Youtube id="dQw4w9WgXcQ" width="560" height="315" />
```

### `<Tweet>` — Embed X/Twitter post

```markdown
<Tweet id="1234567890" />
```

### `<SlidevVideo>` — Local video with control

```markdown
<SlidevVideo autoplay muted loop controls>
  <source src="/demo.mp4" type="video/mp4" />
</SlidevVideo>
```

## Icons

Slidev integrates [Iconify](https://icon-sets.iconify.design) — **200k+ icons** available as components. Syntax: `<collection-name>` → `<carbon-accessibility />`, `<mdi-heart />`, `<logos-typescript />`.

```markdown
<logos-typescript class="text-6xl" />
<mdi-heart class="text-red-500 text-4xl animate-pulse" />
<carbon-logo-github /> github.com/me/proj
```

Install icon collections on demand: `pnpm add -D @iconify-json/<collection>` (e.g. `@iconify-json/logos`, `@iconify-json/mdi`).

Popular collections for tech talks:
- `@iconify-json/logos` — language/tool logos (Go, Rust, TypeScript, Docker…)
- `@iconify-json/mdi` — Material Design Icons
- `@iconify-json/carbon` — IBM Carbon Design
- `@iconify-json/tabler` — Tabler Icons (clean line icons)
- `@iconify-json/simple-icons` — brand icons (GitHub, Slack, Discord…)

## Arrows and Annotations

### `<Arrow>` — Point at things

```markdown
<Arrow x1="100" y1="200" x2="300" y2="400" />
```

Coordinates in pixels from the slide's top-left. Tedious but precise. For many arrows, consider using Mermaid or an image with pre-drawn annotations.

## Embedded Rendering

### `<RenderWhen>` — Conditional rendering by context

```markdown
<RenderWhen context="presenter">

Only the speaker sees this.

</RenderWhen>
```

Contexts: `'main'` (audience view), `'presenter'` (presenter mode), `'overview'`, `'print'`, `'slide'`.

### `<Transform>` — Scale a block

```markdown
<Transform :scale="0.7">

Big content shrunk to fit

</Transform>
```

Useful when a code block is slightly too tall.

## Theme-Provided Components

Each theme can ship its own components. `theme-seriph` adds `<Cover>`, `<SpeakerCard>`. See the theme's README for specifics. Check available components:

```bash
ls node_modules/@slidev/theme-seriph/components
```

## Custom Components

Put any `.vue` file in `components/` at the project root. It auto-imports.

```vue
<!-- components/Callout.vue -->
<template>
  <div
    class="border-l-4 px-4 py-3 rounded-r-lg"
    :class="variantClasses[variant]"
  >
    <slot />
  </div>
</template>

<script setup lang="ts">
const { variant = 'info' } = defineProps<{ variant?: 'info' | 'warn' | 'danger' }>()

const variantClasses = {
  info: 'border-blue-400 bg-blue-400/10 text-blue-100',
  warn: 'border-amber-400 bg-amber-400/10 text-amber-100',
  danger: 'border-red-400 bg-red-400/10 text-red-100',
}
</script>
```

Use in any slide:

```markdown
<Callout variant="warn">

Don't run this in production.

</Callout>
```

## Component Composition Tips

- **Wrap with blank lines** when a component contains markdown; the parser needs them to switch between HTML and MD modes.
- **Props with expressions** use `:prop="..."` (Vue convention), string props use `prop="..."`.
- **Click-aware components** can read the current click count via `const { $clicks } = useContext()`.
