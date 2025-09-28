<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Badge } from '$lib/components/ui/badge';
  import { AspectRatio } from '$lib/components/ui/aspect-ratio';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from '$lib/components/ui/carousel';

  import { session } from '$lib/state/session.js';
  import { MediaCard } from '$lib/components/system';
  import { posterUrl, backdropUrl, personImageUrl, thumbUrl } from '$lib/utils/jellyfinImages.js';
  import { getItemDetails, type JellyfinItem } from '$lib/services/mediaService.js';
  import { getPersonFilmography } from '$lib/services/peopleService.js';

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let api: any = $state(null);
  let personId = $state('');

  let loading = $state(true);
  let error = $state<string | null>(null);
  let person = $state<JellyfinItem | null>(null);
  let movies = $state<JellyfinItem[]>([]);
  let series = $state<JellyfinItem[]>([]);
  let episodes = $state<JellyfinItem[]>([]);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user || !s.api) { goto('/connect'); return; }
    baseUrl = s.baseUrl; token = s.token; userId = s.user.id; api = s.api;
    personId = get(page).params.id as string;
    void init();
  });

  async function init() {
    loading = true; error = null;
    try {
      // Load person base item (name, overview, etc.)
      person = await getItemDetails(baseUrl, token, userId, personId);
      // Load filmography via Jellyfin SDK
      const res = await getPersonFilmography(api, userId, personId, { limit: 200 });
      const items = res.Items ?? [];
      movies = items.filter((x: any) => x?.Type === 'Movie');
      series = items.filter((x: any) => x?.Type === 'Series');
      episodes = items.filter((x: any) => x?.Type === 'Episode');
    } catch (e) {
      console.error('Failed to load person page', e);
      error = 'Impossible de charger la fiche acteur';
    } finally { loading = false; }
  }

  function minutesFromTicks(t?: number) { if (!t) return null; const m = Math.round(t/10_000_000/60); return m>0?m:null; }
  function formatMinutes(m?: number | null) { if (!m) return null; const h = Math.floor(m/60); const mm = m % 60; return h ? `${h}h ${mm}min` : `${mm}min`; }

  function pickEpImage(it: any): { src: string; step: string } {
    if (it?.ThumbImageTag) return { src: thumbUrl(baseUrl, token, it.Id, 270), step: 'thumb' };
    if (Array.isArray(it?.BackdropImageTags) && it.BackdropImageTags.length > 0)
      return { src: backdropUrl(baseUrl, token, it.Id, 270), step: 'backdrop' };
    return { src: posterUrl(baseUrl, token, it.Id, 600), step: 'poster' };
  }
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-0 sm:px-0 pb-safe">
  {#if loading}
    <div class="space-y-4">
      <Skeleton class="h-48 w-full rounded-none" />
      <div class="px-5 sm:px-8 space-y-3">
        <Skeleton class="h-6 w-2/3" />
        <Skeleton class="h-4 w-1/2" />
      </div>
    </div>
  {:else if error}
    <div class="px-5 sm:px-8 py-6"><p class="text-sm text-destructive">{error}</p></div>
  {:else if person}
    <!-- Backdrop header -->
    <div class="relative w-full h-48 sm:h-56 md:h-64 lg:h-72 xl:h-80">
      <img src={personImageUrl(baseUrl, token, person.Id, 720, person.ImageTags?.Primary)} alt={person.Name} class="absolute inset-0 w-full h-full object-cover" />
      <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-background/90 to-background/0 h-24"></div>
    </div>

    <!-- Main content -->
    <div class="-mt-16 px-5 sm:px-8">
      <div class="mx-auto max-w-6xl rounded-xl border bg-background/80 backdrop-blur shadow-md p-4 sm:p-6">
        <div class="flex items-center gap-4">
          <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-full overflow-hidden bg-secondary border">
            <img src={personImageUrl(baseUrl, token, person.Id, 200, person.ImageTags?.Primary)} alt={person.Name} class="w-full h-full object-cover" />
          </div>
          <div class="min-w-0">
            <h1 class="text-lg sm:text-xl font-semibold line-clamp-2">{person.Name}</h1>
            {#if person.Overview}
              <p class="mt-1 text-sm text-muted-foreground line-clamp-2">{person.Overview}</p>
            {/if}
          </div>
        </div>

    <!-- Movies -->
    <section class="space-y-3 mt-4">
      <h2 class="text-base font-semibold">Films</h2>
      {#if movies.length === 0}
        <p class="text-sm text-muted-foreground">Aucun film</p>
      {:else}
        <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
          <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
            {#each movies as it (it.Id)}
              <CarouselItem class="basis-[60%] xs:basis-1/2 sm:basis-1/3 md:basis-1/4 lg:basis-1/5">
                <a href={`/movie/${it.Id}`} aria-label={it.Name} class="block">
                  <MediaCard item={it} {baseUrl} {token} kind="movie" variant="grid" />
                </a>
              </CarouselItem>
            {/each}
          </CarouselContent>
          <CarouselPrevious />
          <CarouselNext />
        </Carousel>
      {/if}
    </section>

    <!-- Series -->
    <section class="space-y-3">
      <h2 class="text-base font-semibold">Séries</h2>
      {#if series.length === 0}
        <p class="text-sm text-muted-foreground">Aucune série</p>
      {:else}
        <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
          <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
            {#each series as it (it.Id)}
              <CarouselItem class="basis-[60%] xs:basis-1/2 sm:basis-1/3 md:basis-1/4 lg:basis-1/5">
                <a href={`/series/${it.Id}`} aria-label={it.Name} class="block">
                  <MediaCard item={it} {baseUrl} {token} kind="series" variant="grid" />
                </a>
              </CarouselItem>
            {/each}
          </CarouselContent>
          <CarouselPrevious />
          <CarouselNext />
        </Carousel>
      {/if}
    </section>

    <!-- Episodes -->
    <section class="space-y-3">
      <h2 class="text-base font-semibold">Épisodes</h2>
      {#if episodes.length === 0}
        <p class="text-sm text-muted-foreground">Aucun épisode</p>
      {:else}
        <div class="space-y-3">
          {#each episodes as e (e.Id)}
            <a href={`/episode/${e.Id}`} class="flex gap-3" aria-label={e.Name}>
              <div class="w-32 shrink-0">
                <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
                  <img src={pickEpImage(e).src} alt={e.Name} class="w-full h-full object-cover" />
                </AspectRatio>
              </div>
              <div class="min-w-0 flex-1">
                <p class="text-xs text-muted-foreground">{e.SeriesName}</p>
                <p class="font-medium line-clamp-1">{e.Name}</p>
                {#if e.Overview}<p class="mt-1 text-sm text-muted-foreground line-clamp-2">{e.Overview}</p>{/if}
                <div class="mt-2 flex items-center gap-2">
                  {#if minutesFromTicks(e.RunTimeTicks)}<Badge variant="outline">{formatMinutes(minutesFromTicks(e.RunTimeTicks))}</Badge>{/if}
                </div>
              </div>
            </a>
          {/each}
        </div>
      {/if}
    </section>
    </div>
    </div>
{/if}
</SafeArea>

