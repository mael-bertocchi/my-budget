import { useSession } from '@application/session-context';
import LogoComponent from '@components/logo';
import SpinnerComponent from '@components/spinner';
import { messageOf } from '@core/errors';
import { useEffect, useRef, useState, type ClipboardEvent, type JSX, type KeyboardEvent } from 'react';

/**
 * @constant LENGTH
 * @description How many digits the code has.
 */
const LENGTH = 6;

/**
 * @constant EMPTY
 * @description A code with nothing typed yet.
 */
const EMPTY: string[] = Array.from({ length: LENGTH }, () => '');

/**
 * @function SignInPage
 * @description Six boxes for the six-digit code set in the server's environment. Typing moves from box to box, a pasted
 * code fills them all, and the last digit submits it. A wrong code shakes the boxes and clears them.
 */
function SignInPage(): JSX.Element {
    const { signIn } = useSession();
    const [digits, setDigits] = useState<string[]>(EMPTY);
    const [error, setError] = useState<string | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [attempts, setAttempts] = useState(0);
    const boxes = useRef<(HTMLInputElement | null)[]>([]);

    useEffect(() => {
        boxes.current[0]?.focus();
    }, []);

    /**
     * @function focus
     * @description Moves the caret to a box.
     */
    const focus = (index: number): void => {
        boxes.current[Math.min(LENGTH - 1, Math.max(0, index))]?.focus();
    };

    /**
     * @function submit
     * @description Tries the code, and starts over on a wrong one.
     */
    const submit = async (code: string): Promise<void> => {
        setIsSubmitting(true);
        setError(null);

        try {
            await signIn(code);
        } catch (failure: unknown) {
            setError(messageOf(failure));
            setAttempts((count) => count + 1);
            setDigits(EMPTY);
            setIsSubmitting(false);
            window.requestAnimationFrame(() => focus(0));
        }
    };

    /**
     * @function fill
     * @description Writes digits into the boxes from one of them on, then submits once all six are there.
     */
    const fill = (from: number, typed: string): void => {
        const incoming = typed.replace(/\D/g, '').split('');

        if (incoming.length === 0) {
            return;
        }

        const next = [...digits];

        incoming.slice(0, LENGTH - from).forEach((digit, offset) => {
            next[from + offset] = digit;
        });

        setDigits(next);
        focus(from + incoming.length);

        if (next.every((digit) => digit !== '')) {
            void submit(next.join(''));
        }
    };

    /**
     * @function handleChange
     * @description Takes what was typed in a box. A digit typed after the one already there replaces it; several digits
     * at once — autofill on a phone — spread over the next boxes.
     */
    const handleChange = (index: number, value: string): void => {
        const current = digits[index] ?? '';

        fill(index, current !== '' && value.startsWith(current) ? value.slice(current.length) : value);
    };

    /**
     * @function handleKeyDown
     * @description Backspace clears the box, or the previous one when this one is empty; the arrows move between boxes.
     */
    const handleKeyDown = (index: number, event: KeyboardEvent<HTMLInputElement>): void => {
        if (event.key === 'Backspace') {
            event.preventDefault();

            const target = digits[index] === '' ? index - 1 : index;

            if (target >= 0) {
                setDigits(digits.map((digit, position) => (position === target ? '' : digit)));
                focus(target);
            }
        } else if (event.key === 'ArrowLeft') {
            focus(index - 1);
        } else if (event.key === 'ArrowRight') {
            focus(index + 1);
        }
    };

    /**
     * @function handlePaste
     * @description A pasted code fills every box from the first.
     */
    const handlePaste = (event: ClipboardEvent<HTMLInputElement>): void => {
        event.preventDefault();
        fill(0, event.clipboardData.getData('text'));
    };

    return (
        <main className="flex min-h-dvh items-center justify-center px-5">
            <div className="w-full max-w-[420px] animate-rise text-center">
                <div className="mx-auto w-fit rounded-[18px] shadow-card">
                    <LogoComponent size={68} />
                </div>
                <h1 className="mt-6 text-[34px] font-semibold tracking-tight">My Budget</h1>
                <p className="mt-2 text-[17px] text-ink-secondary">Enter your code to open your budget.</p>

                <div key={attempts} className={`mt-10 flex justify-center gap-2 sm:gap-2.5 ${attempts > 0 ? 'animate-shake' : ''}`} role="group" aria-label="Six-digit code">
                    {digits.map((digit, index) => (
                        <input
                            key={index}
                            ref={(element) => {
                                boxes.current[index] = element;
                            }}
                            type="password"
                            inputMode="numeric"
                            autoComplete="off"
                            maxLength={LENGTH}
                            value={digit}
                            disabled={isSubmitting}
                            aria-label={`Digit ${index + 1}`}
                            onChange={(event) => handleChange(index, event.target.value)}
                            onKeyDown={(event) => handleKeyDown(index, event)}
                            onPaste={handlePaste}
                            onFocus={(event) => event.target.select()}
                            className={`h-16 w-12 rounded-2xl bg-white text-center text-[28px] font-semibold caret-transparent shadow-control outline-none ring-1 ring-hairline transition focus:ring-2 focus:ring-accent disabled:opacity-60 sm:w-14 ${index === 3 ? 'ml-2 sm:ml-3' : ''}`}
                        />
                    ))}
                </div>

                <div className="mt-6 flex h-6 items-center justify-center">
                    {isSubmitting ? <SpinnerComponent /> : error !== null && <p className="text-[15px] text-negative-text" role="alert">{error}</p>}
                </div>
            </div>
        </main>
    );
}

export default SignInPage;
