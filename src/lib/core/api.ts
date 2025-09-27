import { buildEmbyAuthHeader, getAccessToken, getBaseUrl, getOrCreateDeviceId, getUserId } from './storage';

function assertBase(): string {
  const base = getBaseUrl();
  if (!base) throw new Error('Base URL not set');
  return base;
}

function assertUser(): string {
  const uid = getUserId();
  if (!uid) throw new Error('User not authenticated');
  return uid;
}

export function authHeaders(): Headers {
  const headers = new Headers();
  const token = getAccessToken();
  const device = typeof navigator !== 'undefined' ? navigator.userAgent : 'Server';
  const deviceId = getOrCreateDeviceId();
  headers.set('X-Emby-Authorization', buildEmbyAuthHeader({ client: 'Jellyfish', device, deviceId, version: '0.1.0' }));
  if (token) headers.set('X-MediaBrowser-Token', token);
  return headers;
}

function withQuery(url: string, params?: Record<string, string | number | boolean | undefined | null>): string {
  if (!params) return url;
  const u = new URL(url, 'http://dummy'); // base won't be used if absolute
  const search = new URLSearchParams(u.search);
  for (const [k, v] of Object.entries(params)) {
    if (v === undefined || v === null) continue;
    search.set(k, String(v));
  }
  const qs = search.toString();
  return qs ? `${url}${url.includes('?') ? '&' : '?'}${qs}` : url;
}

