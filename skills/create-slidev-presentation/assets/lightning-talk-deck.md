---
theme: seriph
title: Lightning Talk Title
info: |
  A 5-minute lightning talk on [one idea].
author: Speaker Name
colorSchema: dark
transition: fade
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

# Lightning Talk Title

<div class="text-2xl opacity-60 mt-4">
  One punchy claim in one line.
</div>

<div class="pt-12 opacity-50 text-sm">
  Speaker · 5 minutes
</div>

<!--
Walk up. Smile. Don't introduce yourself — the MC just did.
Go straight to slide 2.
-->

---
layout: center
class: text-center
---

<div class="text-8xl font-bold tracking-tighter leading-none">
  <span class="opacity-40">The</span><br />
  <span class="text-sky-400">claim</span>
</div>

<!--
20 seconds on this slide. Let it sit.
-->

---

# Why you should care

<v-clicks>

- Point one
- Point two
- Point three

</v-clicks>

<!--
60 seconds. Keep moving.
-->

---

# The example

```ts
// One small, punchy example.
// Fit on the screen. No scrolling.
const result = demonstrateTheClaim(input)
```

<!--
90 seconds. Walk through the code briefly.
-->

---
layout: two-cols
---

# Without

```ts
// The old way — verbose
let x = []
for (let i = 0; i < arr.length; i++) {
  if (arr[i] > 0) x.push(arr[i] * 2)
}
```

::right::

# With

```ts
// The new way — obvious
const x = arr
  .filter(n => n > 0)
  .map(n => n * 2)
```

<!--
30 seconds. Let the contrast land.
-->

---
layout: fact
---

# 10×

less code. Same result.

<!--
If you have a number, show it.
Nothing cuts through fatigue like a big digit.
-->

---

# Try it

```ts {monaco-run}
// Change the array — see the result update.
const arr = [1, -2, 3, -4, 5]

const result = arr
  .filter(n => n > 0)
  .map(n => n * 2)

console.log(result)
```

<!--
30 seconds. Click once to run.
Don't explain — let them read.
-->

---
layout: center
class: text-center
---

# The takeaway

<div class="text-5xl font-bold tracking-tighter mt-8">
  <span class="text-sky-400">One sentence</span> they'll remember.
</div>

<!--
20 seconds.
-->

---
layout: end
class: text-center
---

# Thank you

<div class="mt-12 font-mono text-xl opacity-60">
  github.com/user/project
</div>

<!--
Total: ~5 minutes.
If you're under: great, audience loves getting time back.
If you're over: the MC will cut you off — finish the sentence fast.
-->
