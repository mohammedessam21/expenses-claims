import { Link } from 'react-router-dom'
import type { Claim } from '../api/types'
import { useI18n } from '../i18n/useI18n'
import { StatusBadge } from './StatusBadge'

interface ClaimsTableProps {
  claims: Claim[]
  detailPath: (claim: Claim) => string
  showEmployee?: boolean
}

export function ClaimsTable({ claims, detailPath, showEmployee = false }: ClaimsTableProps) {
  const { t, categoryName, formatSar } = useI18n()

  return (
    <table className="table">
      <thead>
        <tr>
          <th>{t('table.reference')}</th>
          {showEmployee && <th>{t('table.employee')}</th>}
          <th>{t('table.category')}</th>
          <th className="numeric">{t('table.amount')}</th>
          <th>{t('table.status')}</th>
          <th>{t('table.date')}</th>
        </tr>
      </thead>
      <tbody>
        {claims.map((claim) => (
          <tr key={claim.id}>
            <td>
              <Link to={detailPath(claim)}>{claim.reference_code}</Link>
            </td>
            {showEmployee && <td>{claim.employee.name}</td>}
            <td>{categoryName(claim.category)}</td>
            <td className="numeric">{formatSar(claim.amount_halalas)}</td>
            <td>
              <StatusBadge status={claim.status} />
            </td>
            <td>{claim.spent_on}</td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
