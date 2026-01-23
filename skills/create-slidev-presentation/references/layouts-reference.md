# Slidev Layouts Reference

## All 17 Built-in Layouts

### 1. cover
Title/opening slides with optional background.
```yaml
---
layout: cover
background: /image.jpg
class: text-center
---
```

### 2. default
Standard content layout for most slides.
```yaml
---
layout: default
---
```

### 3. center
Content centered both vertically and horizontally.
```yaml
---
layout: center
---
```

### 4. section
Section divider between parts.
```yaml
---
layout: section
---
```

### 5. statement
Bold key message display.
```yaml
---
layout: statement
---
```

### 6. fact
Large statistics or metrics.
```yaml
---
layout: fact
---
```

### 7. quote
Quotations and testimonials.
```yaml
---
layout: quote
---
```

### 8. end
Closing/thank you slides.
```yaml
---
layout: end
---
```

### 9. two-cols
Side-by-side content with `::right::` slot.
```markdown
---
layout: two-cols
---

Left content

::right::

Right content
```

### 10. two-cols-header
Header spanning both columns.
```markdown
---
layout: two-cols-header
---

# Header

::left::

Left content

::right::

Right content
```

### 11. image-left
Image on left, content on right.
```yaml
---
layout: image-left
image: /image.jpg
---
```

### 12. image-right
Image on right, content on left.
```yaml
---
layout: image-right
image: /image.jpg
---
```

### 13. image
Full-screen background image.
```yaml
---
layout: image
image: /image.jpg
---
```

### 14. iframe
Embedded web page.
```yaml
---
layout: iframe
url: https://example.com
---
```

### 15. iframe-left
Web page on left, content on right.
```yaml
---
layout: iframe-left
url: https://example.com
---
```

### 16. iframe-right
Web page on right, content on left.
```yaml
---
layout: iframe-right
url: https://example.com
---
```

### 17. none
Blank canvas for custom designs.
```yaml
---
layout: none
---
```

## Layout Selection Guide

| Use Case | Recommended Layout |
|----------|-------------------|
| Opening slide | `cover` |
| New section | `section` |
| Regular content | `default` |
| Centered quote | `center` or `quote` |
| Comparison | `two-cols` |
| Code + explanation | `two-cols` or `image-right` |
| Key statistic | `fact` |
| Final slide | `end` |
