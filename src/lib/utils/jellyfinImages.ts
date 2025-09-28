export function posterUrl(baseUrl: string, token: string, itemId: string, height = 450) {
  const url = `${baseUrl}/Items/${itemId}/Images/Primary?fillHeight=${height}&quality=90&tag=`;
  return `${url}&api_key=${encodeURIComponent(token)}`;
}

export function backdropUrl(baseUrl: string, token: string, itemId: string, height = 270) {
  const url = `${baseUrl}/Items/${itemId}/Images/Backdrop?fillHeight=${height}&quality=85&tag=`;
  return `${url}&api_key=${encodeURIComponent(token)}`;
}
export function thumbUrl(baseUrl: string, token: string, itemId: string, height = 270) {
  const url = `${baseUrl}/Items/${itemId}/Images/Thumb?fillHeight=${height}&quality=85&tag=`;
  return `${url}&api_key=${encodeURIComponent(token)}`;
}

export function logoUrl(baseUrl: string, token: string, itemId: string, height = 100) {
  const url = `${baseUrl}/Items/${itemId}/Images/Logo?fillHeight=${height}&quality=90&tag=`;
  return `${url}&api_key=${encodeURIComponent(token)}`;
}
export function personImageUrl(baseUrl: string, token: string, personId: string, height = 160) {
  const url = `${baseUrl}/Persons/${personId}/Images/Primary?fillHeight=${height}&quality=85&tag=`;
  return `${url}&api_key=${encodeURIComponent(token)}`;
}




// Jellyfin Trickplay: try a tile thumbnail (index 0) at given width. Falls back via <img onerror> in UI.
export function trickplayThumbUrl(baseUrl: string, token: string, itemId: string, width = 320, index = 0) {
  // Some servers use .jpg, some may support .webp; start with jpg.
  return `${baseUrl}/Videos/${itemId}/Trickplay/${width}/${index}.jpg?api_key=${encodeURIComponent(token)}`;
}

