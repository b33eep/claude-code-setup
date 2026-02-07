import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const skillsDir = join(__dirname, '..', '..', 'skills')
const pagesDir = join(__dirname, '..', 'pages', 'features', 'skills')
const dataDir = join(__dirname, '..', 'data')

mkdirSync(dataDir, { recursive: true })

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/)
  if (!match) return { meta: {}, body: content }

  const meta = {}
  for (const line of match[1].split('\n')) {
    const kv = line.match(/^(\w+):\s*(.+)$/)
    if (kv) {
      let value = kv[2].trim()
      if (value.startsWith('[') && value.endsWith(']')) {
        value = value.slice(1, -1).split(',').map(s => s.trim().replace(/^["']|["']$/g, ''))
      }
      meta[kv[1]] = value
    }
  }
  return { meta, body: match[2] }
}

// Escape <T>, <E> etc. outside fenced code blocks for MDX
function escapeMdxBody(md) {
  const lines = md.split('\n')
  let inCodeBlock = false
  return lines.map(line => {
    if (line.startsWith('```')) inCodeBlock = !inCodeBlock
    if (inCodeBlock) return line
    return line.replace(/`[^`]*`/g, m => m.replace(/</g, '\x00'))
      .replace(/<([A-Z][A-Za-z, ]*?)>/g, '&lt;$1&gt;')
      .replace(/\x00/g, '<')
  }).join('\n')
}

// Scan skill directory for extra files beyond SKILL.md
function scanExtras(skillDir) {
  const extras = []
  const ignore = new Set(['SKILL.md', '.DS_Store'])

  function scanDir(dir, prefix) {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (ignore.has(entry.name)) continue
      const rel = prefix ? `${prefix}/${entry.name}` : entry.name
      if (entry.isDirectory()) {
        extras.push({ path: rel + '/', type: 'dir' })
        // Don't recurse into large dirs — just note the top-level dir
      } else {
        extras.push({ path: rel, type: 'file' })
      }
    }
  }

  scanDir(skillDir, '')
  return extras
}

// Parse deps.json and return dependency names
function parseDeps(skillDir) {
  const depsFile = join(skillDir, 'deps.json')
  if (!existsSync(depsFile)) return []
  try {
    const data = JSON.parse(readFileSync(depsFile, 'utf-8'))
    return (data.dependencies || []).map(d => d.name)
  } catch { return [] }
}

// Known descriptions for conventional files/dirs
const extraDescriptions = {
  'deps.json': deps => `System dependencies (${deps.join(', ')})`,
  'assets/': () => 'Templates and reusable content',
  'references/': () => 'Reference documentation for Claude',
  'test-project/': () => 'Example project for testing',
}

const displayNames = {
  'standards-python': 'Python',
  'standards-typescript': 'TypeScript',
  'standards-javascript': 'JavaScript',
  'standards-shell': 'Shell/Bash',
  'standards-java': 'Java',
  'standards-kotlin': 'Kotlin',
  'standards-gradle': 'Gradle',
  'youtube-transcript': 'YouTube Transcript',
  'create-slidev-presentation': 'Slidev Presentations',
  'skill-creator': 'Skill Creator'
}

const dirs = readdirSync(skillsDir, { withFileTypes: true })
  .filter(d => d.isDirectory())
  .map(d => d.name)
  .sort()

const allSkills = []

for (const dir of dirs) {
  const skillFile = join(skillsDir, dir, 'SKILL.md')
  if (!existsSync(skillFile)) continue

  const content = readFileSync(skillFile, 'utf-8')
  const { meta, body } = parseFrontmatter(content)
  const extras = scanExtras(join(skillsDir, dir))
  const deps = parseDeps(join(skillsDir, dir))

  // Collapse files inside known dirs (show dir only, not individual files)
  const topLevel = []
  const seenDirs = new Set()
  for (const e of extras) {
    const topDir = e.path.split('/')[0]
    if (e.path.includes('/') && !seenDirs.has(topDir)) {
      seenDirs.add(topDir)
      topLevel.push({ path: topDir + '/', type: 'dir' })
    } else if (!e.path.includes('/')) {
      topLevel.push(e)
    }
  }

  // Build descriptions
  const extrasWithDesc = topLevel.map(e => {
    const descFn = extraDescriptions[e.path]
    const desc = descFn ? descFn(deps) : ''
    return { path: e.path, type: e.type, description: desc }
  })

  allSkills.push({
    name: meta.name || dir,
    description: meta.description || '',
    type: meta.type || 'context',
    applies_to: Array.isArray(meta.applies_to) ? meta.applies_to : [],
    file_extensions: Array.isArray(meta.file_extensions) ? meta.file_extensions : [],
    extras: extrasWithDesc,
    dir
  })

  // Only auto-generate pages for context skills
  if (meta.type !== 'context') continue

  const appliesTo = Array.isArray(meta.applies_to) ? meta.applies_to.join(', ') : ''

  const hasExtras = extrasWithDesc.length > 0
  const importLine = hasExtras ? `import { SkillExtras } from '../../../components/SkillExtras'\n` : ''
  const extrasTag = hasExtras ? `\n## Included Files\n\n<SkillExtras name="${meta.name || dir}" />\n` : ''

  const mdx = `{/* auto-generated from skills/${dir}/SKILL.md — do not edit */}
${importLine}
## Metadata

| Field | Value |
|-------|-------|
| Type | ${meta.type} |
| Applies to | ${appliesTo} |
${Array.isArray(meta.file_extensions) ? `| File extensions | ${meta.file_extensions.join(', ')} |\n` : ''}${extrasTag}
${escapeMdxBody(body).trim()}
`

  writeFileSync(join(pagesDir, `${dir}.mdx`), mdx)
}

// Write skills.json for overview page and components
writeFileSync(join(dataDir, 'skills.json'), JSON.stringify(allSkills, null, 2) + '\n')

// Generate _meta.js
const metaEntries = ["  index: 'Overview'"]
for (const skill of allSkills) {
  const label = displayNames[skill.dir] || skill.name
  metaEntries.push(`  '${skill.dir}': '${label}'`)
}
const metaContent = `// auto-generated — do not edit
export default {
${metaEntries.join(',\n')}
}
`
writeFileSync(join(pagesDir, '_meta.js'), metaContent)

const contextCount = allSkills.filter(s => s.type === 'context').length
console.log(`Generated ${contextCount} skill pages + _meta.js + data/skills.json (${allSkills.length} total)`)
