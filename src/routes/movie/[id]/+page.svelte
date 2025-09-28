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

  import { posterUrl, backdropUrl, logoUrl, personImageUrl } from '$lib/utils/jellyfinImages.js';

  import { getItemDetails, getSimilarItems, type JellyfinItem } from '$lib/services/mediaService.js';

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let itemId = $state('');

  let loading = $state(true);
  let error = $state<string | null>(null);
  let item = $state<JellyfinItem | null>(null);
  let similar = $state<JellyfinItem[]>([]);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) {
      goto('/connect');
      return;
    }
    baseUrl = s.baseUrl; token = s.token; userId = s.user.id;
    itemId = get(page).params.id as string;
    void init();
  });

  async function init() {
    loading = true; error = null;
    try {
      item = await getItemDetails(baseUrl, token, userId, itemId);
      similar = await getSimilarItems(baseUrl, token, itemId, 12);
    } catch (e) {
      console.error('Failed to load movie', e);
      error = 'Failed to load movie';
    } finally {
      loading = false;
    }
  }
  function formatMinutes(m?: number | null) {
    if (!m) return null; const h = Math.floor(m/60); const mm = m % 60; return h ? `${h}h ${mm}min` : `${mm}min`;
  }
  function formatDurationFromTicks(t?: number) {
    const m = minutesFromTicks(t); return formatMinutes(m) ?? null;
  }


  function minutesFromTicks(t?: number) {
    if (!t) return null; const m = Math.round(t / 10_000_000 / 60); return m > 0 ? m : null;
  }
  function resolutionLabel(streams?: any[]) {
    if (!Array.isArray(streams)) return null;
    const h = streams.filter((s) => s?.Type === 'Video').reduce((m, s) => Math.max(m, s?.Height||0), 0);
    if (!h) return null; if (h>=2160) return '4K'; if (h>=1440) return '1440p'; if (h>=1080) return '1080p'; if (h>=720) return '720p'; return `${h}p`;
  }
  function audioLabels(streams?: any[]) {
    if (!Array.isArray(streams)) return [] as string[];
    return streams.filter((s)=> s?.Type==='Audio').map((s)=> [s?.Language ?? s?.DisplayLanguage, s?.Codec?.toUpperCase()].filter(Boolean).join(' · '));
  }
  function subtitleLabels(streams?: any[]) {
    if (!Array.isArray(streams)) return [] as string[];
    return streams.filter((s)=> s?.Type==='Subtitle').map((s)=> s?.Language ?? s?.DisplayLanguage).filter(Boolean);
  }
  function title(i: any) { return i?.Name ?? ''; }
  function year(i: any) { return i?.ProductionYear ?? null; }
  function rating(i: any) { return i?.CommunityRating ?? null; }
  function official(i: any) { return i?.OfficialRating ?? null; }
  function fileSize(i: any): string | null {
    const ms = (i?.MediaSources ?? []); const size = ms.find(Boolean)?.Size ?? null; if (!size) return null;
    const mb = size / (1024*1024); return mb > 1024 ? `${(mb/1024).toFixed(1)} GB` : `${Math.round(mb)} MB`;
  }

  function playOrResume() { goto(`/play/${itemId}`); }
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
  {:else if item}
    <!-- Backdrop header -->
    <div class="relative w-full h-48 sm:h-56 md:h-64 lg:h-72 xl:h-80">
      <img src={backdropUrl(baseUrl, token, item.Id, 720, item.BackdropImageTags?.[0])} alt={title(item)} class="absolute inset-0 w-full h-full object-cover" />
      <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-background/90 to-background/0 h-24"></div>
    </div>

    <!-- Main content -->
    <div class="-mt-16 px-5 sm:px-8">
      <div class="mx-auto max-w-6xl rounded-xl border bg-background/80 backdrop-blur shadow-md p-4 sm:p-6">

      <div class="flex gap-4">
        <div class="w-28 sm:w-36 shrink-0">
          <AspectRatio ratio={2/3} class="rounded-md overflow-hidden bg-secondary border">
            <img src={posterUrl(baseUrl, token, item.Id, 540, item.ImageTags?.Primary)} alt={title(item)} class="w-full h-full object-cover" />
          </AspectRatio>
        </div>
        <div class="min-w-0 flex-1">
          <!-- Logo or title -->
          <div class="min-h-[40px] sm:min-h-[48px]">
            <img src={logoUrl(baseUrl, token, item.Id, 120, item.ImageTags?.Logo)} alt={title(item)} class="max-h-12 sm:max-h-16 object-contain" />
          </div>
          <h1 class="sr-only">{title(item)}</h1>
          <div class="mt-2 flex flex-wrap gap-2">
            {#if year(item)}<Badge variant="secondary">{year(item)}</Badge>{/if}
            {#if formatDurationFromTicks(item.RunTimeTicks)}<Badge variant="outline">{formatDurationFromTicks(item.RunTimeTicks)}</Badge>{/if}
            {#if rating(item)}<Badge variant="outline">★ {rating(item).toFixed(1)}</Badge>{/if}
            {#if official(item)}<Badge variant="outline">{official(item)}</Badge>{/if}
            {#if resolutionLabel(item.MediaStreams)}<Badge variant="outline">{resolutionLabel(item.MediaStreams)}</Badge>{/if}
            {#if fileSize(item)}<Badge variant="outline">{fileSize(item)}</Badge>{/if}
          </div>
          <div class="mt-3 flex items-center gap-2">
            <Button size="sm" onclick={playOrResume} aria-label="Play or resume movie" class="inline-flex items-center gap-2"><PlayIcon class="h-4 w-4" /> Lire</Button>
          </div>
        </div>
      </div>

      <!-- Plot -->
      {#if item.Overview}
        <div class="mt-4 text-sm text-muted-foreground">{item.Overview}</div>
      {/if}

      <!-- Genres & Studio -->
      <div class="mt-4 flex flex-wrap gap-2">
        {#each (item.Genres ?? []) as g}<Badge variant="outline">{g}</Badge>{/each}
        {#if Array.isArray(item.Studios) && item.Studios.length>0}
          <Badge variant="outline">{item.Studios[0]?.Name}</Badge>
        {/if}
      </div>

      <!-- Cast & Crew -->
      {#if Array.isArray(item.People) && item.People.length > 0}
        <div class="mt-5">
          <h2 class="text-base font-semibold">Distribution</h2>
          <Carousel class="relative mt-2" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
            <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
              {#each item.People.slice(0, 14) as p}
                <CarouselItem class="basis-[45%] xs:basis-[35%] sm:basis-[28%] md:basis-[22%] lg:basis-[18%]">
                  <a href={`/person/${p.Id}`} aria-label={p.Name} class="flex flex-col items-center text-center">
                    <div class="w-16 h-16 sm:w-20 sm:h-20 rounded-full overflow-hidden bg-secondary border">
                      <img src={personImageUrl(baseUrl, token, p.Id, 200, p.PrimaryImageTag)} alt={p.Name} class="w-full h-full object-cover" />
                    </div>
                    <p class="mt-2 text-sm font-medium line-clamp-1 w-full">{p.Name}</p>
                    {#if p.Role}
                      <p class="text-xs text-muted-foreground line-clamp-1 w-full">{p.Role}</p>
                    {:else if p.Type}
                      <p class="text-xs text-muted-foreground line-clamp-1 w-full">{p.Type}</p>
                    {/if}
                  </a>
                </CarouselItem>
              {/each}
            </CarouselContent>
            <CarouselPrevious />
            <CarouselNext />
          </Carousel>
        </div>
      {/if}

      <!-- Technical metadata -->
      <div class="mt-5">
        <h2 class="text-base font-semibold">Technique</h2>
        <div class="mt-2 flex flex-wrap gap-2 text-xs">
          {#if resolutionLabel(item.MediaStreams)}<Badge variant="outline">Vidéo: {resolutionLabel(item.MediaStreams)}</Badge>{/if}
          {#each audioLabels(item.MediaStreams) as a}
            <Badge variant="outline">Audio: {a}</Badge>
          {/each}
          {#each subtitleLabels(item.MediaStreams) as s}
            <Badge variant="outline">Sous-titres: {s}</Badge>
          {/each}
        </div>
      </div>

      <!-- Recommendations -->
      <div class="mt-6">
        <h2 class="text-base font-semibold">Vous aimerez aussi</h2>
        {#if similar.length === 0}
          <p class="text-sm text-muted-foreground mt-2">Aucune recommandation</p>
        {:else}
          <Carousel class="relative" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
            <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
              {#each similar as it (it.Id)}
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
      </div>
      </div>
    </div>
  {/if}
</SafeArea>

