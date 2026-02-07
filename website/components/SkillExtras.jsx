import skills from '../data/skills.json'

export function SkillExtras({ name }) {
  const skill = skills.find(s => s.name === name)
  if (!skill || !skill.extras || skill.extras.length === 0) return null

  return (
    <table>
        <thead>
          <tr>
            <th>Path</th>
            <th>Description</th>
          </tr>
        </thead>
        <tbody>
          {skill.extras.map(e => (
            <tr key={e.path}>
              <td><code>{e.path}</code></td>
              <td>{e.description}</td>
            </tr>
          ))}
        </tbody>
    </table>
  )
}
