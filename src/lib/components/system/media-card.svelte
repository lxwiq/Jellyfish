<script lang="ts">
  import { AspectRatio } from '$lib/components/ui/aspect-ratio';
  import { Badge } from '$lib/components/ui/badge';
  import { cn } from '$lib/utils';
  import { posterUrl, backdropUrl, thumbUrl } from '$lib/utils/jellyfinImages';
  import CheckIcon from '@lucide/svelte/icons/check';
  import PlayIcon from '@lucide/svelte/icons/play';
  import ClockIcon from '@lucide/svelte/icons/clock';

  export type MediaCardVariant = 'grid' | 'rect' | 'list';
  export type MediaKind = 'movie' | 'series';

  let {
    item,
    baseUrl,
    token,
    kind = 'movie' as MediaKind,
    variant = 'grid' as MediaCardVariant,
    class: className,
  }: {
    item: any;
    baseUrl: string;
    token: string;
    kind?: MediaKind;
    variant?: MediaCardVariant;
    class?: string;
  } = $props();

  function pickLandscape(it: any): { src: string; step: string } {
    if (it?.ThumbImageTag) return { src: thumbUrl(baseUrl, token, it.Id, 270), step: 'thumb' };
    if (Array.isArray(it?.BackdropImageTags) && it.BackdropImageTags.length > 0)
      return { src: backdropUrl(baseUrl, token, it.Id, 270), step: 'backdrop' };
    if (it?.SeriesId) return { src: thumbUrl(baseUrl, token, it.SeriesId, 270), step: 'seriesThumb' };
    return { src: posterUrl(baseUrl, token, it.Id, 600), step: 'poster' };
  }
  function setFallbackImage(e: Event, it: any) {
    const img = e.currentTarget as HTMLImageElement;
    const step = (img.dataset.step as string) || 'thumb';
    if (step === 'thumb') {
      img.dataset.step = 'backdrop';
      img.src = backdropUrl(baseUrl, token, it.Id, 270);
      return;
    }
    if (step === 'backdrop') {
      if (it?.SeriesId) {
        img.dataset.step = 'seriesThumb';
        img.src = thumbUrl(baseUrl, token, it.SeriesId, 270);
      } else {
        img.dataset.step = 'poster';
        img.src = posterUrl(baseUrl, token, it.Id, 600);
      }
      return;
    }
    if (step === 'seriesThumb') {
      img.dataset.step = 'seriesBackdrop';
      img.src = backdropUrl(baseUrl, token, it.SeriesId, 270);
      return;
    }
    if (step === 'seriesBackdrop') {
      img.dataset.step = 'poster';
      img.src = posterUrl(baseUrl, token, it.Id, 600);
      return;
    }
  }

  function minutesFromTicks(ticks?: number) {
    if (!ticks) return null;
    const minutes = Math.round(ticks / 10_000_000 / 60);
    return minutes > 0 ? minutes : null;
  }
  function remainingMinutes(it: any) {
    const pos = it?.UserData?.PlaybackPositionTicks ?? 0;
    const dur = it?.RunTimeTicks ?? 0;
    if (!dur || pos <= 0 || pos >= dur) return null;
    const mins = Math.max(0, Math.round((dur - pos) / 10_000_000 / 60));
    return mins > 0 ? mins : null;
  }
  function isPlayed(it: any) {
    const u = it?.UserData ?? {};
    return !!u?.Played || (u?.PlayCount ?? 0) > 0;
  }
  function isInProgress(it: any) {
    if (isPlayed(it)) return false;
    const pos = it?.UserData?.PlaybackPositionTicks ?? 0;
    const dur = it?.RunTimeTicks ?? 0;
    return !!dur && pos > 0 && pos < dur;
  }
  function unplayedCount(it: any) {
    const u = it?.UserData ?? {};
    return typeof u?.UnplayedItemCount === 'number' ? u.UnplayedItemCount : null;
  }
  function resolutionLabel(streams?: any[]) {
    if (!Array.isArray(streams)) return null;
    const vid = streams.filter((s) => s?.Type === 'Video');
    const h = vid.reduce((m, s) => Math.max(m, s?.Height || 0), 0);
    if (!h) return null;
    if (h >= 2160) return '4K';
    if (h >= 1440) return '1440p';
    if (h >= 1080) return '1080p';
    if (h >= 720) return '720p';
    return `${h}p`;
  }
  function seasonsCount(it: any) {
    return it?.SeasonCount ?? it?.ChildCount ?? null;
  }
  function episodesCount(it: any) {
    return it?.RecursiveItemCount ?? null;
  }
  function yearOf(it: any) {
    return it?.ProductionYear ?? null;
  }
  function titleOf(it: any) {
    return it?.Name ?? '';
  }
