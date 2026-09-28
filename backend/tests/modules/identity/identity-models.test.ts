import { LoginSchema, LogoutSchema, RefreshSchema } from 'src/modules/identity/identity-models';
import { describe, expect, it } from 'vitest';

describe('LoginSchema', () => {
    it('accepts a six-digit code', () => {
        expect(LoginSchema.safeParse({ code: '048213' }).success).toBe(true);
    });

    it('rejects a code of another length or with anything but digits', () => {
        expect(LoginSchema.safeParse({ code: '12345' }).success).toBe(false);
        expect(LoginSchema.safeParse({ code: '1234567' }).success).toBe(false);
        expect(LoginSchema.safeParse({ code: '12a456' }).success).toBe(false);
    });

    it('rejects the old username and password body', () => {
        expect(LoginSchema.safeParse({ username: 'owner', password: 'secret' }).success).toBe(false);
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
