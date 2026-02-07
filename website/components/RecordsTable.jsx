import records from '../data/records.json'

const BASE_URL = 'https://github.com/b33eep/claude-code-setup/blob/main/docs/records'

export function RecordsTable() {
  return (
    <table>
      <thead>
        <tr>
          <th>#</th>
          <th>Title</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>
        {records.map(r => (
          <tr key={r.num}>
            <td>{r.num}</td>
            <td><a href={`${BASE_URL}/${r.file}`}>{r.title}</a></td>
            <td>{r.status}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
