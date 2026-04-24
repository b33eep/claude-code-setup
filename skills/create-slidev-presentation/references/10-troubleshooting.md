# Troubleshooting

## Slides Don't Update

**Symptom:** Editing `slides.md`, dev server doesn't re-render.

**Fix:**

```bash
# Full cache clear
rm -rf .slidev node_modules/.vite
pnpm dev --force
```

If that fails, delete `node_modules` and reinstall.

## Layout Not Found

**Symptom:** `[vite] Internal server error: layout "foo" not found`.

**Causes + fixes:**

1. **Typo in layout name.** Case-sensitive.
2. **Theme doesn't include that layout.** Check `node_modules/<theme>/layouts/`.
3. **Custom layout not in `layouts/`.** File must be `layouts/foo.vue` at project root.
4. **Missing `<template>` block.** Your custom Vue file must have one.

## Code Block Not Highlighted

**Symptom:** Code renders as plain text.

**Causes + fixes:**

1. **No language specified.** Change ` ``` ` to ` ```ts `.
2. **Language not in Shiki.** Rare; check <https://shiki.style/languages>.
3. **Stale cache.** `pnpm dev --force`.

## Magic-Move Doesn't Animate

**Symptom:** Blocks render but don't morph between clicks.

**Causes + fixes:**

