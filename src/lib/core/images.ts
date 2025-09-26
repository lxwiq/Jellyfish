import { getAccessToken, getBaseUrl } from './storage';

export function primaryImageUrl(itemId: string, tag?: string, opts?: { width?: number; height?: number; quality?: number }) {
  const base = getBaseUrl();
  if (!base) return '';
  const width = opts?.width ?? 300;
  const height = opts?.height ?? 450;
  const quality = opts?.quality ?? 90;
  const token = getAccessToken();
  const url = new URL(`${base}/Items/${itemId}/Images/Primary`);
  url.searchParams.set('maxWidth', String(width));
  url.searchParams.set('maxHeight', String(height));
  url.searchParams.set('quality', String(quality));
  if (tag) url.searchParams.set('tag', tag);
  if (token) url.searchParams.set('api_key', token);
  return url.toString();
}


export function userAvatarUrl(userId: string, opts?: { width?: number; height?: number; quality?: number; format?: 'webp' | 'jpg' }) {
  const base = getBaseUrl();
  if (!base) return '';
  const width = opts?.width ?? 48;
  const height = opts?.height ?? 48;
  const quality = opts?.quality ?? 90;
  const format = opts?.format ?? 'webp';
  const token = getAccessToken();
  const url = new URL(`${base}/Users/${userId}/Images/Primary`);
  url.searchParams.set('fillWidth', String(width));
  url.searchParams.set('fillHeight', String(height));
  url.searchParams.set('quality', String(quality));
  url.searchParams.set('format', format);
  if (token) url.searchParams.set('api_key', token);
  return url.toString();
}

export function placeholderPosterUrl(width = 300, height = 450, text?: string) {
  const t = text ? encodeURIComponent(text) : `${width}x${height}`;
  // Placehold.co supports formats and colors via query params if needed
  return `https://placehold.co/${width}x${height}?text=${t}`;
}

export type BasicItem = { Id: string; Name: string; PrimaryImageTag?: string };
export function itemPosterUrl(item: BasicItem, opts?: { width?: number; height?: number; quality?: number }) {
  const tag = (item as any).PrimaryImageTag ?? (item as any).ImageTags?.Primary;
  if (tag) {
    return primaryImageUrl(item.Id, tag, opts);
  }
  return placeholderPosterUrl(opts?.width ?? 300, opts?.height ?? 450, item?.Name || '');
}


export function posterSrcset(item: BasicItem, widths: number[] = [200, 300, 450], opts?: { quality?: number }) {
  return widths
    .map((w) => {
      const h = Math.round((w * 3) / 2);
      return `${itemPosterUrl(item, { width: w, height: h, quality: opts?.quality })} ${w}w`;
    })
    .join(', ');
}

export const posterSizes = '(min-width: 1280px) 200px, (min-width: 640px) 25vw, 66vw';
