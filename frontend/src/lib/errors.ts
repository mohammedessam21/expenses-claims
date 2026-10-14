import { serverErrorMessage } from '../api/client'
import type { I18nValue } from '../i18n/context'

export function apiErrorMessage(error: unknown, t: I18nValue['t']) {
  return serverErrorMessage(error) ?? t('common.networkError')
}
