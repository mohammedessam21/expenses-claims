import { Navigate, Route, Routes } from 'react-router-dom'
import { homePathFor } from './auth/homePath'
import { useAuth } from './auth/useAuth'
import { Layout } from './components/Layout'
import { RequireRole } from './components/RequireRole'
import { useI18n } from './i18n/useI18n'
import { CategoriesPage } from './pages/approver/CategoriesPage'
import { ReviewClaimPage } from './pages/approver/ReviewClaimPage'
import { ReviewQueuePage } from './pages/approver/ReviewQueuePage'
import { ClaimDetailPage } from './pages/employee/ClaimDetailPage'
import { MyClaimsPage } from './pages/employee/MyClaimsPage'
import { NewClaimPage } from './pages/employee/NewClaimPage'
import { LoginPage } from './pages/LoginPage'

export default function App() {
  const { user, restoring } = useAuth()
  const { t } = useI18n()

  if (restoring) {
    return <p className="page muted">{t('common.loading')}</p>
  }

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/claims" element={<RequireRole role="employee"><MyClaimsPage /></RequireRole>} />
        <Route path="/claims/new" element={<RequireRole role="employee"><NewClaimPage /></RequireRole>} />
        <Route path="/claims/:id" element={<RequireRole role="employee"><ClaimDetailPage /></RequireRole>} />
        <Route path="/review/claims" element={<RequireRole role="approver"><ReviewQueuePage /></RequireRole>} />
        <Route path="/review/claims/:id" element={<RequireRole role="approver"><ReviewClaimPage /></RequireRole>} />
        <Route path="/review/categories" element={<RequireRole role="approver"><CategoriesPage /></RequireRole>} />
        <Route path="*" element={<Navigate to={user ? homePathFor(user.role) : '/login'} replace />} />
      </Route>
    </Routes>
  )
}
