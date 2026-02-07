import skills from '../data/skills.json'

export function SkillsOverview() {
  const context = skills.filter(s => s.type === 'context')
  const command = skills.filter(s => s.type === 'command')

  return (
    <>
      <h2>Coding Standards</h2>
      <p>Auto-load based on your project's tech stack:</p>
      <ul>
        {context.map(s => (
          <li key={s.dir}>
            <a href={`/claude-code-setup/features/skills/${s.dir}`}>{s.name}</a> — {(s.description.match(/^.+?\.(?:\s|$)/) || [s.description])[0].trim()}
          </li>
        ))}
      </ul>

      <h2>Tool Skills</h2>
      <p>Invoked manually or when relevant:</p>
      <ul>
        {command.map(s => (
          <li key={s.dir}>
            <a href={`/claude-code-setup/features/skills/${s.dir}`}>{s.name}</a> — {(s.description.match(/^.+?\.(?:\s|$)/) || [s.description])[0].trim()}
          </li>
        ))}
      </ul>
    </>
  )
}
