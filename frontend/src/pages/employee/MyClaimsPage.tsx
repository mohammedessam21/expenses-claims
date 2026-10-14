import { Link } from 'react-router-dom'
import { fetchMyClaims } from '../../api/requests'
import { ClaimsTable } from '../../components/ClaimsTable'
import { ErrorAlert } from '../../components/ErrorAlert'
import { useI18n } from '../../i18n/useI18n'
import { apiErrorMessage } from '../../lib/errors'
import { useApiData } from '../../lib/useApiData'

export function MyClaimsPage() {
  const { t } = useI18n()
  const { data: claims, error, loading } = useApiData(fetchMyClaims)

  return (
    <section>
      <div className="page-heading">
        <h1>{t('myClaims.title')}</h1>
        <Link className="button" to="/claims/new">
          {t('myClaims.newClaim')}
        </Link>
      </div>
      <ErrorAlert message={error ? apiErrorMessage(error, t) : null} />
      {loading && <p className="muted">{t('common.loading')}</p>}
      {claims && claims.length === 0 && <p className="muted">{t('myClaims.empty')}</p>}
      {claims && claims.length > 0 && <ClaimsTable claims={claims} detailPath={(claim) => `/claims/${claim.id}`} />}
    </section>
  )
}
