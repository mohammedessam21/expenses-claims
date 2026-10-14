import type { ClaimStatus } from '../api/types'
import { useI18n } from '../i18n/useI18n'

export function StatusBadge({ status }: { status: ClaimStatus }) {
  const { t } = useI18n()
  return <span className={`badge badge-${status}`}>{t(`status.${status}`)}</span>
}
