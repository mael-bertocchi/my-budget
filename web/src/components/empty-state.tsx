import type { JSX } from 'react';

/**
 * @function EmptyStateComponent
 * @description A quiet card saying there is nothing to show yet.
 */
function EmptyStateComponent({ message }: { message: string }): JSX.Element {
    return <p className="rounded-2xl bg-fill px-5 py-8 text-center text-[15px] text-ink-secondary">{message}</p>;
}

export default EmptyStateComponent;
