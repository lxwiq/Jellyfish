<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Button } from '$lib/components/ui/button';
  import { Badge } from '$lib/components/ui/badge';
  import { AspectRatio } from '$lib/components/ui/aspect-ratio';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from '$lib/components/ui/carousel';
  import PlayIcon from '@lucide/svelte/icons/play';

  import { session } from '$lib/state/session.js';
  import { posterUrl, backdropUrl, thumbUrl, personImageUrl } from '$lib/utils/jellyfinImages.js';
  import { getItemDetails, type JellyfinItem } from '$lib/services/mediaService.js';

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let episodeId = $state('');

  let loading = $state(true);
  let error = $state<string | null>(null);
  let ep = $state<JellyfinItem | null>(null);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) { goto('/connect'); return; }
    baseUrl = s.baseUrl; token = s.token; userId = s.user.id;
    episodeId = get(page).params.id as string;
    void init();
  });

  async function init() {
    loading = true; error = null;
    try {
      ep = await getItemDetails(baseUrl, token, userId, episodeId);
    } catch (e) {
      console.error('Failed to load episode', e);
      error = 'Impossible de charger l\'épisode';
    } finally {
      loading = false;
    }
  }

  function minutesFromTicks(t?: number) { if (!t) return null; const m = Math.round(t/10_000_000/60); return m>0?m:null; }
  function formatMinutes(m?: number | null) { if (!m) return null; const h = Math.floor(m/60); const mm = m % 60; return h ? `${h}h ${mm}min` : `${mm}min`; }
  function formatDurationFromTicks(t?: number) { const m = minutesFromTicks(t); return formatMinutes(m) ?? null; }

  function episodeMetaLabel(e: any) {
    const s = e?.ParentIndexNumber; const n = e?.IndexNumber;
    if (s != null && n != null) return `Saison ${s} · Épisode ${n}`;
    if (n != null) return `Épisode ${n}`;
    return '';
  }
  function pickEpisodeImage(e: any): { src: string; step: string } {
    const primaryTag = e?.PrimaryImageTag ?? e?.ImageTags?.Primary;
    if (e?.ThumbImageTag) return { src: thumbUrl(baseUrl, token, e.Id, 720, e.ThumbImageTag), step: 'thumb' };
    if (primaryTag) return { src: posterUrl(baseUrl, token, e.Id, 720, primaryTag), step: 'primary' };
    if (Array.isArray(e?.BackdropImageTags) && e.BackdropImageTags.length > 0)
      return { src: backdropUrl(baseUrl, token, e.Id, 720, e.BackdropImageTags[0]), step: 'backdrop' };
    return { src: thumbUrl(baseUrl, token, e.Id, 720), step: 'thumbNT' };
  }
  function onEpisodeImgError(ev: Event, e: any, size: number) {
    const img = ev.currentTarget as HTMLImageElement;
    const step = (img.dataset.step as string) || 'thumb';
    const primaryTag = e?.PrimaryImageTag ?? e?.ImageTags?.Primary;
    if (step === 'thumb') { img.dataset.step = 'primary'; img.src = primaryTag ? posterUrl(baseUrl, token, e.Id, size, primaryTag) : posterUrl(baseUrl, token, e.Id, size); return; }
    if (step === 'primary') { img.dataset.step = 'backdrop'; img.src = backdropUrl(baseUrl, token, e.Id, size, e.BackdropImageTags?.[0]); return; }
    if (step === 'backdrop') { img.dataset.step = 'thumbNT'; img.src = thumbUrl(baseUrl, token, e.Id, size); return; }
    // give up; hide broken image
    img.style.display = 'none';
  }

  function playEpisode() { goto(`/play/${episodeId}`); }
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
  {:else if ep}
    <!-- Backdrop header -->
    <div class="relative w-full h-48 sm:h-56 md:h-64 lg:h-72 xl:h-80">
      <img src={pickEpisodeImage(ep).src} data-step={pickEpisodeImage(ep).step} alt={ep.Name} class="absolute inset-0 w-full h-full object-cover" onerror={(ev)=>onEpisodeImgError(ev, ep, 720)} />
      <div class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-background/90 to-background/0 h-24"></div>
    </div>

    <!-- Main content -->
    <div class="-mt-16 px-5 sm:px-8">
      <div class="mx-auto max-w-6xl rounded-xl border bg-background/80 backdrop-blur shadow-md p-4 sm:p-6">
        <div class="flex gap-4">
          <div class="w-28 sm:w-36 shrink-0">
            <AspectRatio ratio={16/9} class="rounded-md overflow-hidden bg-secondary border">
              <img src={pickEpisodeImage(ep).src} data-step={pickEpisodeImage(ep).step} alt={ep.Name} class="w-full h-full object-cover" onerror={(ev)=>onEpisodeImgError(ev, ep, 540)} />
            </AspectRatio>
          </div>
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2 text-xs text-muted-foreground">
              {#if ep.SeriesName}
                <a class="hover:underline" href={`/series/${ep.SeriesId}`}>{ep.SeriesName}</a>
              {/if}
              {#if episodeMetaLabel(ep)}<span>·</span><span>{episodeMetaLabel(ep)}</span>{/if}
              {#if formatDurationFromTicks(ep.RunTimeTicks)}<span>·</span><span>{formatDurationFromTicks(ep.RunTimeTicks)}</span>{/if}
            </div>
            <h1 class="text-lg sm:text-xl font-semibold line-clamp-2">{ep.Name}</h1>
            {#if ep.Overview}
              <p class="mt-2 text-sm text-muted-foreground line-clamp-3">{ep.Overview}</p>
            {/if}

            <div class="mt-3 flex items-center gap-2">
              <Button size="sm" onclick={playEpisode} aria-label="Lire">
                <PlayIcon class="h-4 w-4 mr-1" />
                Lire
              </Button>
              {#if ep.PremiereDate}
                <Badge variant="outline">{new Date(ep.PremiereDate).getFullYear?.() ?? ''}</Badge>
              {/if}
            </div>
          </div>
        </div>

        <!-- Cast -->
        {#if Array.isArray(ep.People) && ep.People.length > 0}
          <div class="mt-6">
            <h2 class="text-base font-semibold">Distribution</h2>
            <Carousel class="relative mt-2" opts={{ align: 'start', containScroll: 'trimSnaps', slidesToScroll: 'auto', skipSnaps: true }}>
              <CarouselContent class="pl-2 pr-2 sm:pl-4 sm:pr-4">
                {#each ep.People.slice(0, 14) as p}
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
      </div>
    </div>
  {/if}
</SafeArea>

