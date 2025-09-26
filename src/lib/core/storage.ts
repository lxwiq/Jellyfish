export const STORAGE_KEYS = {
  baseUrl: 'jf.baseUrl',
  accessToken: 'jf.accessToken',
  userId: 'jf.userId',
  deviceId: 'jf.deviceId',
} as const;

export function safeGet(key: string): string | null {
  try { return localStorage.getItem(key); } catch { return null; }
}
export function safeSet(key: string, value: string) {
  try { localStorage.setItem(key, value); } catch {}
}
export function safeRemove(key: string) {
  try { localStorage.removeItem(key); } catch {}
}

export function getBaseUrl() { return safeGet(STORAGE_KEYS.baseUrl); }
export function setBaseUrl(v: string) { safeSet(STORAGE_KEYS.baseUrl, v); }

export function getAccessToken() { return safeGet(STORAGE_KEYS.accessToken); }
export function setAccessToken(v: string) { safeSet(STORAGE_KEYS.accessToken, v); }

export function getUserId() { return safeGet(STORAGE_KEYS.userId); }
export function setUserId(v: string) { safeSet(STORAGE_KEYS.userId, v); }

export function getOrCreateDeviceId(): string {
  let id = safeGet(STORAGE_KEYS.deviceId);
  if (!id) {
    id = (globalThis.crypto?.randomUUID?.() ?? Math.random().toString(36).slice(2));
    safeSet(STORAGE_KEYS.deviceId, id);
  }
  return id;
}

export function buildEmbyAuthHeader(params: { client: string; device: string; deviceId: string; version: string; }): string {
  const { client, device, deviceId, version } = params;
  return `MediaBrowser Client="${client}", Device="${device}", DeviceId="${deviceId}", Version="${version}"`;
}

