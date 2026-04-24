# Quality Checklist

Run through this list before telling the user a deck is ready.

## Content

- [ ] Every code block has a language tag (` ```ts `, ` ```bash `, etc. — never bare ` ``` `)
- [ ] No slide exceeds 6 bullets / 6 words per bullet (or speaker note explains why)
- [ ] Lists with 3+ items use `<v-clicks>` for progressive disclosure
- [ ] Section dividers (`layout: section`) break the deck into chapters
- [ ] Final slide uses `layout: end` with a clear takeaway or Q&A cue

## Frontmatter

- [ ] Headmatter has `title`, `author`, `theme`, `fonts`, `lang`
- [ ] Font `fallbacks: true` set if the venue may be offline
- [ ] `colorSchema` set deliberately (don't default to `auto` if venue lighting is known)

## Speaker notes

- [ ] Speaker notes exist for every content slide (HTML comment at slide end)
- [ ] Notes include any exact commands to type during live demos
- [ ] Fallback instructions for live-demo failures (see `09-live-demo-patterns.md`)

## Runtime

- [ ] `pnpm dev` runs without console errors
- [ ] If Monaco is used: `monaco: dev` or `monaco: true` in headmatter
- [ ] If PDF export is promised: `playwright-chromium` installed; `pnpm export` tested

## Accessibility and legibility

- [ ] Text contrast ≥ 4.5:1 on every slide (see `06-themes-styling.md` → Projector Legibility)
- [ ] Images have `alt` attributes (empty `alt=""` for decorative, descriptive for informational)
- [ ] Diagrams have a screen-reader text alternative (see `08-export-deploy.md` → Accessibility)
- [ ] No information communicated by color alone
