# Code Presentation

The feature that makes Slidev the right choice for tech talks. This reference covers everything from basic highlighting to live editors.

## Choosing the Right Tool

| You want to… | Use |
|---|---|
| Show static code with pretty colors | Plain fenced code block |
| Walk through code line by line on clicks | Line highlighting `{1\|3-5\|all}` |
| Show code evolving between versions | **Shiki Magic-Move** |
| Let the audience edit and run code live | Monaco editor |
| Show TypeScript types inline (hover/errors) | **TwoSlash** |
| Show two code variants side-by-side with tabs | Code Groups |
| Include code from an external file | `<<< @/path/to/file.ts` |
| Diff old vs. new | `diff` language + highlighting |

## Basic Code Blocks

Always specify the language:

````markdown
```ts
const greet = (name: string) => `Hello, ${name}`
console.log(greet('World'))
```
````

Slidev uses **Shiki** for highlighting. The color theme follows the deck's `colorSchema` (light/dark/auto).

### Force a specific Shiki theme

In the headmatter:

```yaml
---
theme: default
shiki:
  theme: 'vitesse-dark'
---
```

Or a light/dark pair:

```yaml
shiki:
  themes:
    light: 'vitesse-light'
    dark: 'vitesse-dark'
```

Popular themes: `vitesse-dark`, `vitesse-light`, `github-dark`, `github-light`, `one-dark-pro`, `nord`, `dracula`, `catppuccin-mocha`, `rose-pine`, `tokyo-night`, `solarized-dark`.

## Line Highlighting

Append `{...}` after the language on the fence line.

````markdown
```ts {1|3-5|all}
const user = 'Alice'

function greet(name: string) {
  return `Hi ${name}`
}
```
````

- `|` separates click steps
- `1` = single line
- `3-5` = range
- `all` = everything
- `*` = also everything (shorthand)
- `hide` = hide all (pair with a later `*` to reveal)
- `none` = unhighlight everything

### Additional options

````markdown
```ts {2-4|*}{at:2, lines:true, maxHeight:'200px'}
```
````

- `at:N` — start the sequence at click N (useful if other things on the slide claim earlier clicks)
- `lines:true` — line numbers for this block only
- `lines:false` — hide line numbers for this block only
- `maxHeight:'200px'` — cap height, scroll

## Shiki Magic-Move

**Use this when showing code evolve between versions.** It morphs identical tokens in place, making diffs obvious.

Wrap multiple code blocks in a `magic-move` fence:

````markdown
````md magic-move
```ts
function greet(name) {
  return 'Hello, ' + name
}
```

```ts
function greet(name: string): string {
  return `Hello, ${name}`
}
```

```ts
const greet = (name: string): string => `Hello, ${name}`
```
````
````

Each inner block is a **step**. Click advances to the next step. Tokens that exist in both steps animate to their new position; tokens that only exist in one fade in/out.

### Magic-Move with line highlighting

````markdown
````md magic-move {at:4, lines:true}
```js {*|1|2-5}
let count = 1
function add() {
  count++
}
```

```js {*}{lines:false}
let count = 1
const add = () => count += 1
```
````
````

The options after `magic-move` apply to the container (e.g. `at:4` delays start until click 4). Options inside each block apply only to that step.

### When to prefer Magic-Move over line highlighting

- Magic-Move: **the code structure changes** (refactoring, adding parameters, extracting functions)
- Line highlighting: **the code is static**, you're walking through it

## Monaco Editor

Make a code block editable and runnable in the browser:

````markdown
```ts {monaco-run}
function fib(n: number): number {
  return n < 2 ? n : fib(n - 1) + fib(n - 2)
}

console.log(fib(10))
```
````

Modes:
- `{monaco}` — editable, no run button (syntax only)
- `{monaco-run}` — editable + "Run" button, output shown below
- `{monaco-diff}` — diff view between two code blocks

### Enable Monaco globally

In the headmatter:

```yaml
monaco: dev   # Only in dev mode (default)
# monaco: true  # Also in build + export
# monaco: false # Disable entirely
```

### Monaco + types

