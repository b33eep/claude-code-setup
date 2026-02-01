# Record 024: Documentation Site

**Status:** In Progress
**Priority:** High
**Date:** 2026-01-31

## Problem

Die aktuelle Dokumentation besteht aus:
- README.md (461 Zeilen, alles in einer Datei)
- 24 Records (verstreut in docs/records/)
- Command-Specs (in commands/)
- Skill-Specs (in skills/)

**Probleme:**
1. **Discoverability:** GitHub README ist limitiert, keine Suche, keine Navigation
2. **Onboarding:** Kein "Zero to working" Tutorial, alles auf einmal
3. **SEO:** Keine separate Domain, schlechte Auffindbarkeit
4. **Struktur:** Keine klare Trennung zwischen Guide, Reference, Architecture

## Solution

Dokumentations-Website mit Nextra (Next.js-basiert) im Monorepo-Ansatz.

### Entscheidungen

| Aspekt | Entscheidung | Begründung |
|--------|--------------|------------|
| Framework | Nextra | Modern, Next.js-basiert, OpenClaw-Style |
| Struktur | Monorepo (`/website`) | Code + Docs synchron, ein PR für beides |
| Hosting | GitHub Pages | Kostenlos, GitHub Actions Deployment |

### Alternativen betrachtet

| Option | Pro | Contra | Entscheidung |
|--------|-----|--------|--------------|
| Separates Repo | Cleaner Trennung | Sync-Overhead, zwei PRs | Rejected |
| MkDocs | Einfacher, Python | Weniger modern, kein React | Rejected |
| Docusaurus | Bekannt, React | Schwerer als Nextra | Rejected |
| VitePress | Leicht, Vue | Kein React-Ecosystem | Rejected |

## Implementation

### Struktur

```
website/
├── package.json
├── next.config.mjs
├── app/layout.jsx
├── content/
│   ├── index.mdx
│   ├── getting-started/
│   ├── concepts/
│   ├── commands/
│   ├── guides/
│   ├── reference/
│   ├── architecture/
│   └── development/
└── public/
```

### Content-Mapping

| Bereich | Quelle | Aufwand |
|---------|--------|---------|
| Getting Started | README.md (aufteilen) | Hoch |
| Concepts | README.md (aufteilen) | Mittel |
| Commands | commands/*.md (1:1) | Niedrig |
| Architecture | docs/records/*.md (1:1) | Niedrig |
| Development | CONTRIBUTING.md, SECURITY.md | Niedrig |
| Guides | NEU (Tutorials) | Hoch |
| Reference | Skills, MCP (zusammenfassen) | Mittel |

### Deployment

GitHub Actions Workflow:
- Trigger: Push to main (website/** changed)
- Build: Next.js Static Export
- Deploy: GitHub Pages

## Trade-offs

| Pro | Contra |
|-----|--------|
| Bessere UX, Navigation, Suche | Mehr Wartungsaufwand |
| SEO, Discoverability | Build-Prozess für Docs |
| Tutorials möglich | Initiale Migration |
| Professioneller Eindruck | Node.js Dependencies |

## References

- [Nextra Docs](https://nextra.site/docs)
- [OpenClaw Docs](https://docs.openclaw.ai) (Inspiration)
- [Record 000](000-core-workflow.md) - Core Workflow
