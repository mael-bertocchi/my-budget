import '@/styles/index.css';
import NoticesProvider from '@application/notices';
import RouterComponent from '@application/router';
import SessionProvider from '@application/session';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';

createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <NoticesProvider>
            <SessionProvider>
                <RouterComponent />
            </SessionProvider>
        </NoticesProvider>
    </StrictMode>
);
