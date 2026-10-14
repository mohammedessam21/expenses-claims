import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../auth/useAuth'
import { useI18n } from '../i18n/useI18n'

export function Layout() {
  const { user, signOut } = useAuth()
  const { t, toggleLanguage } = useI18n()

  return (
    <>
      <header className="topbar">
        <strong className="brand">{t('app.title')}</strong>
        {user && (
          <nav className="nav">
            {user.role === 'employee' ? (
              <>
                <NavLink to="/claims" end>
                  {t('nav.myClaims')}
                </NavLink>
                <NavLink to="/claims/new">{t('nav.newClaim')}</NavLink>
              </>
            ) : (
              <>
                <NavLink to="/review/claims">{t('nav.reviewQueue')}</NavLink>
                <NavLink to="/review/categories">{t('nav.categories')}</NavLink>
              </>
            )}
          </nav>
        )}
        <div className="topbar-end">
          {user && (
            <span className="muted">
              {user.name} · {user.company.name}
            </span>
          )}
          <button type="button" className="secondary" onClick={toggleLanguage}>
            {t('language.toggle')}
          </button>
          {user && (
            <button type="button" className="secondary" onClick={signOut}>
              {t('nav.logout')}
            </button>
          )}
        </div>
      </header>
      <main className="page">
        <Outlet />
      </main>
    </>
  )
}
