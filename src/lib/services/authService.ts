import type { Api } from '@jellyfin/sdk';
import { createApi, authenticate } from '$lib/api/jellyfin.js';
import { session } from '$lib/state/session.js';
import { get } from 'svelte/store';
import {
  setBaseUrl as persistBaseUrl,
  setAccessToken as persistAccessToken,
  setUser as persistUser,
  getBaseUrl as readBaseUrl,
  getAccessToken as readAccessToken,
  getUser as readUser,
} from '$lib/core/storage.js';

export function validateServerUrl(input: string): { ok: true; url: string } | { ok: false; error: string } {
  if (!input || typeof input !== 'string') return { ok: false, error: 'Please enter a server URL' };
  let url: URL;
  try {
    url = new URL(input);
  } catch (e) {
    return { ok: false, error: 'Invalid URL format' };
  }
  if (!['http:', 'https:'].includes(url.protocol)) {
    return { ok: false, error: 'URL must start with http:// or https://' };
  }
  // Normalize: remove trailing slash; keep path prefix if provided
  const normalized = `${url.origin}${url.pathname.replace(/\/$/, '')}`;
  return { ok: true, url: normalized };
}

export function connectToServer(baseUrl: string): Api {
  const api = createApi(baseUrl);
  session.setBaseUrl(baseUrl);
  session.setApi(api);
  // Persist base URL so we can restore on next launch
  persistBaseUrl(baseUrl);
  return api;
}

export async function loginWithCredentials(api: Api, username: string, password: string) {
  const { token, userId, userName } = await authenticate(api, username, password);
  // Persist auth first
  persistAccessToken(token);
  persistUser({ id: userId, name: userName });
  // Update session
  session.setAuth(token, { id: userId, name: userName });
  // Recreate API with token so SDK carries Authorization by default
  const { baseUrl } = get(session);
  if (baseUrl) {
    const authedApi = createApi(baseUrl, token);
    session.setApi(authedApi);
  }
}

// Attempt to restore a previous session from storage (mobile/desktop)
export function restoreSession(): boolean {
  const baseUrl = readBaseUrl();
  const token = readAccessToken();
  const user = readUser();
  if (!baseUrl || !token || !user) return false;
  const api = createApi(baseUrl, token);
  session.setBaseUrl(baseUrl);
  session.setApi(api);
  session.setAuth(token, user);
  return true;
}

