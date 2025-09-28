import { writable } from 'svelte/store';
import type { Api } from '@jellyfin/sdk';

export type UserInfo = { id: string; name: string };

export type SessionState = {
  baseUrl: string | null;
  api: Api | null;
  token: string | null;
  user: UserInfo | null;
  authenticated: boolean;
};

const initial: SessionState = {
  baseUrl: null,
  api: null,
  token: null,
  user: null,
  authenticated: false,
};

function createSessionStore() {
  const { subscribe, update, set } = writable<SessionState>(initial);

  return {
    subscribe,
    reset: () => set(initial),
    setBaseUrl: (baseUrl: string) => update((s) => ({ ...s, baseUrl })),
    setApi: (api: Api) => update((s) => ({ ...s, api })),
    setAuth: (token: string, user: UserInfo) =>
      update((s) => ({ ...s, token, user, authenticated: true })),
    logout: () => set(initial),
  };
}

export const session = createSessionStore();

