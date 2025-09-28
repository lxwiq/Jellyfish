import { Jellyfin, type Api } from '@jellyfin/sdk';

// NOTE: .augment/rules.md says do not use Axios directly. We only use the SDK.

function getOrCreateDeviceId(): string {
  const key = 'jellyfish.deviceId';
  try {
    const existing = localStorage.getItem(key);
    if (existing) return existing;
    const id = crypto?.randomUUID?.() ?? `${Date.now()}-${Math.random()}`;
    localStorage.setItem(key, id);
    return id;
  } catch {
    // Fallback in non-browser or restricted environments
    return 'jellyfish-device';
  }
}

const jellyfin = new Jellyfin({
  clientInfo: {
    name: 'Jellyfish',
    version: '0.1.0',
  },
  deviceInfo: {
    id: getOrCreateDeviceId(),
    name: 'Jellyfish Client',
  },
});

export function createApi(baseUrl: string, accessToken?: string): Api {
  // Ensure no trailing slash to avoid double slashes in requests.
  const normalized = baseUrl.replace(/\/$/, '');
  return jellyfin.createApi(normalized, accessToken);
}

export async function authenticate(
  api: Api,
  username: string,
  password: string
): Promise<{ token: string; userId: string; userName: string }>
{
  const res = await api.authenticateUserByName(username, password);
  const data = res.data;
  const token = (data as any).AccessToken ?? (data as any).accessToken;
  const user = (data as any).User ?? (data as any).user;
  if (!token || !user) {
    throw new Error('Invalid authentication response from server');
  }
  return { token, userId: user.Id ?? user.id, userName: user.Name ?? user.name };
}

