import { useLanguage } from '@application/hooks';
import LayoutComponent from '@application/layout';
import BudgetPage from '@pages/budget/budget';
import HistoryPage from '@pages/history/history';
import SettingsPage from '@pages/settings/settings';
import type { JSX } from 'react';
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

/**
 * @function RouterComponent
 * @description The routed pages, drawn afresh in a language picked in Settings: every sentence on them is looked up while
 * rendering, so redrawing them is all a new language takes. The session and the budget sit above and are kept.
 */
function RouterComponent(): JSX.Element {
    const language = useLanguage();

    return <RouterProvider key={language} router={router} />;
}

export default RouterComponent;
