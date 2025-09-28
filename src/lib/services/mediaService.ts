import type { Api } from '@jellyfin/sdk';

// NOTE: We currently use fetch with Jellyfin's REST endpoints, aligned with how the home page does it.
// We pass the token via X-Emby-Token for requests, and use api_key query for <img> URLs.

export type JellyfinItem = Record<string, any>;

async function jfGet<T = any>(url: URL | string, token: string): Promise<T> {
  const res = await fetch(url.toString(), { headers: { 'X-Emby-Token': token } });
  if (!res.ok) throw new Error(`Jellyfin request failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export async function getContinueWatching(
  baseUrl: string,
  token: string,
  userId: string,
  limit = 24
): Promise<JellyfinItem[]> {
  const url = new URL(`${baseUrl}/Users/${userId}/Items/Resume`);
  url.searchParams.set('Limit', String(limit));
  url.searchParams.set('IncludeItemTypes', 'Movie,Episode');
  url.searchParams.set('Recursive', 'true');
  url.searchParams.set('Fields', 'PrimaryImageAspectRatio,SeriesInfo,UserData,RunTimeTicks,SeriesId,PrimaryImageTag,BackdropImageTags,ThumbImageTag');
  const data = await jfGet<{ Items?: JellyfinItem[] }>(url, token);
  return Array.isArray((data as any)) ? (data as any) : (data.Items ?? []);
}

export async function getNextUp(
  baseUrl: string,
  token: string,
  userId: string,
  limit = 24
): Promise<JellyfinItem[]> {
  const url = new URL(`${baseUrl}/Shows/NextUp`);
  url.searchParams.set('UserId', userId);
  url.searchParams.set('Limit', String(limit));
  url.searchParams.set('Fields', 'PrimaryImageAspectRatio,SeriesInfo,UserData,RunTimeTicks,SeriesId,PrimaryImageTag,BackdropImageTags,ThumbImageTag');
  const data = await jfGet<{ Items?: JellyfinItem[] }>(url, token);
  return Array.isArray((data as any)) ? (data as any) : (data.Items ?? []);
}

// Fetch user views (libraries)
export async function getUserViews(
  baseUrl: string,
  token: string,
  userId: string
): Promise<Array<{ Id: string; Name: string; CollectionType?: string }>> {
  const url = new URL(`${baseUrl}/Users/${userId}/Views`);
  const data = await jfGet<{ Items?: Array<{ Id: string; Name: string; CollectionType?: string }> }>(url, token);
  return data?.Items ?? [];
}

// Resolve a library (view) ID by CollectionType or by localized names fallback.
export async function resolveLibraryId(
  baseUrl: string,
  token: string,
  userId: string,
  kind: 'movies' | 'series'
): Promise<{ id: string; name: string } | null> {
  const views = await getUserViews(baseUrl, token, userId);
  const ct = kind === 'movies' ? 'movies' : 'tvshows';
  const byCollection = views.find((v) => (v.CollectionType ?? '').toLowerCase() === ct);
  if (byCollection) return { id: byCollection.Id, name: byCollection.Name };

  const normalize = (s: string | undefined) => (s ?? '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
  const hasName = (v: { Name: string }, names: string[]) => names.some((x) => normalize(v.Name) === normalize(x));
  const movieNames = ['films', 'film', 'movies', 'movie'];
  const seriesNames = ['series', 'séries', 'serie', 'série', 'tv shows', 'tv', 'shows'];
  const fallback = views.find((v) => hasName(v, kind === 'movies' ? movieNames : seriesNames));
  return fallback ? { id: fallback.Id, name: fallback.Name } : null;
}

export type SortBy = 'SortName' | 'DateCreated' | 'PremiereDate' | 'CommunityRating';
export type SortOrder = 'Ascending' | 'Descending';

export type PagedResult = { Items: JellyfinItem[]; TotalRecordCount: number };

export async function fetchLibraryItems(
  baseUrl: string,
  token: string,
  userId: string,
  parentId: string,
  includeItemTypes: string,
  opts: { startIndex: number; limit: number; sortBy: SortBy; sortOrder: SortOrder }
): Promise<PagedResult> {
  const url = new URL(`${baseUrl}/Users/${userId}/Items`);
  url.searchParams.set('ParentId', parentId);
  url.searchParams.set('IncludeItemTypes', includeItemTypes);
  url.searchParams.set('Recursive', 'true');
  url.searchParams.set('StartIndex', String(opts.startIndex));
  url.searchParams.set('Limit', String(opts.limit));
  url.searchParams.set('SortBy', opts.sortBy);
  url.searchParams.set('SortOrder', opts.sortOrder);
  url.searchParams.set(
    'Fields',
    [
      'PrimaryImageAspectRatio',
      'UserData',
      'RunTimeTicks',
      'ProductionYear',
      'SeasonCount',
      'ChildCount',
      'RecursiveItemCount',
      'OfficialRating',
      'MediaStreams',
      'Status',
      'SeriesInfo',
      'IndexNumber',
    ].join(',')
  );
  const data = await jfGet<PagedResult>(url, token);
  // Some servers return array directly; normalize
  if (Array.isArray((data as any))) {
    return { Items: data as unknown as JellyfinItem[], TotalRecordCount: (data as any).length ?? 0 };
  }
  return { Items: data.Items ?? [], TotalRecordCount: data.TotalRecordCount ?? (data.Items?.length ?? 0) };
}



// Generic POST helper
async function jfPost<T = any>(url: URL | string, token: string, body: any): Promise<T> {
  const res = await fetch(url.toString(), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Emby-Token': token },
    body: body == null ? undefined : JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`Jellyfin request failed: ${res.status}`);
  return res.json() as Promise<T>;
}

export async function getItemDetails(
  baseUrl: string,
  token: string,
  userId: string,
  itemId: string
): Promise<JellyfinItem> {
  const url = new URL(`${baseUrl}/Users/${userId}/Items/${itemId}`);
  url.searchParams.set(
    'Fields',
    [
      'PrimaryImageAspectRatio',
      'ImageTags',
      'BackdropImageTags',
      'ThumbImageTag',
      'Overview',
      'People',
      'Genres',
      'Studios',
      'OriginalTitle',
      'RunTimeTicks',
      'ProductionYear',
      'CommunityRating',
      'OfficialRating',
      'MediaStreams',
      'Taglines',
      'ExternalUrls',
      'Status',
      'SeriesGenres',
      'SeasonCount',
      'ChildCount',
      'RecursiveItemCount'
    ].join(',')
  );
  return jfGet<JellyfinItem>(url, token);
}

export async function getSeasons(
  baseUrl: string,
  token: string,
  userId: string,
  seriesId: string
): Promise<JellyfinItem[]> {
  const url = new URL(`${baseUrl}/Shows/${seriesId}/Seasons`);
  url.searchParams.set('UserId', userId);
  url.searchParams.set('Fields', 'PrimaryImageAspectRatio,UserData,Overview,IndexNumber');
  const data = await jfGet<{ Items?: JellyfinItem[] }>(url, token);
  return data?.Items ?? [];
}

export async function getEpisodes(
  baseUrl: string,
  token: string,
  userId: string,
  seriesId: string,
  seasonId?: string
): Promise<JellyfinItem[]> {
  const url = new URL(`${baseUrl}/Shows/${seriesId}/Episodes`);
  url.searchParams.set('UserId', userId);
  if (seasonId) url.searchParams.set('SeasonId', seasonId);
  url.searchParams.set('Fields', 'PrimaryImageAspectRatio,UserData,RunTimeTicks,IndexNumber,ParentIndexNumber,PrimaryImageTag,ThumbImageTag,BackdropImageTags,ImageTags');
  const data = await jfGet<{ Items?: JellyfinItem[] }>(url, token);
  return data?.Items ?? [];
}

export async function getSimilarItems(
  baseUrl: string,
  token: string,
  itemId: string,
  limit = 20
): Promise<JellyfinItem[]> {
  const url = new URL(`${baseUrl}/Items/${itemId}/Similar`);
  url.searchParams.set('Limit', String(limit));
  url.searchParams.set('Fields', 'PrimaryImageAspectRatio,UserData,RunTimeTicks,ProductionYear,MediaStreams,SeriesInfo,PrimaryImageTag,BackdropImageTags,ThumbImageTag');
  const data = await jfGet<{ Items?: JellyfinItem[] }>(url, token);
  return data?.Items ?? [];
}

export type PlaybackInfo = {
  MediaSources?: Array<{
    Id?: string;
    Path?: string;
    Size?: number;
    Name?: string;
    Container?: string;
    DirectStreamUrl?: string;
    TranscodingUrl?: string;
    SupportsDirectPlay?: boolean;
    SupportsDirectStream?: boolean;
    SupportsTranscoding?: boolean;
    MediaStreams?: any[];
  }>;
};

export async function getPlaybackInfo(
  baseUrl: string,
  token: string,
  userId: string,
  itemId: string
): Promise<PlaybackInfo> {
  const url = new URL(`${baseUrl}/Items/${itemId}/PlaybackInfo`);
  url.searchParams.set('UserId', userId);
  // Minimal body to let server select a source; device profile could be added later
  return jfPost<PlaybackInfo>(url, token, {});
}
