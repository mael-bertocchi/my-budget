import { LoginSchema, LogoutSchema, RefreshSchema } from 'src/modules/identity/identity-models';
import { describe, expect, it } from 'vitest';

describe('LoginSchema', () => {
    it('accepts a username and password', () => {
        expect(LoginSchema.safeParse({ username: 'owner', password: 'secret' }).success).toBe(true);
    });

    it('rejects an empty username', () => {
        expect(LoginSchema.safeParse({ username: '', password: 'secret' }).success).toBe(false);
    });

    it('rejects an empty password', () => {
        expect(LoginSchema.safeParse({ username: 'owner', password: '' }).success).toBe(false);
    });
});

describe('RefreshSchema', () => {
    it('accepts a non-empty refresh token', () => {
        expect(RefreshSchema.safeParse({ refreshToken: 'abc.def.ghi' }).success).toBe(true);
    });

    it('rejects an empty refresh token', () => {
        expect(RefreshSchema.safeParse({ refreshToken: '' }).success).toBe(false);
    });
});

describe('LogoutSchema', () => {
    it('accepts a non-empty refresh token', () => {
        expect(LogoutSchema.safeParse({ refreshToken: 'abc.def.ghi' }).success).toBe(true);
    });

    it('rejects an empty refresh token', () => {
        expect(LogoutSchema.safeParse({ refreshToken: '' }).success).toBe(false);
    });
});
