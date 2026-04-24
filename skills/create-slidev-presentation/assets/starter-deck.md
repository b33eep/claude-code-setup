---
theme: seriph
title: Your Title Here
info: |
  One-line description. Appears in PDF metadata and the info panel.
author: Speaker Name
keywords: [tag1, tag2]
colorSchema: auto
transition: slide-left
mdc: true
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google
  weights: '400,500,600,700'
  fallbacks: true
lang: en
---

# Your Title Here

An optional subtitle

Speaker Name · Venue · Date

<!--
Speaker notes go here. Only visible in presenter mode.
-->

---
layout: center
class: text-center
---

# The Hook

One sentence that earns the audience's attention.

<!--
Start with a concrete pain point, surprising stat, or bold claim.
Do not read the slide aloud.
-->

---

# What we'll cover

<v-clicks>

- First main idea
- Second main idea
- Third main idea

</v-clicks>

<!--
Keep this brief. If possible, skip the agenda entirely.
-->

---
layout: section
---

# Part 1

Name of first section

---

# Main content slide

A short explanation here.

```ts
// Example code — always specify the language
function greet(name: string): string {
  return `Hello, ${name}`
}
```

<!--
Explain the code: what it does, why it matters.
-->

---
layout: two-cols
---

# Before

The old way.

```ts
// Imperative, verbose
let result = []
for (let i = 0; i < items.length; i++) {
  if (items[i].active) {
    result.push(items[i].name)
  }
}
```

::right::

# After

The new way.

```ts
// Declarative, concise
const result = items
  .filter(i => i.active)
  .map(i => i.name)
```

---

# Key takeaways

<v-clicks>

- Takeaway one
- Takeaway two
- Takeaway three

</v-clicks>

---
layout: end
class: text-center
---

# Thank You

Questions?

Find me: @handle · github.com/user
