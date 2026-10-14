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

function parsePage(value: string | null): number {
  const page = Number(value)
  return Number.isInteger(page) && page > 0 ? page : 1
}

export function ReviewQueuePage() {
  const { t } = useI18n()
  const [searchParams, setSearchParams] = useSearchParams()
  const status = parseStatus(searchParams.get('status'))
  const page = parsePage(searchParams.get('page'))
  const load = useCallback(() => fetchReviewClaims(status, page), [status, page])
  const { data, error, loading } = useApiData(load)
  const claims = data?.claims
  const meta = data?.meta

  function changeStatus(value: string) {
    setSearchParams(value ? { status: value } : {})
  }

  function changePage(value: number) {
    setSearchParams(status ? { status, page: String(value) } : { page: String(value) })
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
      {!loading && meta && meta.total_pages > 0 && (
        <nav className="pagination" aria-label={t('pagination.label')}>
          <button type="button" className="secondary" onClick={() => changePage(Math.min(meta.page - 1, meta.total_pages))} disabled={meta.page <= 1}>
            {t('pagination.previous')}
          </button>
          <span>{t('pagination.pageOf', { page: meta.page, total: meta.total_pages })}</span>
          <button
            type="button"
            className="secondary"
            onClick={() => changePage(meta.page + 1)}
            disabled={meta.page >= meta.total_pages}
          >
            {t('pagination.next')}
          </button>
        </nav>
      )}
    </section>
  )
}
