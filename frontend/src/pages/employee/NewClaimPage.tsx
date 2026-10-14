import { useState, type FormEvent } from 'react'
import { useNavigate } from 'react-router-dom'
import { createClaim, fetchActiveCategories } from '../../api/requests'
import { ErrorAlert } from '../../components/ErrorAlert'
import { useI18n } from '../../i18n/useI18n'
import { checkAmount } from '../../lib/claimForm'
import { apiErrorMessage } from '../../lib/errors'
import { useApiData } from '../../lib/useApiData'

export function NewClaimPage() {
  const { t, categoryName, formatSar } = useI18n()
  const navigate = useNavigate()
  const { data: categories, error: loadError } = useApiData(fetchActiveCategories)
  const [categoryId, setCategoryId] = useState('')
  const [amount, setAmount] = useState('')
  const [spentOn, setSpentOn] = useState('')
  const [description, setDescription] = useState('')
  const [attempted, setAttempted] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [submitError, setSubmitError] = useState<unknown>(null)

  const category = categories?.find((item) => String(item.id) === categoryId) ?? null
  const amountCheck = checkAmount(amount, category?.limit_halalas ?? null)
  const errors = {
    category: category ? null : t('validation.categoryRequired'),
    amount: amountCheck.ok
      ? null
      : t(amountCheck.error, { limit: category ? formatSar(category.limit_halalas) : '' }),
    spentOn: spentOn ? null : t('validation.dateRequired'),
    description: description.trim() ? null : t('validation.descriptionRequired'),
  }
  const visibleErrors = attempted ? errors : null

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setAttempted(true)
    if (!category || !amountCheck.ok || errors.spentOn || errors.description) {
      return
    }
    setSubmitting(true)
    setSubmitError(null)
    try {
      const claim = await createClaim({
        category_id: category.id,
        amount_halalas: amountCheck.halalas,
        spent_on: spentOn,
        description: description.trim(),
      })
      navigate(`/claims/${claim.id}`)
    } catch (error) {
      setSubmitError(error)
      setSubmitting(false)
    }
  }

  return (
    <form className="card" onSubmit={handleSubmit} noValidate>
      <h1>{t('newClaim.title')}</h1>
      <ErrorAlert message={loadError ? apiErrorMessage(loadError, t) : null} />
      <label className="field">
        <span>{t('newClaim.category')}</span>
        <select value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
          <option value="">{t('newClaim.chooseCategory')}</option>
          {categories?.map((item) => (
            <option key={item.id} value={item.id}>
              {t('newClaim.categoryOption', { name: categoryName(item), limit: formatSar(item.limit_halalas) })}
            </option>
          ))}
        </select>
        {visibleErrors?.category && <span className="field-error">{visibleErrors.category}</span>}
      </label>
      <label className="field">
        <span>{t('newClaim.amount')}</span>
        <input inputMode="decimal" value={amount} onChange={(event) => setAmount(event.target.value)} placeholder="150.00" />
        {visibleErrors?.amount && <span className="field-error">{visibleErrors.amount}</span>}
      </label>
      <label className="field">
        <span>{t('newClaim.date')}</span>
        <input type="date" value={spentOn} onChange={(event) => setSpentOn(event.target.value)} />
        {visibleErrors?.spentOn && <span className="field-error">{visibleErrors.spentOn}</span>}
      </label>
      <label className="field">
        <span>{t('newClaim.description')}</span>
        <textarea rows={3} value={description} onChange={(event) => setDescription(event.target.value)} />
        {visibleErrors?.description && <span className="field-error">{visibleErrors.description}</span>}
      </label>
      <ErrorAlert message={submitError ? apiErrorMessage(submitError, t) : null} />
      <button type="submit" disabled={submitting}>
        {submitting ? t('common.saving') : t('newClaim.submit')}
      </button>
    </form>
  )
}
