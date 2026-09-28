import type { JSX } from 'react';

/**
 * @function LogoComponent
 * @description The app's icon: a euro sign on a violet tile.
 */
function LogoComponent({ size = 32 }: { size?: number }): JSX.Element {
    return (
        <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true" className="shrink-0">
            <defs>
                <linearGradient id="logo-tile" x1="0" y1="0" x2="1" y2="1">
                    <stop offset="0" stopColor="#8B74E8" />
                    <stop offset="1" stopColor="#5B45B8" />
                </linearGradient>
            </defs>
            <rect width="64" height="64" rx="15" fill="url(#logo-tile)" />
            <path d="M41 21.5a12 12 0 1 0 0 21M17 29h17M17 35h17" fill="none" stroke="#fff" strokeWidth="4" strokeLinecap="round" />
        </svg>
    );
}

export default LogoComponent;
