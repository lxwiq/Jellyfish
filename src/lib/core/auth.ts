import { buildEmbyAuthHeader, getAccessToken, getBaseUrl, getOrCreateDeviceId, setAccessToken, setBaseUrl, setUserId } from './storage';

export function normalizeBaseUrl(value: string): string {
  let v = value.trim();
  if (!v) return v;
  if (!/^https?:\/\//i.test(v)) v = `http://${v}`;
  return v.replace(/\/+$/, '');
}

export function isHostConfigured(): boolean { return !!getBaseUrl(); }
export function isAuthenticated(): boolean { return !!getAccessToken(); }

function endpoint(path: string): string {
  const base = getBaseUrl();
  if (!base) throw new Error('Base URL not set');
  return `${base}${path.startsWith('/') ? '' : '/'}${path}`;
}

export async function verifyServer(baseUrl: string, fetchImpl: typeof fetch = fetch): Promise<{ ok: true } | { ok: false; status?: number }>{
  try {
    const url = `${normalizeBaseUrl(baseUrl)}/System/Info/Public`;
    const res = await fetchImpl(url);
    if (!res.ok) return { ok: false, status: res.status };
    await res.json();
    return { ok: true };
  } catch {
    return { ok: false };
  }
}

export async function saveHostAndVerify(baseUrlRaw: string, fetchImpl: typeof fetch = fetch): Promise<void> {
  const baseUrl = normalizeBaseUrl(baseUrlRaw);
  const res = await verifyServer(baseUrl, fetchImpl);
  if (!res.ok) throw new Error('Server verification failed');
  setBaseUrl(baseUrl);
}

export type LoginResult = { userId: string; accessToken: string };

export async function loginByName(username: string, password: string, fetchImpl: typeof fetch = fetch): Promise<LoginResult> {
  const device = navigator?.userAgent ?? 'Unknown Device';
  const deviceId = getOrCreateDeviceId();
  const headers = new Headers();
  headers.set('Content-Type', 'application/json');
  headers.set('X-Emby-Authorization', buildEmbyAuthHeader({ client: 'Jellyfish', device, deviceId, version: '0.1.0' }));

  const body = JSON.stringify({ Username: username, Pw: password });
  const res = await fetchImpl(endpoint('/Users/AuthenticateByName'), { method: 'POST', headers, body });
  if (!res.ok) throw new Error('Bad credentials');
  const data = await res.json();
  const accessToken: string = data?.AccessToken;
  const userId: string = data?.User?.Id ?? data?.User?.id;
  if (!accessToken || !userId) throw new Error('Invalid auth response');
  setAccessToken(accessToken);
  setUserId(userId);
  return { userId, accessToken };
}

function fetchImplWithBase(fetchImpl: typeof fetch, baseUrl: string) {
  return (input: RequestInfo | URL, init?: RequestInit) => {
    const url = typeof input === 'string' || input instanceof URL ? String(input) : (input as Request).url;
    const absolute = url.startsWith('http://') || url.startsWith('https://');
    const full = absolute ? url : `${baseUrl}${url.startsWith('/') ? '' : '/'}${url}`;
    return fetchImpl(full, init);
  };
}

