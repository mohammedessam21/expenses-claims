import { useState, type FormEvent } from 'react'
import { Navigate } from 'react-router-dom'
import { homePathFor } from '../auth/homePath'
import { useAuth } from '../auth/useAuth'
import { ErrorAlert } from '../components/ErrorAlert'
import type { TranslationKey } from '../i18n/context'
import { useI18n } from '../i18n/useI18n'

export function LoginPage() {
  const { user, signIn } = useAuth()
  const { t } = useI18n()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errorKey, setErrorKey] = useState<TranslationKey | null>(null)
  const [submitting, setSubmitting] = useState(false)

  if (user) {
    return <Navigate to={homePathFor(user.role)} replace />
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (!email.trim() || !password) {
      setErrorKey('login.required')
      return
    }
    setSubmitting(true)
    setErrorKey(null)
    try {
      await signIn(email.trim(), password)
    } catch {
      setErrorKey('login.failed')
      setSubmitting(false)
    }
  }

  return (
    <form className="card narrow" onSubmit={handleSubmit} noValidate>
      <h1>{t('login.title')}</h1>
      <label className="field">
        <span>{t('login.email')}</span>
        <input type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} />
      </label>
      <label className="field">
        <span>{t('login.password')}</span>
        <input
          type="password"
          autoComplete="current-password"
          value={password}
          onChange={(event) => setPassword(event.target.value)}
        />
      </label>
      <ErrorAlert message={errorKey && t(errorKey)} />
      <button type="submit" disabled={submitting}>
        {submitting ? t('login.submitting') : t('login.submit')}
      </button>
    </form>
  )
}
