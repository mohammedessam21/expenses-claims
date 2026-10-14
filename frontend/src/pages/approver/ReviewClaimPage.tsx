import { useCallback, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { approveClaim, fetchReviewClaim, rejectClaim, returnClaim, startReview } from '../../api/requests'
import type { ClaimDetail } from '../../api/types'
import { ClaimSummary } from '../../components/ClaimSummary'
import { ErrorAlert } from '../../components/ErrorAlert'
import { TextDialog } from '../../components/TextDialog'
import { Timeline } from '../../components/Timeline'
import { useI18n } from '../../i18n/useI18n'
import { apiErrorMessage } from '../../lib/errors'
import { useApiData } from '../../lib/useApiData'

type TextAction = 'reject' | 'return'

export function ReviewClaimPage() {
  const { id = '' } = useParams()
  const { t } = useI18n()
  const load = useCallback(() => fetchReviewClaim(id), [id])
  const { data: claim, setData: setClaim, error: loadError, loading } = useApiData(load)
  const [actionError, setActionError] = useState<unknown>(null)
  const [dialogError, setDialogError] = useState<unknown>(null)
  const [busy, setBusy] = useState(false)
  const [dialog, setDialog] = useState<TextAction | null>(null)

  async function run(action: () => Promise<ClaimDetail>) {
    setBusy(true)
    setActionError(null)
    try {
      setClaim(await action())
    } catch (error) {
      setActionError(error)
    } finally {
      setBusy(false)
    }
  }

  async function confirmDialog(current: ClaimDetail, action: TextAction, text: string) {
    setBusy(true)
    setDialogError(null)
    try {
      setClaim(action === 'reject' ? await rejectClaim(current.id, text) : await returnClaim(current.id, text))
      setDialog(null)
    } catch (error) {
      setDialogError(error)
    } finally {
      setBusy(false)
    }
  }

  function openDialog(action: TextAction) {
    setDialogError(null)
    setDialog(action)
  }

  const allowed = (action: ClaimDetail['available_actions'][number]) => claim?.available_actions.includes(action) ?? false

  return (
    <section>
      <Link to="/review/claims">{t('common.back')}</Link>
      <ErrorAlert message={loadError ? apiErrorMessage(loadError, t) : null} />
      {loading && !claim && <p className="muted">{t('common.loading')}</p>}
      {claim && (
        <>
          <ClaimSummary claim={claim} />
          <ErrorAlert message={actionError ? apiErrorMessage(actionError, t) : null} />
          <div className="actions">
            {allowed('start_review') && (
              <button type="button" onClick={() => run(() => startReview(claim.id))} disabled={busy}>
                {t('action.start_review')}
              </button>
            )}
            {allowed('approve') && (
              <button type="button" onClick={() => run(() => approveClaim(claim.id))} disabled={busy}>
                {t('action.approve')}
              </button>
            )}
            {allowed('reject') && (
              <button type="button" className="danger" onClick={() => openDialog('reject')} disabled={busy}>
                {t('action.reject')}
              </button>
            )}
            {allowed('return') && (
              <button type="button" className="secondary" onClick={() => openDialog('return')} disabled={busy}>
                {t('action.return')}
              </button>
            )}
          </div>
          <Timeline events={claim.events} />
          {dialog && (
            <TextDialog
              title={t(dialog === 'reject' ? 'dialog.rejectTitle' : 'dialog.returnTitle')}
              label={t(dialog === 'reject' ? 'dialog.rejectLabel' : 'dialog.returnLabel')}
              confirmLabel={t(`action.${dialog}`)}
              error={dialogError ? apiErrorMessage(dialogError, t) : null}
              submitting={busy}
              onConfirm={(text) => confirmDialog(claim, dialog, text)}
              onCancel={() => setDialog(null)}
            />
          )}
        </>
      )}
    </section>
  )
}
