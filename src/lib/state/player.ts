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
  candidates: string[];
  idx: number;
};

function appendApiKey(u: string, token: string) {
  if (!u) return u;
  return u + (u.includes('?') ? '&' : '?') + `api_key=${encodeURIComponent(token)}`;
}

function resolveCandidates(baseUrl: string, token: string, info: any, itemIdForPath?: string): string[] {
  const ms = (info?.MediaSources ?? []);
  const first = ms[0] ?? {};

  const out: string[] = [];

  // Prefer URLs provided by server
  let url: string = first.TranscodingUrl || first.DirectStreamUrl || '';
  if (url && !url.startsWith('http')) url = `${baseUrl}${url}`;
  if (url) out.push(url.includes('api_key=') ? url : appendApiKey(url, token));

  // Fallbacks: construct URLs from MediaSourceId / container
  const itemId = itemIdForPath || first?.Id || '';
  const mediaSourceId = first?.Id || '';
  const container = (first?.Container || '').toLowerCase();

  const candidates: string[] = [];
  if (mediaSourceId) {
    // Prefer HLS master (Safari native, others with hls.js)
    candidates.push(`${baseUrl}/Videos/${itemId}/master.m3u8?MediaSourceId=${encodeURIComponent(mediaSourceId)}`);
    // Try progressive MP4 remux (widely compatible)
    candidates.push(`${baseUrl}/Videos/${itemId}/stream.mp4?static=true&MediaSourceId=${encodeURIComponent(mediaSourceId)}`);
    // Try original container as progressive (if supported)
    if (container) {
      candidates.push(`${baseUrl}/Videos/${itemId}/stream.${container}?static=true&MediaSourceId=${encodeURIComponent(mediaSourceId)}`);
    }
    // Generic stream endpoint
    candidates.push(`${baseUrl}/Videos/${itemId}/stream?static=true&MediaSourceId=${encodeURIComponent(mediaSourceId)}`);
    // Direct download of the source file
    candidates.push(`${baseUrl}/Items/${itemId}/Download`);
  } else if (itemIdForPath) {
    // Last resort using item id only
    candidates.push(`${baseUrl}/Videos/${itemIdForPath}/master.m3u8`);
    candidates.push(`${baseUrl}/Videos/${itemIdForPath}/stream.mp4?static=true`);
    candidates.push(`${baseUrl}/Videos/${itemIdForPath}/stream`);
  }

  for (const c of candidates) {
    if (c) out.push(appendApiKey(c, token));
  }
  return out;
}

function createPlayerStore() {
  const { subscribe, update, set } = writable<PlayerState>({ isOpen: false, itemId: null, src: null, loading: false, error: null, candidates: [], idx: 0 });

  async function open(itemId: string) {
    const s = get(session);
    if (!s?.authenticated || !s?.baseUrl || !s?.token || !s?.user?.id) {
      update((st) => ({ ...st, isOpen: true, itemId, loading: false, error: 'Not authenticated' }));
      return;
    }
    set({ isOpen: true, itemId, src: null, loading: true, error: null, candidates: [], idx: 0 });
    try {
      const info = await getPlaybackInfo(s.baseUrl, s.token, s.user.id, itemId);
      const candidates = resolveCandidates(s.baseUrl, s.token, info, itemId);
      const first = candidates[0] ?? null;
      if (!first) throw new Error('No playable media source');
      update((st) => ({ ...st, src: first, candidates, idx: 0, loading: false }));
    } catch (e) {
      console.error('Playback error', e);
      update((st) => ({ ...st, loading: false, error: 'Unable to start playback' }));
    }
  }

  function next() {
    update((st) => {
      if (!st.candidates || st.idx == null) return st;
      const nextIdx = st.idx + 1;
      if (nextIdx >= st.candidates.length) return { ...st, error: st.error ?? 'Aucune source valide' };
      return { ...st, idx: nextIdx, src: st.candidates[nextIdx] };
    });
  }

  function close() {
    set({ isOpen: false, itemId: null, src: null, loading: false, error: null, candidates: [], idx: 0 });
  }

  return { subscribe, open, close, next };
}

export const player = createPlayerStore();
export const openPlayer = (itemId: string) => player.open(itemId);
export const closePlayer = () => player.close();
export const nextCandidate = () => (player as any).next?.();

