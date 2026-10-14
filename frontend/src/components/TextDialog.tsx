import { useState, type FormEvent } from 'react'
import { useI18n } from '../i18n/useI18n'
import { ErrorAlert } from './ErrorAlert'

interface TextDialogProps {
  title: string
  label: string
  confirmLabel: string
  error: string | null
  submitting: boolean
  onConfirm: (text: string) => void
  onCancel: () => void
}

export function TextDialog({ title, label, confirmLabel, error, submitting, onConfirm, onCancel }: TextDialogProps) {
  const { t } = useI18n()
  const [text, setText] = useState('')
  const [validationError, setValidationError] = useState<string | null>(null)

  function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (!text.trim()) {
      setValidationError(t('validation.textRequired'))
      return
    }
    setValidationError(null)
    onConfirm(text.trim())
  }

  return (
    <div className="dialog-backdrop">
      <form className="dialog" role="dialog" aria-modal="true" aria-labelledby="dialog-title" onSubmit={handleSubmit} noValidate>
        <h2 id="dialog-title">{title}</h2>
        <label className="field">
          <span>{label}</span>
          <textarea rows={4} value={text} onChange={(event) => setText(event.target.value)} autoFocus required />
          {validationError && <span className="field-error">{validationError}</span>}
        </label>
        <ErrorAlert message={error} />
        <div className="actions">
          <button type="submit" disabled={submitting || !text.trim()}>
            {confirmLabel}
          </button>
          <button type="button" className="secondary" onClick={onCancel} disabled={submitting}>
            {t('common.cancel')}
          </button>
        </div>
      </form>
    </div>
  )
}
