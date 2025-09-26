export function formatTicksToHMS(ticks?: number): string {
  if (!ticks || ticks <= 0) return '0:00';
  // Jellyfin ticks: 10,000,000 per second
  const totalSeconds = Math.floor(ticks / 10_000_000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  const mm = String(minutes).padStart(2, '0');
  const ss = String(seconds).padStart(2, '0');
  return hours > 0 ? `${hours}:${mm}:${ss}` : `${minutes}:${ss}`;
}

export function formatTicksToMinutes(ticks?: number): number {
  if (!ticks || ticks <= 0) return 0;
  return Math.round(ticks / 600_000_000);
}

