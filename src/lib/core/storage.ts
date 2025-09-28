// Simple persistent storage helpers for session data.
// We intentionally use localStorage for portability (Tauri desktop/mobile webview).
// Never store the password. We only persist baseUrl, access token, and user info.

export type StoredUser = { id: string; name: string };

const KEY_BASE_URL = 'jellyfish.baseUrl';
const KEY_ACCESS_TOKEN = 'jellyfish.accessToken';
const KEY_USER = 'jellyfish.user';
const KEY_QC_ENABLED = 'jellyfish.quickConnectEnabled';

function safeGet(key: string): string | null {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function safeSet(key: string, value: string) {
  try {
    localStorage.setItem(key, value);
  } catch {
    // ignore
  }
}

function safeRemove(key: string) {
  try {
    localStorage.removeItem(key);
  } catch {
    // ignore
  }
}

export function getBaseUrl(): string | null {
  return safeGet(KEY_BASE_URL);
}

export function setBaseUrl(url: string) {
  safeSet(KEY_BASE_URL, url);
}

export function getAccessToken(): string | null {
  return safeGet(KEY_ACCESS_TOKEN);
}

export function setAccessToken(token: string) {
  safeSet(KEY_ACCESS_TOKEN, token);
}

export function getUser(): StoredUser | null {
  const raw = safeGet(KEY_USER);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as StoredUser;
  } catch {
    return null;
  }
}

export function setUser(user: StoredUser) {
  safeSet(KEY_USER, JSON.stringify(user));
}

export function getQuickConnectEnabled(): boolean | null {
  const raw = safeGet(KEY_QC_ENABLED);
  if (raw == null) return null;
  return raw === '1' || raw === 'true';
}

export function setQuickConnectEnabled(enabled: boolean) {
  safeSet(KEY_QC_ENABLED, enabled ? '1' : '0');
}

export function clearSessionStorage() {
  safeRemove(KEY_BASE_URL);
  safeRemove(KEY_ACCESS_TOKEN);
  safeRemove(KEY_USER);
}

