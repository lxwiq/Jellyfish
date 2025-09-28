import { writable } from 'svelte/store';
import { get } from 'svelte/store';
import { session } from '$lib/state/session';
import { getPlaybackInfo } from '$lib/services/mediaService';

export type PlayerState = {
  isOpen: boolean;
  itemId: string | null;
  src: string | null;
  loading: boolean;
  error: string | null;
};

function resolveStreamUrl(baseUrl: string, token: string, info: any): string | null {
  const ms = (info?.MediaSources ?? []);
  const first = ms[0] ?? {};
  let url: string = first.TranscodingUrl || first.DirectStreamUrl || '';
  if (url && !url.startsWith('http')) url = `${baseUrl}${url}`;
  if (url && url.indexOf('api_key=') === -1) url += (url.includes('?') ? '&' : '?') + `api_key=${encodeURIComponent(token)}`;
  return url || null;
}

function createPlayerStore() {
  const { subscribe, update, set } = writable<PlayerState>({ isOpen: false, itemId: null, src: null, loading: false, error: null });

  async function open(itemId: string) {
    const s = get(session);
    if (!s?.authenticated || !s?.baseUrl || !s?.token || !s?.user?.id) {
      update((st) => ({ ...st, isOpen: true, itemId, loading: false, error: 'Not authenticated' }));
      return;
    }
    set({ isOpen: true, itemId, src: null, loading: true, error: null });
    try {
      const info = await getPlaybackInfo(s.baseUrl, s.token, s.user.id, itemId);
      const src = resolveStreamUrl(s.baseUrl, s.token, info);
      if (!src) throw new Error('No playable media source');
      update((st) => ({ ...st, src, loading: false }));
    } catch (e) {
      console.error('Playback error', e);
      update((st) => ({ ...st, loading: false, error: 'Unable to start playback' }));
    }
  }

  function close() {
    set({ isOpen: false, itemId: null, src: null, loading: false, error: null });
  }

  return { subscribe, open, close };
}

export const player = createPlayerStore();
export const openPlayer = (itemId: string) => player.open(itemId);
export const closePlayer = () => player.close();

