import { useState, type FormEvent } from 'react'
import { createCategory, fetchReviewCategories, updateCategory } from '../../api/requests'
import type { Category, CategoryInput } from '../../api/types'
import { ErrorAlert } from '../../components/ErrorAlert'
import { useI18n } from '../../i18n/useI18n'
import { apiErrorMessage } from '../../lib/errors'
import { halalasToSar, sarToHalalas } from '../../lib/money'
import { useApiData } from '../../lib/useApiData'

type Editing = { mode: 'new' } | { mode: 'edit'; category: Category }

export function CategoriesPage() {
  const { t, formatSar } = useI18n()
  const { data: categories, error, loading, reload } = useApiData(fetchReviewCategories)
  const [editing, setEditing] = useState<Editing | null>(null)

  async function save(input: CategoryInput) {
    if (editing?.mode === 'edit') {
      await updateCategory(editing.category.id, input)
    } else {
      await createCategory(input)
    }
    setEditing(null)
    reload()
  }

  return (
    <section>
      <div className="page-heading">
        <h1>{t('categories.title')}</h1>
        <button type="button" onClick={() => setEditing({ mode: 'new' })}>
          {t('categories.new')}
        </button>
      </div>
      {editing && (
        <CategoryForm
          key={editing.mode === 'edit' ? editing.category.id : 'new'}
          category={editing.mode === 'edit' ? editing.category : null}
          onSave={save}
          onCancel={() => setEditing(null)}
        />
      )}
      <ErrorAlert message={error ? apiErrorMessage(error, t) : null} />
      {loading && !categories && <p className="muted">{t('common.loading')}</p>}
      {categories && categories.length === 0 && <p className="muted">{t('categories.empty')}</p>}
      {categories && categories.length > 0 && (
        <table className="table">
          <thead>
            <tr>
              <th>{t('categories.nameEn')}</th>
              <th>{t('categories.nameAr')}</th>
              <th className="numeric">{t('categories.limit')}</th>
              <th>{t('categories.active')}</th>
              <th>{t('table.actions')}</th>
            </tr>
          </thead>
          <tbody>
            {categories.map((category) => (
              <tr key={category.id}>
                <td>{category.name_en}</td>
                <td dir="rtl">{category.name_ar}</td>
                <td className="numeric">{formatSar(category.limit_halalas)}</td>
                <td>{category.active ? t('common.yes') : t('common.no')}</td>
                <td>
                  <button type="button" className="secondary" onClick={() => setEditing({ mode: 'edit', category })}>
                    {t('common.edit')}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  )
}

interface CategoryFormProps {
  category: Category | null
  onSave: (input: CategoryInput) => Promise<void>
  onCancel: () => void
}

function CategoryForm({ category, onSave, onCancel }: CategoryFormProps) {
  const { t } = useI18n()
  const [nameEn, setNameEn] = useState(category?.name_en ?? '')
  const [nameAr, setNameAr] = useState(category?.name_ar ?? '')
  const [limit, setLimit] = useState(category ? halalasToSar(category.limit_halalas) : '')
  const [active, setActive] = useState(category?.active ?? true)
  const [attempted, setAttempted] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState<unknown>(null)

  const limitHalalas = sarToHalalas(limit)
  const errors = {
    nameEn: nameEn.trim() ? null : t('validation.nameEnRequired'),
    nameAr: nameAr.trim() ? null : t('validation.nameArRequired'),
    limit: limitHalalas !== null && limitHalalas > 0 ? null : t('validation.limitInvalid'),
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    setAttempted(true)
    if (errors.nameEn || errors.nameAr || limitHalalas === null || limitHalalas <= 0) {
      return
    }
    setSaving(true)
    setSaveError(null)
    try {
      await onSave({ name_en: nameEn.trim(), name_ar: nameAr.trim(), limit_halalas: limitHalalas, active })
    } catch (error) {
      setSaveError(error)
      setSaving(false)
    }
  }

  return (
    <form className="card" onSubmit={handleSubmit} noValidate>
      <h2>{category ? t('categories.edit') : t('categories.new')}</h2>
      <label className="field">
        <span>{t('categories.nameEn')}</span>
        <input value={nameEn} onChange={(event) => setNameEn(event.target.value)} />
        {attempted && errors.nameEn && <span className="field-error">{errors.nameEn}</span>}
      </label>
      <label className="field">
        <span>{t('categories.nameAr')}</span>
        <input dir="rtl" value={nameAr} onChange={(event) => setNameAr(event.target.value)} />
        {attempted && errors.nameAr && <span className="field-error">{errors.nameAr}</span>}
      </label>
      <label className="field">
        <span>{t('categories.limit')}</span>
        <input inputMode="decimal" value={limit} onChange={(event) => setLimit(event.target.value)} placeholder="500.00" />
        {attempted && errors.limit && <span className="field-error">{errors.limit}</span>}
      </label>
      <label className="checkbox">
        <input type="checkbox" checked={active} onChange={(event) => setActive(event.target.checked)} />
        <span>{t('categories.active')}</span>
      </label>
      <ErrorAlert message={saveError ? apiErrorMessage(saveError, t) : null} />
      <div className="actions">
        <button type="submit" disabled={saving}>
          {saving ? t('common.saving') : t('common.save')}
        </button>
        <button type="button" className="secondary" onClick={onCancel} disabled={saving}>
          {t('common.cancel')}
        </button>
      </div>
    </form>
  )
}
