export function posterUrl(baseUrl: string, token: string, itemId: string, height = 450, tag?: string) {
  const qp = new URLSearchParams({ fillHeight: String(height), quality: '90' });
  if (tag) qp.set('tag', tag);
  qp.set('api_key', token);
  return `${baseUrl}/Items/${itemId}/Images/Primary?${qp.toString()}`;
}

export function backdropUrl(baseUrl: string, token: string, itemId: string, height = 270, tag?: string) {
  const qp = new URLSearchParams({ fillHeight: String(height), quality: '85' });
  if (tag) qp.set('tag', tag);
  qp.set('api_key', token);
  return `${baseUrl}/Items/${itemId}/Images/Backdrop?${qp.toString()}`;
}
export function thumbUrl(baseUrl: string, token: string, itemId: string, height = 270, tag?: string) {
  const qp = new URLSearchParams({ fillHeight: String(height), quality: '85' });
  if (tag) qp.set('tag', tag);
  qp.set('api_key', token);
  return `${baseUrl}/Items/${itemId}/Images/Thumb?${qp.toString()}`;
}

export function logoUrl(baseUrl: string, token: string, itemId: string, height = 100, tag?: string) {
  const qp = new URLSearchParams({ fillHeight: String(height), quality: '90' });
  if (tag) qp.set('tag', tag);
  qp.set('api_key', token);
  return `${baseUrl}/Items/${itemId}/Images/Logo?${qp.toString()}`;
}
export function personImageUrl(baseUrl: string, token: string, personId: string, height = 160, tag?: string) {
  const qp = new URLSearchParams({ fillHeight: String(height), quality: '85' });
  if (tag) qp.set('tag', tag);
  qp.set('api_key', token);
  return `${baseUrl}/Items/${personId}/Images/Primary?${qp.toString()}`;
}




// Jellyfin Trickplay: try a tile thumbnail (index 0) at given width. Falls back via <img onerror> in UI.
export function trickplayThumbUrl(baseUrl: string, token: string, itemId: string, width = 320, index = 0) {
  // Some servers use .jpg, some may support .webp; start with jpg.
  return `${baseUrl}/Videos/${itemId}/Trickplay/${width}/${index}.jpg?api_key=${encodeURIComponent(token)}`;
}

