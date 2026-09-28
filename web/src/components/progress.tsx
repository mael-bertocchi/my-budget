import type { JSX, ReactNode } from 'react';

/**
 * @interface RingProps
 * @description What the budget ring shows.
 */
interface RingProps {
    progress: number; /*!< How full it is, between 0 and 1 */
    color: string; /*!< The filled arc's colour */
    size?: number; /*!< Its diameter, in pixels */
    children: ReactNode; /*!< What sits in its middle */
}

/**
 * @function RingComponent
 * @description The budget ring: a thick arc with rounded ends around the month's main figure.
 */
export function RingComponent({ progress, color, size = 232, children }: RingProps): JSX.Element {
    const stroke = 18;
    const radius = (size - stroke) / 2;
    const circumference = 2 * Math.PI * radius;
    const filled = Math.min(1, Math.max(0, progress));

    return (
        <div className="relative" style={{ width: size, height: size }}>
            <svg width={size} height={size} className="-rotate-90" aria-hidden="true">
                <circle cx={size / 2} cy={size / 2} r={radius} fill="none" stroke="#EDEDF0" strokeWidth={stroke} />
                <circle
                    cx={size / 2}
                    cy={size / 2}
                    r={radius}
                    fill="none"
                    stroke={color}
                    strokeWidth={stroke}
                    strokeLinecap="round"
                    strokeDasharray={circumference}
                    strokeDashoffset={circumference * (1 - filled)}
                    style={{ transition: 'stroke-dashoffset 0.8s cubic-bezier(0.2, 0.8, 0.2, 1), stroke 0.3s' }}
                    opacity={filled === 0 ? 0 : 1}
                />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center text-center">{children}</div>
        </div>
    );
}

/**
 * @function TrackBarComponent
 * @description A thin progress bar, for a category against its limit.
 */
export function TrackBarComponent({ progress, color }: { progress: number; color: string }): JSX.Element {
    return (
        <div className="h-1.5 w-full overflow-hidden rounded-full bg-fill-strong">
            <div
                className="h-full rounded-full"
                style={{ width: `${Math.min(1, Math.max(0, progress)) * 100}%`, backgroundColor: color, transition: 'width 0.6s cubic-bezier(0.2, 0.8, 0.2, 1)' }}
            />
        </div>
    );
}
