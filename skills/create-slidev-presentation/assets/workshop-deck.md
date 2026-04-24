---
theme: seriph
title: Workshop Title
info: |
  Hands-on workshop: [topic]. Duration: [N] hours.
author: Instructor Name
keywords: [workshop, hands-on]
colorSchema: dark
transition: slide-left
mdc: true
lineNumbers: true   # helpful when attendees type along
monaco: dev
fonts:
  sans: 'Geist'
  serif: 'Geist'
  mono: 'Geist Mono'
  provider: google
  weights: '400,500,600,700'
  fallbacks: true
lang: en
---

# Workshop Title

Hands-on: [concrete skill you'll leave with]

<div class="pt-8 opacity-70 text-sm">
  Instructor · Duration: N hours · Date
</div>

---

# Before we start

Make sure you have:

<v-clicks>

- [Tool A] installed — check: `tool-a --version`
- [Tool B] installed — check: `tool-b --version`
- A text editor (VS Code, Vim, whatever)
- ~30 minutes of time for the first exercise

</v-clicks>

<div v-click class="mt-12 p-4 border-l-4 border-amber-500 bg-amber-500/10 rounded-r-lg">
  Raise your hand now if anything is missing. We'll help before we start.
</div>

---

# Structure

<div class="grid grid-cols-2 gap-6 mt-8 text-sm">
  <div class="p-4 bg-neutral-800 rounded-lg">
    <div class="text-sky-400 font-semibold">Block 1</div>
    <div class="opacity-80 mt-1">Intro + first hands-on</div>
  </div>
  <div class="p-4 bg-neutral-800 rounded-lg">
    <div class="text-sky-400 font-semibold">Block 2</div>
    <div class="opacity-80 mt-1">Concept deep-dive</div>
  </div>
  <div class="p-4 bg-neutral-800 rounded-lg">
    <div class="text-sky-400 font-semibold">Block 3</div>
    <div class="opacity-80 mt-1">Main exercise</div>
  </div>
  <div class="p-4 bg-neutral-800 rounded-lg">
    <div class="text-sky-400 font-semibold">Block 4</div>
    <div class="opacity-80 mt-1">Wrap-up + bonus</div>
  </div>
</div>

---
layout: section
---

# Block 1

Getting oriented

---

# Concept

Brief explanation of the first concept.

```ts {monaco-run}
// Try editing the string — output updates live
const greeting = 'Hello, workshop!'
console.log(greeting)
```

<!--
Give them 2 minutes to poke at this.
Then: any questions?
-->

---
layout: two-cols
---

# Step by step

Commands we'll run:

```bash
# 1. Create a new project
mkdir my-project && cd my-project

# 2. Initialize
tool-a init

# 3. First build
tool-a build
```

::right::

# What you should see

```
✓ Project initialized
✓ 3 files created
  - config.yml
  - main.ts
  - README.md

Built in 1.2s
```

<!--
Left side = what they type. Right side = expected output.
This is the core workshop pattern.
-->

---
layout: statement
class: bg-amber-500 text-neutral-950
---

<carbon-laptop class="text-8xl mx-auto mb-8" />

# Exercise 1

## 15 minutes

Create your project and make the first build pass.

<div class="mt-8 text-sm opacity-80">
  Stuck? Ask a neighbor or raise your hand.
</div>

<!--
Set timer 15:00.
Walk around. Help. Do not solve for them.
-->

---

# Checkpoint

Everyone should have:

<v-clicks>

- A running project directory
- A successful first build
- The output matching what was shown

</v-clicks>

<div v-click class="mt-12 p-4 border-l-4 border-emerald-500 bg-emerald-500/10 rounded-r-lg">
  All green? Great. If not, grab me before the next exercise.
</div>

---
layout: section
---

# Block 2

Going deeper

---

# The mechanism

How it actually works.

````md magic-move

```ts
// Simplified view
function doThing(input: Input): Output {
  return magic(input)
}
```

```ts
// One level deeper
function doThing(input: Input): Output {
  const step1 = parse(input)
  const step2 = transform(step1)
  return serialize(step2)
}
```

```ts
// What really happens
function doThing(input: Input): Output {
  const parsed = parse(input)
  const validated = validate(parsed)
  const transformed = transform(validated)
  const verified = verify(transformed)
  return serialize(verified)
}
```

````

<!--
Magic-move makes the "peeling back the abstraction" feel natural.
Pause on each step. Ask what they think happens next.
-->

---

# Try it yourself

```ts {monaco-run}
// Modify this function to handle negative numbers
function sqrt(n: number): number {
  // TODO: handle n < 0
  return Math.sqrt(n)
}

console.log(sqrt(16))
console.log(sqrt(-4))
```

<div v-click class="mt-4 text-sm opacity-70">
  Hint: what should happen for a negative input?
</div>

---
layout: statement
class: bg-amber-500 text-neutral-950
---

<carbon-laptop class="text-8xl mx-auto mb-8" />

# Exercise 2

## 30 minutes

Extend your project with [concrete feature].

See `exercises/02-feature/README.md` for the full brief.

---
layout: section
---

# Block 3

The main exercise

---
layout: center
class: text-center
---

<carbon-trophy class="text-8xl mx-auto mb-4 text-amber-400" />

# Main Exercise

## 45 minutes

Build [substantial thing] from scratch.

Reference: `exercises/03-main/README.md`

<!--
This is the workshop's centerpiece.
Walk around. Don't solve. Unblock.
-->

---
layout: section
---

# Block 4

Wrap-up

---

# What you built

<v-clicks>

- A working [thing]
- Understanding of [concept]
- A pattern you can apply at work on Monday

</v-clicks>

---

# Going further

Resources for after the workshop:

- [Official docs](https://example.com/docs)
- [Related course / tutorial](https://example.com)
- [Community / chat](https://example.com)
- Workshop repo: `github.com/instructor/workshop-slug`

---
layout: center
class: text-center
---

# Feedback

If this was useful — or if it wasn't — please tell me:

<div class="mt-8 font-mono text-lg">
  feedback-form.example.com
</div>

<div class="mt-4 text-sm opacity-60">
  Takes 2 minutes. Helps the next cohort.
</div>

---
layout: end
class: text-center
---

# Thank you

Find me afterward for questions or to show what you built.
