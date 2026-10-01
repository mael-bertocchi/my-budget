import OperationEditorProvider from '@application/editor';
import { useBudget } from '@application/hooks';
import { useServices } from '@application/services';
import { useSession } from '@application/session-context';
import NavigationComponent from '@components/navigation';
import { t } from '@core/i18n';
import SpinnerComponent from '@components/spinner';
import SignInPage from '@pages/sign-in/sign-in';
import type { JSX } from 'react';
import { Outlet, ScrollRestoration } from 'react-router-dom';

/**
 * @function LayoutComponent
 * @description The page's frame. Signed out, it shows the code screen; signed in, it waits for the budget's first read,
 * then shows the navigation and the current tab.
 */
function LayoutComponent(): JSX.Element {
    const { state } = useSession();
    const { document, status, error } = useBudget();
    const { store } = useServices();

    if (state === 'signedOut') {
        return <SignInPage />;
    }

    if (document === null) {
        return (
            <main className="flex min-h-dvh flex-col items-center justify-center gap-4 px-6 text-center">
                {status === 'syncing' ? (
                    <SpinnerComponent size={28} />
                ) : (
                    <>
                        <p className="text-[17px] font-semibold">{t('layout.loadFailed')}</p>
                        <p className="text-[15px] text-ink-secondary">{error}</p>
                        <button type="button" onClick={() => void store.refresh()} className="mt-2 rounded-full bg-accent px-5 py-2 text-[15px] font-semibold text-white">{t('layout.tryAgain')}</button>
                    </>
                )}
            </main>
        );
    }

    return (
        <OperationEditorProvider>
            <NavigationComponent />
            <ScrollRestoration />
            <main className="mx-auto max-w-5xl px-5 pb-28 pt-8 sm:px-8 sm:pb-16 sm:pt-10">
                <Outlet />
            </main>
        </OperationEditorProvider>
    );
}

export default LayoutComponent;
