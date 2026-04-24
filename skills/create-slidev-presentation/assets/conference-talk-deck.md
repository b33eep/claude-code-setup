---
theme: seriph
title: Your Conference Talk Title
info: |
  A 30–45 minute conference session on [topic].
  [Venue] — [Date]
author: Speaker Name
keywords: [topic, tag]
colorSchema: auto
transition: slide-left
mdc: true
lineNumbers: false
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google
  weights: '400,500,600,700'
  fallbacks: true
lang: en
drawings:
  persist: false
---

# Your Conference Talk Title

A subtitle that makes the topic concrete

<div class="pt-8 opacity-70 text-sm">
  Speaker Name · Role · Venue · Date
</div>

<!--
Welcome. Pause. Let the audience settle.
Do not thank the organizers yet — that kills pacing. Save it for the end.
-->

---
layout: center
class: text-center
---

<div class="text-6xl font-bold tracking-tighter leading-none">
  The <span class="text-sky-400">one thing</span><br />
  I want you to remember
</div>

<!--
Open with your single takeaway. Everything else is in service of this.
If you only have 60 seconds, this is what you'd say.
-->

---

# Who am I

<div class="grid grid-cols-[1fr_2fr] gap-8 mt-8">
  <div>
    <img src="/headshot.jpg" class="rounded-xl w-full" />
  </div>
  <div class="flex flex-col justify-center">
    <div class="text-3xl font-semibold">Speaker Name</div>
    <div class="opacity-60 mt-2">Role at Company</div>
    <div class="mt-6 space-y-1">
      <div><carbon-logo-github /> github.com/user</div>
      <div><carbon-logo-x /> @handle</div>
      <div><carbon-email /> me@example.com</div>
    </div>
  </div>
</div>

<!--
Keep this to 30 seconds. They came for the content, not your CV.
-->

---
layout: section
---

# Part 1

The problem

---

# The problem

<v-clicks>

- Symptom one
- Symptom two
- Symptom three

</v-clicks>

<div v-click class="mt-12 text-xl opacity-80">
  Why does this keep happening?
</div>

<!--
Build tension before the reveal.
-->

---
layout: fact
---

# 73%

of teams report this problem at least once a quarter

<!--
Source: [cite it in notes, not on slide].
One big number is more memorable than a table.
-->

---
layout: section
---

# Part 2

A better approach

---

# Core idea

The pitch, in one sentence.

```ts
// A concrete example, always
const solution = applyBetterApproach(problem)
```

<v-click>

It works because of three properties:

</v-click>

<v-clicks>

- Property A
- Property B
- Property C

</v-clicks>

---

# Evolving the code

Walk through the transformation.

````md magic-move

```ts
// Naive: works but doesn't scale
function process(items) {
  const results = []
  for (const item of items) {
    results.push(heavyWork(item))
  }
  return results
}
```

```ts
// Better: parallelized
async function process(items: Item[]): Promise<Result[]> {
  return Promise.all(items.map(heavyWork))
}
```

```ts
// Best: batched with backpressure
async function process(items: Item[]): Promise<Result[]> {
  const batches = chunk(items, 10)
  const results: Result[] = []
  for (const batch of batches) {
    results.push(...await Promise.all(batch.map(heavyWork)))
  }
  return results
}
```

````

<!--
Magic-move morphs tokens between steps — audience sees what changes.
Pause between clicks. Let the transformation register.
-->

---
layout: section
---

# Part 3

Live demo

---
layout: center
class: text-center
---

<div class="text-8xl font-bold tracking-tighter opacity-20">
  DEMO
</div>

<div class="text-xl mt-8 opacity-60">
  Topic of the demo
</div>

<Link to="demo-fallback" class="mt-12 inline-block text-xs opacity-30 hover:opacity-60">
  (emergency fallback)
</Link>

<!--
Demo script:

1. Open terminal in ~/demo
2. [exact command 1]
3. [exact command 2]
4. Show output
5. Kill with Ctrl+C

If demo fails: click the fallback link.
-->

---
layout: section
---

# Part 4

What to take home

---

# The three things

<div class="grid grid-cols-3 gap-8 mt-12">
  <div v-click class="p-6 bg-sky-500/10 border-l-4 border-sky-500 rounded-r-lg">
    <div class="text-sm text-sky-400 uppercase tracking-wide font-semibold">One</div>
    <div class="text-xl font-semibold mt-2">First takeaway</div>
    <div class="text-sm opacity-70 mt-2">One-line explanation</div>
  </div>
  <div v-click class="p-6 bg-fuchsia-500/10 border-l-4 border-fuchsia-500 rounded-r-lg">
    <div class="text-sm text-fuchsia-400 uppercase tracking-wide font-semibold">Two</div>
    <div class="text-xl font-semibold mt-2">Second takeaway</div>
    <div class="text-sm opacity-70 mt-2">One-line explanation</div>
  </div>
  <div v-click class="p-6 bg-amber-500/10 border-l-4 border-amber-500 rounded-r-lg">
    <div class="text-sm text-amber-400 uppercase tracking-wide font-semibold">Three</div>
    <div class="text-xl font-semibold mt-2">Third takeaway</div>
    <div class="text-sm opacity-70 mt-2">One-line explanation</div>
  </div>
</div>

---

# Further reading

- [Paper / book title](https://example.com)
- [Blog post](https://example.com)
- [Related talk](https://example.com)
- [Source code](https://github.com/user/repo)

---
layout: center
class: text-center
---

# Questions?

<div class="mt-12 text-lg opacity-70">
  Slides: <span class="font-mono">github.com/user/talk-slug</span>
</div>

<div class="mt-2 text-lg opacity-70">
  Contact: <span class="font-mono">@handle</span>
</div>

<!--
Stand confidently. First question is always the slowest — wait it out.
If nobody asks: seed a question ("one thing I often get asked…").
-->

---
layout: end
class: text-center
---

# Thank you

---
hide: true
routeAlias: demo-fallback
---

# Demo — recorded version

<img src="/demo-recording.gif" class="h-[500px] mx-auto rounded-xl shadow-2xl" />

<div class="mt-4 text-sm opacity-60">
  Recorded the day before the talk. Same content as live.
</div>