export async function apiGet<T>(path: string, params?: Record<string, unknown>, fetchImpl: typeof fetch = fetch): Promise<T> {
  const base = assertBase();
  const url = withQuery(`${base}${path.startsWith('/') ? '' : '/'}${path}` as string, params as any);
  const res = await fetchImpl(url, { headers: authHeaders() });
  if (!res.ok) throw new Error(`GET ${path} failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export type LibraryItem = {
  Id: string;
  Name: string;
  Type: string;
  PrimaryImageTag?: string;
  ImageTags?: Record<string, string>;
};

export type ItemsResponse<T = LibraryItem> = {
  Items: T[];
  TotalRecordCount?: number;
};


export async function getLatestMovies(limit = 20, fetchImpl: typeof fetch = fetch): Promise<LibraryItem[]> {
  const userId = assertUser();
  return apiGet<LibraryItem[]>(`/Users/${userId}/Items/Latest`, {
    includeItemTypes: 'Movie',
    limit,
    fields: 'PrimaryImageAspectRatio',
  }, fetchImpl);
}

export async function getLatestSeries(limit = 20, fetchImpl: typeof fetch = fetch): Promise<LibraryItem[]> {
  const userId = assertUser();
  return apiGet<LibraryItem[]>(`/Users/${userId}/Items/Latest`, {
    includeItemTypes: 'Series',
    limit,
    fields: 'PrimaryImageAspectRatio',
  }, fetchImpl);
}


export type UserView = { Id: string; Name: string; CollectionType?: string };

export async function getUserViews(fetchImpl: typeof fetch = fetch): Promise<UserView[]> {
  const userId = assertUser();
  const views = await apiGet<{ Items: UserView[] }>(`/Users/${userId}/Views`, undefined, fetchImpl);
  return views?.Items ?? [];
}

async function listItemsInViews(
  collectionType: 'movies' | 'tvshows',
  includeItemTypes: 'Movie' | 'Series',
  limitPerView = 500,
  fetchImpl: typeof fetch = fetch
) {
  const userId = assertUser();
  const views = await getUserViews(fetchImpl);
  const matching = views.filter((v) => (v.CollectionType || '').toLowerCase() === collectionType);
  const all: LibraryItem[] = [];
  for (const v of matching) {
    const resp = await apiGet<ItemsResponse>(`/Users/${userId}/Items`, {
      ParentId: v.Id,
      includeItemTypes,
      recursive: true,
      sortBy: 'DateCreated',
      sortOrder: 'Descending',
      limit: limitPerView,
      fields: 'PrimaryImageAspectRatio,ImageTags,PrimaryImageTag'
    }, fetchImpl);
    all.push(...(resp?.Items ?? []));
  }
  return all;
}

export async function listMovies(limit = 60, fetchImpl: typeof fetch = fetch): Promise<LibraryItem[]> {
  const userId = assertUser();
  const directRes = await apiGet<ItemsResponse>(`/Users/${userId}/Items`, {
    includeItemTypes: 'Movie',
    recursive: true,
    sortBy: 'DateCreated',
    sortOrder: 'Descending',
    limit,
    fields: 'PrimaryImageAspectRatio,ImageTags,PrimaryImageTag'
  }, fetchImpl);
  const direct = directRes?.Items ?? [];
  if (direct.length) return direct;
  // Fallback: agrège sur les bibliothèques "movies"
  return listItemsInViews('movies', 'Movie', limit, fetchImpl);
}

export async function listSeries(limit = 60, fetchImpl: typeof fetch = fetch): Promise<LibraryItem[]> {
  const userId = assertUser();
  const directRes = await apiGet<ItemsResponse>(`/Users/${userId}/Items`, {
    includeItemTypes: 'Series',
    recursive: true,
    sortBy: 'DateCreated',
    sortOrder: 'Descending',
    limit,
    fields: 'PrimaryImageAspectRatio,ImageTags,PrimaryImageTag'
  }, fetchImpl);
  const direct = directRes?.Items ?? [];
  if (direct.length) return direct;
  // Fallback: agrège sur les bibliothèques "tvshows"
  return listItemsInViews('tvshows', 'Series', limit, fetchImpl);
}

export type UserData = {
  Played?: boolean;
  PlaybackPositionTicks?: number;
  PlayCount?: number;
  LastPlayedDate?: string;
};

export type ItemDetail = LibraryItem & {
  Overview?: string;
  ProductionYear?: number;
  RunTimeTicks?: number;
  Genres?: string[];
  BackdropImageTags?: string[];
  CommunityRating?: number;
  OfficialRating?: string;
  Studios?: Array<{ Name: string; Id: string }>;
  UserData?: UserData;
};

export async function getItem(id: string, fetchImpl: typeof fetch = fetch): Promise<ItemDetail> {
  const userId = assertUser();
  return apiGet<ItemDetail>(`/Users/${userId}/Items/${id}`, {
    fields: 'Overview,RunTimeTicks,ProductionYear,ImageTags,PrimaryImageTag,Genres,BackdropImageTags,CommunityRating,OfficialRating,Studios,UserData',
    EnableUserData: true
  }, fetchImpl);
}

export type EpisodeItem = ItemDetail & {
  SeriesId?: string;
  SeriesName?: string;
  SeasonId?: string;
  IndexNumber?: number;            // episode number
  ParentIndexNumber?: number;      // season number
};

export async function getShowNextUp(seriesId: string, fetchImpl: typeof fetch = fetch): Promise<EpisodeItem | null> {
  const userId = assertUser();
  const res = await apiGet<ItemsResponse<EpisodeItem>>(`/Shows/${seriesId}/NextUp`, {
    UserId: userId,
    Limit: 1,
    Fields: 'Overview,RunTimeTicks,ImageTags,PrimaryImageTag,CommunityRating,OfficialRating,UserData,ParentIndexNumber,IndexNumber'
  }, fetchImpl);
  return res?.Items?.[0] ?? null;
}

export async function getNextUpEpisodes(limit = 20, fetchImpl: typeof fetch = fetch): Promise<EpisodeItem[]> {
  const userId = assertUser();
  const res = await apiGet<ItemsResponse<EpisodeItem>>(`/Shows/NextUp`, {
    UserId: userId,
    Limit: limit,
    Fields: 'Overview,RunTimeTicks,ImageTags,PrimaryImageTag,CommunityRating,OfficialRating,UserData,ParentIndexNumber,IndexNumber'
  }, fetchImpl);
  return res?.Items ?? [];
}

export async function getResumeItems(limit = 20, includeItemTypes: string, fetchImpl: typeof fetch = fetch) {
  const userId = assertUser();
  const res = await apiGet<ItemsResponse<ItemDetail>>(`/Users/${userId}/Items/Resume`, {
    IncludeItemTypes: includeItemTypes,
    Limit: limit,
    Fields: 'Overview,RunTimeTicks,ImageTags,PrimaryImageTag,CommunityRating,OfficialRating,UserData'
  }, fetchImpl);
  return res?.Items ?? [];
}

export async function getResumeMovies(limit = 20, fetchImpl: typeof fetch = fetch) {
  return getResumeItems(limit, 'Movie', fetchImpl);
}

export async function getResumeEpisodes(limit = 20, fetchImpl: typeof fetch = fetch) {
  return getResumeItems(limit, 'Episode', fetchImpl);
}




export function videoStreamUrl(id: string, opts?: { startTicks?: number; container?: 'mp4' | 'webm' }) {
  const base = assertBase();
  const token = getAccessToken();
  const url = new URL(`${base}/Videos/${id}/stream`);
  url.searchParams.set('static', 'true');
  url.searchParams.set('container', opts?.container ?? 'mp4');
  if (opts?.startTicks && opts.startTicks > 0) url.searchParams.set('StartTimeTicks', String(opts.startTicks));
  if (token) url.searchParams.set('api_key', token);
  return url.toString();
}
