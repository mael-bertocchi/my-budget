import '@/styles/index.css';
import LayoutComponent from '@application/layout';
import NoticesProvider from '@application/notices';
import SessionProvider from '@application/session';
import BudgetPage from '@pages/budget/budget';
import HistoryPage from '@pages/history/history';
import SettingsPage from '@pages/settings/settings';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { createBrowserRouter, Navigate, RouterProvider } from 'react-router-dom';

/**
 * @constant router
 * @description The three tabs, each at its own path so a reload stays where it was.
 */
const router = createBrowserRouter([
    {
        path: '/',
        element: <LayoutComponent />,
        children: [
            { index: true, element: <Navigate to="/budget" replace /> },
            { path: 'budget', element: <BudgetPage /> },
            { path: 'history', element: <HistoryPage /> },
            { path: 'settings', element: <SettingsPage /> },
            { path: '*', element: <Navigate to="/budget" replace /> }
        ]
    }
]);

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <NoticesProvider>
            <SessionProvider>
                <RouterProvider router={router} />
            </SessionProvider>
        </NoticesProvider>
    </StrictMode>
);
