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