</script>

<!-- GRID / POSTER -->
{#if variant === 'grid'}
  <div class={cn('w-full', className)}>
    <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary">
      <div class="relative w-full h-full">
        <img
          src={posterUrl(baseUrl, token, item.Id, 600)}
          alt={titleOf(item)}
          loading="lazy"
          class="absolute inset-0 w-full h-full object-cover"
        />
        <!-- Status badges overlay -->
        <div class="absolute top-1 left-1 flex gap-1">
          {#if isInProgress(item) && remainingMinutes(item)}
            <Badge variant="info" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <PlayIcon class="h-3 w-3" />
              <span class="text-[11px] leading-none">{remainingMinutes(item)} min</span>
            </Badge>
          {/if}
        </div>
        <div class="absolute top-1 right-1 flex gap-1">
          {#if isPlayed(item)}
            <Badge variant="success" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <CheckIcon class="h-3 w-3" />
            </Badge>
          {/if}
          {#if kind === 'series' && unplayedCount(item) != null && unplayedCount(item) > 0}
            <Badge variant="warning" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <ClockIcon class="h-3 w-3" />
              <span class="text-[11px] leading-none">{unplayedCount(item)}</span>
            </Badge>
          {/if}
        </div>
      </div>
    </AspectRatio>
    <div class="mt-2 space-y-1">
      <p class="text-sm line-clamp-2">{titleOf(item)}</p>
      <div class="flex flex-wrap gap-1.5">
        {#if kind === 'movie'}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if minutesFromTicks(item?.RunTimeTicks)}<Badge variant="outline">{minutesFromTicks(item.RunTimeTicks)} min</Badge>{/if}
          {#if resolutionLabel(item?.MediaStreams)}<Badge variant="outline">{resolutionLabel(item.MediaStreams)}</Badge>{/if}
        {:else}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if seasonsCount(item)}<Badge variant="outline">{seasonsCount(item)} saisons</Badge>{/if}
          {#if episodesCount(item)}<Badge variant="outline">{episodesCount(item)} épisodes</Badge>{/if}
          {#if item?.Status}<Badge variant="outline">{item.Status}</Badge>{/if}
        {/if}
      </div>
    </div>
  </div>
{:else if variant === 'rect'}
  <!-- RECTANGLE / LANDSCAPE -->
  <div class={cn('w-full', className)}>
    <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
      <div class="relative w-full h-full">
        <img
          src={pickLandscape(item).src}
          data-step={pickLandscape(item).step}
          alt={titleOf(item)}
          loading="lazy"
          class="absolute inset-0 w-full h-full object-cover"
          onerror={(e) => setFallbackImage(e, item)}
        />
        <!-- Status badges overlay -->
        <div class="absolute top-1 left-1 flex gap-1">
          {#if isInProgress(item) && remainingMinutes(item)}
            <Badge variant="info" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <PlayIcon class="h-3 w-3" />
              <span class="text-[11px] leading-none">{remainingMinutes(item)} min</span>
            </Badge>
          {/if}
        </div>
        <div class="absolute top-1 right-1 flex gap-1">
          {#if isPlayed(item)}
            <Badge variant="success" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <CheckIcon class="h-3 w-3" />
            </Badge>
          {/if}
          {#if kind === 'series' && unplayedCount(item) != null && unplayedCount(item) > 0}
            <Badge variant="warning" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm">
              <ClockIcon class="h-3 w-3" />
              <span class="text-[11px] leading-none">{unplayedCount(item)}</span>
            </Badge>
          {/if}
        </div>
      </div>
    </AspectRatio>
    <div class="mt-2 space-y-1">
      <p class="text-sm line-clamp-2">{titleOf(item)}</p>
      <div class="flex flex-wrap gap-1.5">
        {#if kind === 'movie'}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if minutesFromTicks(item?.RunTimeTicks)}<Badge variant="outline">{minutesFromTicks(item.RunTimeTicks)} min</Badge>{/if}
          {#if resolutionLabel(item?.MediaStreams)}<Badge variant="outline">{resolutionLabel(item.MediaStreams)}</Badge>{/if}
        {:else}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if seasonsCount(item)}<Badge variant="outline">{seasonsCount(item)} saisons</Badge>{/if}
          {#if episodesCount(item)}<Badge variant="outline">{episodesCount(item)} épisodes</Badge>{/if}
          {#if item?.Status}<Badge variant="outline">{item.Status}</Badge>{/if}
        {/if}
      </div>
    </div>
  </div>
{:else}
  <!-- LIST / COMPACT HORIZONTAL -->
  <div class={cn('w-full flex gap-3', className)}>
    <div class="w-40 shrink-0">
      <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
        <div class="relative w-full h-full">
          <img
            src={pickLandscape(item).src}
            data-step={pickLandscape(item).step}
            alt={titleOf(item)}
            loading="lazy"
            class="absolute inset-0 w-full h-full object-cover"
            onerror={(e) => setFallbackImage(e, item)}
          />
          <!-- Status badges overlay -->
          <div class="absolute top-1 left-1 flex gap-1">
            {#if isInProgress(item) && remainingMinutes(item)}
              <Badge variant="secondary" class="h-5 px-1.5 py-0.5 flex items-center gap-1">
                <PlayIcon class="h-3 w-3" />
                <span class="text-[11px] leading-none">{remainingMinutes(item)} min</span>
              </Badge>
            {/if}
          </div>
          <div class="absolute top-1 right-1 flex gap-1">
            {#if isPlayed(item)}
              <Badge variant="secondary" class="h-5 px-1.5 py-0.5 flex items-center gap-1">
                <CheckIcon class="h-3 w-3" />
              </Badge>
            {/if}
            {#if kind === 'series' && unplayedCount(item) != null && unplayedCount(item) > 0}
              <Badge variant="outline" class="h-5 px-1.5 py-0.5 flex items-center gap-1">
                <ClockIcon class="h-3 w-3" />
                <span class="text-[11px] leading-none">{unplayedCount(item)}</span>
              </Badge>
            {/if}
          </div>
        </div>
      </AspectRatio>
    </div>
    <div class="min-w-0 space-y-1">
      <div class="flex items-center gap-1">
        <p class="text-sm font-medium line-clamp-2 flex-1 min-w-0">{titleOf(item)}</p>
        {#if isPlayed(item)}
          <Badge variant="success" class="h-5 px-1.5 py-0.5 shadow-sm"><CheckIcon class="h-3 w-3" /></Badge>
        {/if}
        {#if isInProgress(item) && remainingMinutes(item)}
          <Badge variant="info" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm"><PlayIcon class="h-3 w-3" /><span class="text-[11px]">{remainingMinutes(item)}m</span></Badge>
        {/if}
        {#if kind === 'series' && unplayedCount(item) != null && unplayedCount(item) > 0}
          <Badge variant="warning" class="h-5 px-1.5 py-0.5 flex items-center gap-1 shadow-sm"><ClockIcon class="h-3 w-3" /><span class="text-[11px]">{unplayedCount(item)}</span></Badge>
        {/if}
      </div>
      <div class="flex flex-wrap gap-1.5">
        {#if kind === 'movie'}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if minutesFromTicks(item?.RunTimeTicks)}<Badge variant="outline">{minutesFromTicks(item.RunTimeTicks)} min</Badge>{/if}
          {#if resolutionLabel(item?.MediaStreams)}<Badge variant="outline">{resolutionLabel(item.MediaStreams)}</Badge>{/if}
        {:else}
          {#if yearOf(item)}<Badge variant="secondary">{yearOf(item)}</Badge>{/if}
          {#if seasonsCount(item)}<Badge variant="outline">{seasonsCount(item)} saisons</Badge>{/if}
          {#if episodesCount(item)}<Badge variant="outline">{episodesCount(item)} épisodes</Badge>{/if}
          {#if item?.Status}<Badge variant="outline">{item.Status}</Badge>{/if}
        {/if}
      </div>
    </div>
  </div>
{/if}

