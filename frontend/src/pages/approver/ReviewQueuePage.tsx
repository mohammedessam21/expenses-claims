import { useCallback } from 'react'
import { useSearchParams } from 'react-router-dom'
import { fetchReviewClaims } from '../../api/requests'
import { CLAIM_STATUSES, type ClaimStatus } from '../../api/types'
import { ClaimsTable } from '../../components/ClaimsTable'
import { ErrorAlert } from '../../components/ErrorAlert'
import { useI18n } from '../../i18n/useI18n'
import { apiErrorMessage } from '../../lib/errors'
import { useApiData } from '../../lib/useApiData'

function parseStatus(value: string | null): ClaimStatus | '' {
  return CLAIM_STATUSES.find((status) => status === value) ?? ''
}

export function ReviewQueuePage() {
  const { t } = useI18n()
  const [searchParams, setSearchParams] = useSearchParams()
  const status = parseStatus(searchParams.get('status'))
  const load = useCallback(() => fetchReviewClaims(status), [status])
  const { data: claims, error, loading } = useApiData(load)

  function changeStatus(value: string) {
    setSearchParams(value ? { status: value } : {})
  }

  return (
    <section>
      <div className="page-heading">
        <h1>{t('review.title')}</h1>
        <label className="inline-field">
          <span>{t('review.filter')}</span>
          <select value={status} onChange={(event) => changeStatus(event.target.value)}>
            <option value="">{t('review.allStatuses')}</option>
            {CLAIM_STATUSES.map((value) => (
              <option key={value} value={value}>
                {t(`status.${value}`)}
              </option>
            ))}
          </select>
        </label>
      </div>
      <ErrorAlert message={error ? apiErrorMessage(error, t) : null} />
      {loading && <p className="muted">{t('common.loading')}</p>}
      {!loading && claims && claims.length === 0 && <p className="muted">{t('review.empty')}</p>}
      {!loading && claims && claims.length > 0 && (
        <ClaimsTable claims={claims} detailPath={(claim) => `/review/claims/${claim.id}`} showEmployee />
      )}
    </section>
  )
}
