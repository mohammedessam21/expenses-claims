import type { ClaimDetail } from '../api/types'
import { useI18n } from '../i18n/useI18n'
import { StatusBadge } from './StatusBadge'

export function ClaimSummary({ claim }: { claim: ClaimDetail }) {
  const { t, categoryName, formatSar } = useI18n()

  return (
    <section className="card">
      <div className="card-heading">
        <h1>{t('claim.title', { code: claim.reference_code })}</h1>
        <StatusBadge status={claim.status} />
      </div>
      <dl className="details">
        <dt>{t('claim.employee')}</dt>
        <dd>{claim.employee.name}</dd>
        <dt>{t('claim.category')}</dt>
        <dd>{categoryName(claim.category)}</dd>
        <dt>{t('claim.amount')}</dt>
        <dd>{formatSar(claim.amount_halalas)}</dd>
        <dt>{t('claim.limitAtSubmission')}</dt>
        <dd>{formatSar(claim.limit_halalas_at_submission)}</dd>
        <dt>{t('claim.date')}</dt>
        <dd>{claim.spent_on}</dd>
        <dt>{t('claim.reviewer')}</dt>
        <dd>{claim.reviewer?.name ?? t('claim.noReviewer')}</dd>
        <dt>{t('claim.description')}</dt>
        <dd className="preserve-lines">{claim.description}</dd>
      </dl>
    </section>
  )
}