When a `.ts` block uses imports, Monaco resolves types from the project's `node_modules`. To make types from your own code available, import them:

````markdown
```ts {monaco-run}
import type { User } from '@/types'

const u: User = { name: 'Alice', age: 30 }
```
````

### Monaco diff

Two code blocks in a `monaco-diff` fence:

````markdown
```ts {monaco-diff}
// Before
function add(a, b) {
  return a + b
}
~~~
// After
function add(a: number, b: number): number {
  return a + b
}
```
````

Separator `~~~` divides "before" and "after."

## TwoSlash

TwoSlash runs the TypeScript compiler at build time and inlines type information into the rendered code. Great for "here's what the types actually are" moments without needing Monaco.

### Setup

TwoSlash is **built into Slidev since v0.46**. No separate install needed. The project does need TypeScript available for type resolution:

```bash
pnpm add -D typescript
```

And a `tsconfig.json` at the project root (even a minimal one — see `references/07-config.md`).

Enable per block:

````markdown
```ts twoslash
const user = { name: 'Alice', age: 30 }
//    ^?
```
````

The `//    ^?` comment makes Slidev render the inferred type of `user` above the line.

### Showing errors

````markdown
```ts twoslash
// @errors: 2322
const x: number = 'not a number'
```
````

Errors render inline, red-underlined, with the TypeScript message on hover.

### Showing completions

````markdown
```ts twoslash
const arr = [1, 2, 3]
arr.fo
//   ^|
```
````

The `^|` comment renders the autocomplete popup.

### TwoSlash vs. Monaco

| | TwoSlash | Monaco |
|---|---|---|
| When computed | Build time | Runtime (in browser) |
| Interactive | No | Yes |
| PDF export | Renders correctly | Shows static state |
| File size | Small | Adds ~2MB to bundle |
| Use when… | Showing types in a static deck | Audience should edit/run |

**Prefer TwoSlash for PDF-exported decks.** Monaco won't work in the PDF.

## Code Groups

Multiple code variants with tabs:

````markdown
````md code-groups
```bash [pnpm]
pnpm add slidev
```

```bash [npm]
npm install slidev
```

```bash [yarn]
yarn add slidev
```
````
````

The `[label]` after the language becomes the tab title.

## Import External Code

Reference a file from your project:

````markdown
<<< @/snippets/demo.ts
````

With line highlighting:

````markdown
<<< @/snippets/demo.ts {2-4|all}
````

With language override and title:

````markdown
<<< @/snippets/demo.txt ts {2-4} {title: 'demo.ts'}
````

Why use this: keep the source in a real `.ts` file that compiles and is linted, then reference it from slides. No drift between "code in slide" and "code in repo."

## Diff Blocks

Git-style diffs have first-class highlighting:

````markdown
```diff
  function add(a, b) {
-   return a + b
+   return a + b + 1
  }
```
````

`+` lines render green, `-` lines red. Combine with `{}` click stepping to walk through diffs.

## Code Snippets in Speaker Notes

Notes can contain full code blocks:

```markdown
# Demo

```ts
// code
```

<!--
Speaker reminders — what to type during the live demo:

```bash
go run main.go
curl localhost:8080/health
```

If the demo breaks, pivot to the recording at slide 12.
-->
```

## Font for Code Blocks

The deck's `fonts.mono` applies to all code. Good choices for projector legibility:

```yaml
fonts:
  mono: 'Geist Mono'       # modern, 2024+
  # mono: 'JetBrains Mono'  # safe, widely available
  # mono: 'Fira Code'       # ligatures
  # mono: 'Monaspace Neon'  # GitHub's texture-healing (self-host needed)
  provider: google
```

See `06-themes-styling.md` for font-pair recommendations.

## Performance Tips

- **Monaco is heavy.** Only enable when the audience will interact; otherwise prefer line highlighting or TwoSlash.
- **Long code blocks scroll.** Use `{maxHeight:'400px'}` instead of shrinking the font.
- **Magic-Move with 10+ steps** slows animation. Split into two slides when the story gets long.
- **TwoSlash adds build time.** 20+ TwoSlash blocks noticeably slow `pnpm build`. Fine for dev.
