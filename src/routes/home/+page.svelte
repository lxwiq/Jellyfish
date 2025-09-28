<script lang="ts">
  import { session } from '$lib/state/session.js';
  import { get } from 'svelte/store';
  import { goto } from '$app/navigation';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { AspectRatio } from '$lib/components/ui/aspect-ratio';
  import {
    Carousel,
    CarouselContent,
    CarouselItem,
    CarouselNext,
    CarouselPrevious,
  } from '$lib/components/ui/carousel';

  import { getContinueWatching, getNextUp } from '$lib/services/mediaService.js';
  import { backdropUrl, posterUrl, thumbUrl } from '$lib/utils/jellyfinImages.js';

  type LibraryKey = 'anime' | 'films' | 'series';

  let name = $state<string>('');
  let baseUrl = $state<string>('');
  let token = $state<string>('');
  let userId = $state<string>('');

  let loading = $state(true);
  let libraries = $state<Record<LibraryKey, { id: string; name: string } | null>>({
    anime: null,
    films: null,
    series: null,
  });

  let items: Record<LibraryKey, any[]> = $state({
    anime: [],
    films: [],
    series: [],
  });

  let continueWatching = $state<any[]>([]);
  let nextEpisodes = $state<any[]>([]);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.api || !s.baseUrl || !s.token || !s.user) {
      goto('/connect');
      return;
    }
    name = s.user.name;
    baseUrl = s.baseUrl;
    token = s.token;
    userId = s.user.id;
    // Kick off loading once session is confirmed
    void loadData();
  });

  type Step = 'thumb' | 'backdrop' | 'seriesThumb' | 'seriesBackdrop' | 'poster';

  function pickInitialLandscape(it: any): { src: string; step: Step } {
    if (it?.ThumbImageTag) return { src: thumbUrl(baseUrl, token, it.Id, 270), step: 'thumb' };
    if (Array.isArray(it?.BackdropImageTags) && it.BackdropImageTags.length > 0)
      return { src: backdropUrl(baseUrl, token, it.Id, 270), step: 'backdrop' };
    if (it?.SeriesId) return { src: thumbUrl(baseUrl, token, it.SeriesId, 270), step: 'seriesThumb' };
    return { src: posterUrl(baseUrl, token, it.Id, 600), step: 'poster' };
  }

  function setFallbackImage(e: Event, it: any) {
    const img = e.currentTarget as HTMLImageElement;
    const step = (img.dataset.step as Step) || 'thumb';
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
    // last step: poster failed too, keep as-is or hide
  }

  function imageUrl(itemId: string, type: 'Primary' | 'Backdrop' = 'Primary', height = 450) {
    // Use api_key query param so <img> can load without custom headers
    const url = `${baseUrl}/Items/${itemId}/Images/${type}?fillHeight=${height}&quality=90&tag=`;
    return `${url}&api_key=${encodeURIComponent(token)}`;
  }

  async function loadData() {
    loading = true;
    try {
      // 1) Fetch all views (libraries)
      const res = await fetch(`${baseUrl}/Users/${userId}/Views`, {
        headers: { 'X-Emby-Token': token },
      });
      const data = await res.json();
      const views: Array<{ Id: string; Name: string }> = data?.Items ?? [];

      // Map known libraries by name (case-insensitive)
      // Accent- and case-insensitive name matching with common synonyms (FR/EN)
      const normalize = (s: string | undefined) =>
        (s ?? '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
      const hasName = (v: { Name: string }, names: string[]) => {
        const n = normalize(v.Name);
        return names.some((x) => n === normalize(x));
      };
      const animeNames = ['anime', 'animé', 'animes', 'animés'];
      const filmsNames = ['films', 'film', 'movies', 'movie'];
      const seriesNames = ['series', 'séries', 'serie', 'série', 'tv shows', 'tv', 'shows'];

      const anime = views.find((v) => hasName(v, animeNames));
      const films = views.find((v) => hasName(v, filmsNames));
      const series = views.find((v) => hasName(v, seriesNames));

      libraries = {
        anime: anime ? { id: anime.Id, name: anime.Name } : null,
        films: films ? { id: films.Id, name: films.Name } : null,
        series: series ? { id: series.Id, name: series.Name } : null,
      } as typeof libraries;

      // 2) For each found library, fetch recently added items
      const fetchRecent = async (parentId: string, includeTypes: string) => {
        const url = new URL(`${baseUrl}/Users/${userId}/Items/Latest`);
        url.searchParams.set('ParentId', parentId);
        url.searchParams.set('Limit', '24');
        url.searchParams.set('IncludeItemTypes', includeTypes);
        const r = await fetch(url, { headers: { 'X-Emby-Token': token } });
        const j = await r.json();
        return Array.isArray(j) ? j : (j?.Items ?? []);
      };

      const [animeItems, filmsItems, seriesItems, cwItems, nextItems] = await Promise.all([
        libraries.anime?.id ? fetchRecent(libraries.anime.id, 'Movie,Series') : Promise.resolve([]),
        libraries.films?.id ? fetchRecent(libraries.films.id, 'Movie') : Promise.resolve([]),
        libraries.series?.id ? fetchRecent(libraries.series.id, 'Series') : Promise.resolve([]),
        getContinueWatching(baseUrl, token, userId, 24),
        getNextUp(baseUrl, token, userId, 24),
      ]);

      items = {
        anime: animeItems,
        films: filmsItems,
        series: seriesItems,
      };

      continueWatching = cwItems;
      // Dedupe: remove episodes from NextUp that are already in Continue Watching
      const cwEpisodeKeys = new Set(
        cwItems
          .filter((x: any) => x?.Type === 'Episode')
          .map((x: any) => (x?.SeriesId && x?.IndexNumber != null)
            ? `${x.SeriesId}:${x.SeasonId ?? ''}:${x.IndexNumber}`
            : x.Id)
      );
      nextEpisodes = nextItems.filter((ep: any) => {
        const key = (ep?.Type === 'Episode' && ep?.SeriesId && ep?.IndexNumber != null)
          ? `${ep.SeriesId}:${ep.SeasonId ?? ''}:${ep.IndexNumber}`
          : ep.Id;
        return !cwEpisodeKeys.has(key);
      });
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('Failed to load libraries/items', e);
    } finally {
      loading = false;
    }
  }
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 space-y-6">
  <!-- Continue Watching Section -->
  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-lg sm:text-xl font-semibold">Continuer la lecture</h2>
    </div>
    {#if loading}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each Array.from({ length: 6 }) as _, i}
            <CarouselItem class="basis-[70%] sm:basis-1/2 md:basis-1/3 lg:basis-1/4">
              <div>
                <AspectRatio ratio={16/9} class="rounded-md overflow-hidden">
                  <Skeleton class="w-full h-full" />
                </AspectRatio>
                <Skeleton class="mt-2 h-4 w-40" />
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else if continueWatching.length > 0}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each continueWatching as it (it.Id)}
            <CarouselItem class="basis-[70%] sm:basis-1/2 md:basis-1/3 lg:basis-1/4">
              <div>
                <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
                  <img
                    src={pickInitialLandscape(it).src}
                    data-step={pickInitialLandscape(it).step}
                    alt={it.Name}
                    loading="lazy"
                    class="w-full h-full object-cover"
                    onerror={(e) => setFallbackImage(e, it)}
                  />
                </AspectRatio>
                <p class="mt-2 line-clamp-2 text-sm">{it.SeriesName ? `${it.SeriesName} — ${it.Name}` : it.Name}</p>
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else}
      <div class="pl-4 pr-4 sm:pl-6 sm:pr-6 text-sm text-muted-foreground">Rien à reprendre pour le moment</div>
    {/if}
  </section>

  <!-- Next Episodes Section -->
  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-lg sm:text-xl font-semibold">Prochains épisodes</h2>
    </div>
    {#if loading}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each Array.from({ length: 6 }) as _, i}
            <CarouselItem class="basis-[70%] sm:basis-1/2 md:basis-1/3 lg:basis-1/4">
              <div>
                <AspectRatio ratio={16/9} class="rounded-md overflow-hidden">
                  <Skeleton class="w-full h-full" />
                </AspectRatio>
                <Skeleton class="mt-2 h-4 w-40" />
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else if nextEpisodes.length > 0}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each nextEpisodes as it (it.Id)}
            <CarouselItem class="basis-[70%] sm:basis-1/2 md:basis-1/3 lg:basis-1/4">
              <div>
                <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary">
                  <img
                    src={pickInitialLandscape(it).src}
                    data-step={pickInitialLandscape(it).step}
                    alt={it.Name}
                    loading="lazy"
                    class="w-full h-full object-cover"
                    onerror={(e) => setFallbackImage(e, it)}
                  />
                </AspectRatio>
                <p class="mt-2 line-clamp-2 text-sm">{it.SeriesName ? `${it.SeriesName} — ${it.Name}` : it.Name}</p>
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else}
      <div class="pl-4 pr-4 sm:pl-6 sm:pr-6 text-sm text-muted-foreground">Aucun épisode à venir</div>
    {/if}
  </section>

  <!-- Anime Section -->
  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-lg sm:text-xl font-semibold">Récemment ajoutés — {libraries.anime?.name ?? 'Anime'}</h2>
    </div>
    {#if loading}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each Array.from({ length: 8 }) as _, i}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden">
                  <Skeleton class="w-full h-full" />
                </AspectRatio>
                <Skeleton class="mt-2 h-4 w-24" />
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each items.anime as it (it.Id)}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary">
                  <img
                    src={imageUrl(it.Id, 'Primary', 450)}
                    alt={it.Name}
                    loading="lazy"
                    class="w-full h-full object-cover"
                  />
                </AspectRatio>
                <p class="mt-2 line-clamp-2 text-sm">{it.Name}</p>
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {/if}
  </section>

  <!-- Films Section -->
  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-lg sm:text-xl font-semibold">Récemment ajoutés — {libraries.films?.name ?? 'Films'}</h2>
    </div>
    {#if loading}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each Array.from({ length: 8 }) as _, i}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden">
                  <Skeleton class="w-full h-full" />
                </AspectRatio>
                <Skeleton class="mt-2 h-4 w-24" />
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each items.films as it (it.Id)}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary">
                  <img
                    src={imageUrl(it.Id, 'Primary', 450)}
                    alt={it.Name}
                    loading="lazy"
                    class="w-full h-full object-cover"
                  />
                </AspectRatio>
                <p class="mt-2 line-clamp-2 text-sm">{it.Name}</p>
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {/if}
  </section>

  <!-- Series Section -->
  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-lg sm:text-xl font-semibold">Récemment ajoutés — {libraries.series?.name ?? 'Séries'}</h2>
    </div>
    {#if loading}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each Array.from({ length: 8 }) as _, i}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden">
                  <Skeleton class="w-full h-full" />
                </AspectRatio>
                <Skeleton class="mt-2 h-4 w-24" />
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {:else}
      <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
        <CarouselContent class="pl-4 pr-4 sm:pl-6 sm:pr-6">
          {#each items.series as it (it.Id)}
            <CarouselItem class="basis-[40%] sm:basis-1/3 md:basis-1/5 lg:basis-1/6 xl:basis-1/8">
              <div>
                <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary">
                  <img
                    src={imageUrl(it.Id, 'Primary', 450)}
                    alt={it.Name}
                    loading="lazy"
                    class="w-full h-full object-cover"
                  />
                </AspectRatio>
                <p class="mt-2 line-clamp-2 text-sm">{it.Name}</p>
              </div>
            </CarouselItem>
          {/each}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
    {/if}
  </section>
</SafeArea>