1. **Wrong fence count.** Must be **four** backticks, not three: ` ```` ` (look carefully).
2. **Missing `md` language.** Use ` ````md magic-move `.
3. **No separator between inner blocks.** Each inner ` ``` ` block must be separate.
4. **Single code block inside magic-move.** Needs at least two.

## Monaco Editor Blank

**Symptom:** Code block with `{monaco-run}` renders as empty box.

**Causes + fixes:**

1. **Monaco not enabled.** Add `monaco: dev` (or `true`) to headmatter.
2. **Build mode.** Monaco requires `monaco: true` (not `dev`) to work in `pnpm build`.
3. **JS error.** Open browser dev tools → Console. Usually a typo in the code block.
4. **Large code paste.** Monaco struggles with >200 lines. Trim the example.

## TwoSlash Errors

**Symptom:** TwoSlash block renders as plain code without type info.

**Causes + fixes:**

1. **TypeScript not installed.** TwoSlash (built-in since Slidev v0.46) needs TS to resolve types: `pnpm add -D typescript`.
2. **No `tsconfig.json`.** Create a minimal one at the project root (see `07-config.md`).
3. **Types from imported packages missing.** Install the package: `pnpm add -D @types/<pkg>`.

**Symptom:** TwoSlash types look wrong.

**Causes + fixes:**

1. **Strictness mismatch.** TwoSlash uses your `tsconfig.json`; if you want stricter errors, set `"strict": true`.
2. **Cached build.** `pnpm dev --force` to clear.

## PDF Export Fails

**Symptom:** `pnpm export` hangs, errors, or produces a blank PDF.

**Causes + fixes:**

1. **Playwright not installed.**
   ```bash
   pnpm add -D playwright-chromium
   pnpm exec playwright install chromium
   ```

2. **Timeout.** Complex slides take longer:
   ```bash
   pnpm export --timeout 120000
   ```

3. **Remote assets unreachable.** Set `remoteAssets: true` in headmatter to cache them during build, then export from the built version.

4. **Mermaid rendering timeout.** Bump `--timeout` or rewrite the diagram smaller.

5. **Monaco code blocks.** Expected — Monaco doesn't render in PDF. Use TwoSlash instead.

6. **Fonts not loading.** Either:
   - Add `local: 'Arial'` fallback in `fonts:`
   - Set `fallbacks: true`
   - Self-host fonts in `public/fonts/`

## Font Not Rendering

**Symptom:** Fonts fall back to browser defaults.

**Causes + fixes:**

1. **No internet during first build.** Google Fonts requires connectivity. Once cached, works offline.
2. **Font name typo.** Exact casing: `Geist`, not `geist` or `GEIST`.
3. **Weight not available.** If `weights: '400,700'` is set, `font-weight: 500` silently falls back. Add the weight.
4. **Self-hosted font not linked.** Check `styles/fonts.css` is imported in `styles/index.ts`.

## Icons Don't Appear

**Symptom:** `<mdi-heart />` renders as text or blank.

**Causes + fixes:**

1. **Icon collection not installed.**
   ```bash
   pnpm add -D @iconify-json/mdi
   ```
2. **Wrong collection prefix.** `carbon-*` for Carbon, `mdi-*` for Material, `logos-*` for brand logos, etc.
3. **Icon name typo.** Browse <https://icon-sets.iconify.design> for correct names.

## Mermaid Diagram Broken

**Symptom:** Diagram renders as text, or shows a Mermaid error.

**Causes + fixes:**

1. **Syntax error.** Paste your diagram into <https://mermaid.live> to validate.
2. **Wrong diagram type.** Check the first line (`graph`, `sequenceDiagram`, `classDiagram`, etc.).
3. **Version mismatch.** Slidev pins a Mermaid version; some advanced syntax may require a newer version than Slidev ships.
4. **Theme conflict.** Try `{theme: 'default'}` on the code fence.

## Presenter Mode Not Syncing

**Symptom:** Presenter view and main view are on different slides.

**Causes + fixes:**

1. **Both tabs must be on the same host.** `localhost:3030` and `127.0.0.1:3030` are different origins.
2. **Firewall blocks WebSockets.** Check browser console for connection errors.
3. **Multiple dev servers running.** Kill stale processes: `lsof -ti :3030 | xargs kill`.

## Deploy Fails on Vercel / Netlify

**Symptom:** Build succeeds locally, fails on CI.

**Causes + fixes:**

1. **Node version too old.** Set `NODE_VERSION=24` in env.
2. **Lockfile mismatch.** Use `pnpm install --frozen-lockfile` locally, commit the lockfile.
3. **Peer dependency warnings turned into errors.** Add `.npmrc`:
   ```ini
   auto-install-peers=true
   strict-peer-dependencies=false
   ```
4. **Playwright not needed at build time** (only for `export`). Move it to optional deps:
   ```json
   "optionalDependencies": {
     "playwright-chromium": "latest"
   }
   ```

## Browser Console Shows Vue Warnings

**Symptom:** `[Vue warn]: Failed to resolve component: MyComponent`.

**Causes + fixes:**

1. **Component not in `components/`.** Move it to the project root `components/` folder.
2. **Case mismatch.** Vue is case-sensitive for custom components in markdown. Use PascalCase in tags: `<MyComponent />`.
3. **File extension.** Must be `.vue`, not `.ts` or `.js`.

## Slidev Won't Start

**Symptom:** `pnpm dev` immediately exits or hangs.

**Causes + fixes:**

1. **Port 3030 in use.**
   ```bash
   pnpm dev --port 3040
   ```
2. **Node version too old.** Check `node -v`; upgrade to ≥20.
3. **Corrupted install.**
   ```bash
   rm -rf node_modules pnpm-lock.yaml
   pnpm install
   ```
4. **Theme not resolvable.** Check `theme:` in headmatter — typos silent-fail.

## PNG Export Produces Tiny Images

**Symptom:** Exported PNGs are low-resolution.

**Fix:** set `canvasWidth` higher in headmatter (default 980):

```yaml
canvasWidth: 1920
```

Rebuild, export.

## Overall Performance Degraded

**Symptom:** Slidev slow to reload, laggy during presentation.

**Causes + fixes:**

1. **Too many Monaco blocks.** Each is ~2 MB. Limit to ~3 per deck, prefer TwoSlash for static types.
2. **Too many remote images.** Set `remoteAssets: true` to cache locally.
3. **Very large images.** Compress to WebP, ~500 KB each.
4. **TwoSlash on every code block.** Only use on blocks that need type info.
5. **Headmatter misconfiguration.** Disable unused features:
   ```yaml
   disabledFeatures: [katex, mermaid]
   ```

## Getting Help

- Slidev GitHub issues: <https://github.com/slidevjs/slidev/issues>
- Slidev Discord: <https://chat.sli.dev>
- Documentation: <https://sli.dev>
