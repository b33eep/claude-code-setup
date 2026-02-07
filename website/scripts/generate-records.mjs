import { readdirSync, readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const recordsDir = join(__dirname, '..', '..', 'docs', 'records')
const dataDir = join(__dirname, '..', 'data')
const outFile = join(dataDir, 'records.json')

mkdirSync(dataDir, { recursive: true })

const files = readdirSync(recordsDir)
  .filter(f => /^\d{3}-.+\.md$/.test(f))
  .sort()

const records = files.map(file => {
  const content = readFileSync(join(recordsDir, file), 'utf-8')
  const num = file.slice(0, 3)

  // Title from "# Record NNN: ..."
  const titleMatch = content.match(/^# Record \d+:\s*(.+)/m)
  const title = titleMatch ? titleMatch[1].trim() : file.replace(/^\d+-|\.md$/g, '')

  // Status: two formats
  // Newer: "## Status\n\nDone"
  // Older: "**Status:** Accepted"
  let status = 'Done'
  const blockMatch = content.match(/^## Status\s*\n+\s*(\S+)/m)
  const inlineMatch = content.match(/\*\*Status:\*\*\s*(\S+)/m)
  if (blockMatch) {
    status = blockMatch[1]
  } else if (inlineMatch) {
    status = inlineMatch[1]
  }

  // Normalize "Accepted" → "Done"
  if (status === 'Accepted') status = 'Done'

  return { num, title, status, file }
})

writeFileSync(outFile, JSON.stringify(records, null, 2) + '\n')
console.log(`Generated ${records.length} records → data/records.json`)
