import type { Api } from '@jellyfin/sdk';
import { createApi, authenticate } from '$lib/api/jellyfin.js';
import { session } from '$lib/state/session.js';

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
  return api;
}

export async function loginWithCredentials(api: Api, username: string, password: string) {
  const { token, userId, userName } = await authenticate(api, username, password);
  session.setAuth(token, { id: userId, name: userName });
}

