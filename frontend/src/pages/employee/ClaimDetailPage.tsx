import { useCallback, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router-dom'
import { fetchMyClaim, resubmitClaim, withdrawClaim } from '../../api/requests'
import type { ClaimDetail } from '../../api/types'
import { ClaimSummary } from '../../components/ClaimSummary'
import { ErrorAlert } from '../../components/ErrorAlert'
import { Timeline } from '../../components/Timeline'
import { useI18n } from '../../i18n/useI18n'
import { checkAmount } from '../../lib/claimForm'
import { apiErrorMessage } from '../../lib/errors'
import { halalasToSar } from '../../lib/money'
import { useApiData } from '../../lib/useApiData'

export function ClaimDetailPage() {
  const { id = '' } = useParams()
  const { t } = useI18n()
  const load = useCallback(() => fetchMyClaim(id), [id])
  const { data: claim, setData: setClaim, error: loadError, loading } = useApiData(load)
  const [actionError, setActionError] = useState<unknown>(null)
  const [busy, setBusy] = useState(false)
  const [editing, setEditing] = useState(false)

  async function run(action: () => Promise<ClaimDetail>) {
    setBusy(true)
    setActionError(null)
    try {
      setClaim(await action())
      setEditing(false)
    } catch (error) {
      setActionError(error)
    } finally {
      setBusy(false)
    }
  }

  function handleWithdraw(current: ClaimDetail) {
    if (window.confirm(t('claim.withdrawConfirm'))) {
      run(() => withdrawClaim(current.id))
    }
  }

  return (
    <section>
      <Link to="/claims">{t('common.back')}</Link>
      <ErrorAlert message={loadError ? apiErrorMessage(loadError, t) : null} />
      {loading && !claim && <p className="muted">{t('common.loading')}</p>}
      {claim && (
        <>
          <ClaimSummary claim={claim} />
          <ErrorAlert message={actionError ? apiErrorMessage(actionError, t) : null} />
          <div className="actions">
            {claim.available_actions.includes('resubmit') && !editing && (
              <button type="button" onClick={() => setEditing(true)} disabled={busy}>
                {t('action.resubmit')}
              </button>
            )}
            {claim.available_actions.includes('withdraw') && (
              <button type="button" className="danger" onClick={() => handleWithdraw(claim)} disabled={busy}>
                {t('action.withdraw')}
              </button>
            )}
          </div>
          {editing && claim.available_actions.includes('resubmit') && (
            <ResubmitForm
              claim={claim}
              busy={busy}
              onCancel={() => setEditing(false)}
              onSubmit={(edits) => run(() => resubmitClaim(claim.id, edits))}
            />
          )}
          <Timeline events={claim.events} />
        </>
      )}
    </section>
  )
}

interface ResubmitFormProps {
  claim: ClaimDetail
  busy: boolean
  onCancel: () => void
  onSubmit: (edits: { amount_halalas: number; description: string }) => void
}

function ResubmitForm({ claim, busy, onCancel, onSubmit }: ResubmitFormProps) {
  const { t, formatSar } = useI18n()
  const [amount, setAmount] = useState(halalasToSar(claim.amount_halalas))
  const [description, setDescription] = useState(claim.description)
  const [attempted, setAttempted] = useState(false)

  const amountCheck = checkAmount(amount, claim.limit_halalas_at_submission)
  const amountError = amountCheck.ok ? null : t(amountCheck.error, { limit: formatSar(claim.limit_halalas_at_submission) })
  const descriptionError = description.trim() ? null : t('validation.descriptionRequired')

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setAttempted(true)
    if (!amountCheck.ok || descriptionError) {
      return
    }
    onSubmit({ amount_halalas: amountCheck.halalas, description: description.trim() })
  }

  return (
    <form className="card" onSubmit={handleSubmit} noValidate>
      <h2>{t('claim.resubmitTitle')}</h2>
      <label className="field">
        <span>{t('newClaim.amount')}</span>
        <input inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)} />
        {attempted && amountError && <span className="field-error">{amountError}</span>}
      </label>
      <label className="field">
        <span>{t('newClaim.description')}</span>
        <textarea rows={3} value={description} onChange={(event) => setDescription(event.target.value)} />
        {attempted && descriptionError && <span className="field-error">{descriptionError}</span>}
      </label>
      <div className="actions">
        <button type="submit" disabled={busy}>
          {t('action.resubmit')}
        </button>
        <button type="button" className="secondary" onClick={onCancel} disabled={busy}>
          {t('common.cancel')}
        </button>
      </div>
    </form>
  )
}
