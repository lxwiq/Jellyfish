<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Button } from '$lib/components/ui/button';
  import { Badge } from '$lib/components/ui/badge';
  import { AspectRatio } from '$lib/components/ui/aspect-ratio';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from '$lib/components/ui/carousel';
  import PlayIcon from '@lucide/svelte/icons/play';

  import { session } from '$lib/state/session.js';
  import { MediaCard } from '$lib/components/system';
  import { posterUrl, backdropUrl, logoUrl, thumbUrl, personImageUrl } from '$lib/utils/jellyfinImages.js';
  import { getItemDetails, getSeasons, getEpisodes, getSimilarItems, type JellyfinItem } from '$lib/services/mediaService.js';

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let seriesId = $state('');

  let loading = $state(true);
  let error = $state<string | null>(null);
  let series = $state<JellyfinItem | null>(null);
  let seasons = $state<JellyfinItem[]>([]);
  let selectedSeasonId = $state<string | null>(null);
  let episodes = $state<JellyfinItem[]>([]);
  let similar = $state<JellyfinItem[]>([]);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) { goto('/connect'); return; }
    baseUrl = s.baseUrl; token = s.token; userId = s.user.id;
    seriesId = get(page).params.id as string;
    void init();
  });

  async function init() {
    loading = true; error = null;
    try {
      series = await getItemDetails(baseUrl, token, userId, seriesId);
      seasons = await getSeasons(baseUrl, token, userId, seriesId);
      selectedSeasonId = seasons[0]?.Id ?? null;
      episodes = selectedSeasonId ? await getEpisodes(baseUrl, token, userId, seriesId, selectedSeasonId) : [];
      similar = await getSimilarItems(baseUrl, token, seriesId, 12);
    } catch (e) {
      console.error('Failed to load series', e); error = 'Failed to load series';
    } finally { loading = false; }
  }

  async function onSelectSeason(id: string) {
    selectedSeasonId = id;
    episodes = await getEpisodes(baseUrl, token, userId, seriesId, selectedSeasonId ?? undefined);
  }

  function title(i: any) { return i?.Name ?? ''; }
  function year(i: any) { return i?.ProductionYear ?? null; }
  function status(i: any) { return i?.Status ?? null; }
  function episodesCount(i: any) { return i?.RecursiveItemCount ?? null; }
  function formatMinutes(m?: number | null) { if (!m) return null; const h = Math.floor(m/60); const mm = m % 60; return h ? `${h}h ${mm}min` : `${mm}min`; }
  function formatDurationFromTicks(t?: number) { const m = minutesFromTicks(t); return formatMinutes(m) ?? null; }

  function seasonsCount(i: any) { const n = i?.SeasonCount ?? i?.ChildCount; if (typeof n === 'number') return n; return seasons.length ? seasons.length : null; }
  function minutesFromTicks(t?: number) { if (!t) return null; const m = Math.round(t/10_000_000/60); return m>0?m:null; }
  function epDisplay(e: any) { const s = e?.ParentIndexNumber; const n = e?.IndexNumber; return s!=null && n!=null ? `S${String(s).padStart(2,'0')}E${String(n).padStart(2,'0')}` : (n!=null? `E${n}` : ''); }
  function isPlayed(e: any) { const u = e?.UserData ?? {}; return !!u?.Played || (u?.PlayCount ?? 0) > 0; }

  function playEpisode(id: string) { goto(`/play/${id}`); }
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-0 sm:px-0 pb-safe">
  {#if loading}
    <div class="space-y-4">
      <Skeleton class="h-48 w-full rounded-none" />
      <div class="px-5 sm:px-8 space-y-3">
        <Skeleton class="h-6 w-2/3" />
        <Skeleton class="h-4 w-1/2" />
        <Skeleton class="h-4 w-full" />
      </div>
    </div>
  {:else if error}
    <div class="px-5 sm:px-8 py-6"><p class="text-sm text-destructive">{error}</p></div>
  {:else if series}
    <!-- Backdrop header -->
    <div class="relative w-full h-48 sm:h-56 md:h-64 lg:h-72 xl:h-80">
      <img src={backdropUrl(baseUrl, token, series.Id, 720)} alt={title(series)} class="absolute inset-0 w-full h-full object-cover" />
      <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-background/90 to-background/0 h-24"></div>
    </div>

    <div class="-mt-16 px-5 sm:px-8">
      <div class="mx-auto max-w-6xl rounded-xl border bg-background/80 backdrop-blur shadow-md p-4 sm:p-6">

      <div class="flex gap-4">
        <div class="w-28 sm:w-36 shrink-0">
          <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary border">
            <img src={posterUrl(baseUrl, token, series.Id, 540)} alt={title(series)} class="w-full h-full object-cover" />
          </AspectRatio>
        </div>
        <div class="min-w-0 flex-1">
          <!-- Logo or title -->
          <div class="min-h-[40px] sm:min-h-[48px]">
            <img src={logoUrl(baseUrl, token, series.Id, 120)} alt={title(series)} class="max-h-12 sm:max-h-16 object-contain" />
          </div>
          <h1 class="sr-only">{title(series)}</h1>
          {#if series.OriginalTitle && series.OriginalTitle !== series.Name}
            <p class="text-sm text-muted-foreground">{series.OriginalTitle}</p>
          {/if}

          <div class="mt-2 flex flex-wrap gap-2">
            {#if year(series)}<Badge variant="secondary">{year(series)}</Badge>{/if}
            {#if seasonsCount(series)}<Badge variant="outline">{seasonsCount(series)} saisons</Badge>{/if}
            {#if episodesCount(series)}<Badge variant="outline">{episodesCount(series)} épisodes</Badge>{/if}
            {#if status(series)}<Badge variant="outline">{status(series)}</Badge>{/if}
          </div>
        </div>
      </div>

      {#if series.Overview}
        <div class="mt-4 text-sm text-muted-foreground">{series.Overview}</div>
      {/if}

      <!-- Genres & Studio -->
      <div class="mt-4 flex flex-wrap gap-2">
        {#each (series.Genres ?? []) as g}<Badge variant="outline">{g}</Badge>{/each}
        {#if Array.isArray(series.Studios) && series.Studios.length>0}
          <Badge variant="outline">{series.Studios[0]?.Name}</Badge>
        {/if}
      </div>

      <!-- Cast -->
      {#if Array.isArray(series.People) && series.People.length > 0}
        <div class="mt-5">
          <h2 class="text-base font-semibold">Distribution</h2>
          <Carousel class="relative mt-2" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
            <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
              {#each series.People.slice(0, 14) as p}
                <CarouselItem class="basis-[45%] xs:basis-[35%] sm:basis-[28%] md:basis-[22%] lg:basis-[18%]">
                  <div class="flex flex-col items-center text-center">
                    <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-full overflow-hidden bg-secondary border">
                      <img src={personImageUrl(baseUrl, token, p.Id, 200)} alt={p.Name} class="w-full h-full object-cover" />
                    </div>
                    <p class="mt-2 text-sm font-medium line-clamp-1 w-full">{p.Name}</p>
                    {#if p.Role}
                      <p class="text-xs text-muted-foreground line-clamp-1 w-full">{p.Role}</p>
                    {:else if p.Type}
                      <p class="text-xs text-muted-foreground line-clamp-1 w-full">{p.Type}</p>
                    {/if}
                  </div>
                </CarouselItem>
              {/each}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
        </div>
      {/if}


      <!-- Seasons selector -->
      {#if seasons.length > 0}
        <div class="mt-6">
          <div class="flex items-center justify-between">
            <h2 class="text-base font-semibold">Saisons</h2>
          </div>
          <div class="mt-2 flex gap-2 overflow-x-auto pb-1">
            {#each seasons as s}
              <Button size="sm" variant={s.Id === selectedSeasonId ? 'default' : 'outline'} onclick={() => onSelectSeason(s.Id)} aria-pressed={s.Id===selectedSeasonId}>{s.Name ?? `Saison ${s.IndexNumber ?? ''}`}</Button>
            {/each}
          </div>
        </div>
      {/if}

      <!-- Episodes list -->
      <div class="mt-4">
        <h2 class="text-base font-semibold">Episodes</h2>
        {#if episodes.length === 0}
          <p class="mt-2 text-sm text-muted-foreground">Aucun épisode</p>
        {:else}
          <div class="mt-2 space-y-3">
            {#each episodes as e (e.Id)}
              <div class="flex gap-3">
                <div class="w-32 shrink-0">
                  <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
                    <img src={e.ThumbImageTag ? thumbUrl(baseUrl, token, e.Id, 270) : backdropUrl(baseUrl, token, e.Id, 270)} alt={e.Name} class="w-full h-full object-cover" />
                  </AspectRatio>
                </div>
                <div class="min-w-0 flex-1">
                  <div class="flex items-center gap-2">
                    <p class="font-medium line-clamp-1">{epDisplay(e)} {e.Name}</p>
                    {#if isPlayed(e)}<Badge variant="success">Vu</Badge>{/if}
                  </div>
                  {#if e.Overview}<p class="mt-1 text-sm text-muted-foreground line-clamp-2">{e.Overview}</p>{/if}
                  <div class="mt-2 flex items-center gap-2">
                    {#if formatDurationFromTicks(e.RunTimeTicks)}<Badge variant="outline">{formatDurationFromTicks(e.RunTimeTicks)}</Badge>{/if}
                    <Button size="sm" onclick={() => playEpisode(e.Id)} aria-label={`Lire ${e.Name}`} class="inline-flex items-center gap-2"><PlayIcon class="h-4 w-4" /> Lire</Button>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </div>

      <!-- Recommendations -->
      <div class="mt-6">
        <h2 class="text-base font-semibold">Séries similaires</h2>
        {#if similar.length === 0}
          <p class="text-sm text-muted-foreground mt-2">Aucune recommandation</p>
        {:else}
          <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
            <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
              {#each similar as it (it.Id)}
                <CarouselItem class="basis-[60%] xs:basis-1/2 sm:basis-1/3 md:basis-1/4 lg:basis-1/5">
                  <MediaCard item={it} {baseUrl} {token} kind="series" variant="grid" />
                </CarouselItem>
              {/each}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
        {/if}
      </div>

      </div>
    </div>
  {/if}
</SafeArea>

