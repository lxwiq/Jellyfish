<script lang="ts">
  import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from "$lib/components/ui/carousel/index.js";
  import { itemPosterUrl, userAvatarUrl, placeholderPosterUrl, posterSrcset, posterSizes, itemThumbUrl, thumbSrcset, thumbSizes, placeholderThumbUrl } from "$lib/core/images";
  let { data } = $props<{ data: { movies: any[]; series: any[]; nextUp: any[]; resumeMovies: any[]; resumeEpisodes: any[] } }>();
  const { movies, series, nextUp, resumeMovies, resumeEpisodes } = data;
  import { getUserId } from "$lib/core/storage";
  const uid = getUserId();
  const avatar = uid ? userAvatarUrl(uid, { width: 32, height: 32 }) : "";
  const posterFor = (item: any) => itemPosterUrl(item, { width: 300, height: 450 });
  const rectFor = (item: any) => itemThumbUrl(item, { width: 480, height: 270 });
</script>





<main class="mx-auto max-w-7xl px-4 py-6 space-y-10">

  <!-- Next up episodes -->
  {#if nextUp?.length}
  <section class="space-y-4">
    <h2 class="text-lg sm:text-xl font-semibold">Épisodes suivants</h2>
    <Carousel class="w-full">
      <CarouselContent class="-ml-3 sm:-ml-4">
        {#each nextUp as ep}
          <CarouselItem class="pl-3 sm:pl-4 basis-2/3 sm:basis-1/2 md:basis-1/3 lg:basis-1/4 xl:basis-1/5">
            <a href={`/watch/${ep.Id}${ep?.UserData?.PlaybackPositionTicks ? `?t=${ep.UserData.PlaybackPositionTicks}` : ''}`} class="block">
              <article class="w-full">
                <div class="overflow-hidden rounded-md">
                  <div class="relative w-full aspect-video">
                    <img src={rectFor(ep)} srcset={thumbSrcset(ep, [320,480,640])} sizes={thumbSizes} alt={ep.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, ep.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">
                  {#if ep.ParentIndexNumber && ep.IndexNumber}
                    S{ep.ParentIndexNumber}E{ep.IndexNumber} · {ep.SeriesName || ep.Name}
                  {:else}
                    {ep.Name}
                  {/if}
                </div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>
  {/if}

  <!-- Resume movies -->
  {#if resumeMovies?.length}
  <section class="space-y-4">
    <h2 class="text-lg sm:text-xl font-semibold">Reprendre les films</h2>
    <Carousel class="w-full">
      <CarouselContent class="-ml-3 sm:-ml-4">
        {#each resumeMovies as m}
          <CarouselItem class="pl-3 sm:pl-4 basis-2/3 sm:basis-1/2 md:basis-1/3 lg:basis-1/5 xl:basis-1/6">
            <a href={`/watch/${m.Id}${m?.UserData?.PlaybackPositionTicks ? `?t=${m.UserData.PlaybackPositionTicks}` : ''}`} class="block">
              <article class="w-full">
                <div class="overflow-hidden rounded-md">
                  <div class="relative w-full aspect-video sm:hidden">
                    <img src={rectFor(m)} srcset={thumbSrcset(m, [320,480,640])} sizes={thumbSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, m.Name))} />
                  </div>
                  <div class="relative w-full hidden sm:block sm:aspect-[2/3]">
                    <img src={posterFor(m)} srcset={posterSrcset(m, [200,300,450])} sizes={posterSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, m.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{m.Name}</div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>
  {/if}

  <!-- Resume series (episodes in progress) -->
  {#if resumeEpisodes?.length}
  <section class="space-y-4">
    <h2 class="text-lg sm:text-xl font-semibold">Reprendre les séries</h2>
    <Carousel class="w-full">
      <CarouselContent class="-ml-3 sm:-ml-4">
        {#each resumeEpisodes as ep}
          <CarouselItem class="pl-3 sm:pl-4 basis-2/3 sm:basis-1/2 md:basis-1/3 lg:basis-1/4 xl:basis-1/5">
            <a href={`/watch/${ep.Id}${ep?.UserData?.PlaybackPositionTicks ? `?t=${ep.UserData.PlaybackPositionTicks}` : ''}`} class="block">
              <article class="w-full">
                <div class="overflow-hidden rounded-md">
                  <div class="relative w-full aspect-video">
                    <img src={rectFor(ep)} srcset={thumbSrcset(ep, [320,480,640])} sizes={thumbSizes} alt={ep.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, ep.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">
                  {#if ep.ParentIndexNumber && ep.IndexNumber}
                    S{ep.ParentIndexNumber}E{ep.IndexNumber} · {ep.SeriesName || ep.Name}
                  {:else}
                    {ep.Name}
                  {/if}
                </div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>
  {/if}

  <!-- Movies -->
  <section class="space-y-4">
    <h2 class="text-lg sm:text-xl font-semibold">Derniers films ajoutés</h2>
    <Carousel class="w-full">
      <CarouselContent class="-ml-3 sm:-ml-4">
        {#each movies as m}
          <CarouselItem class="pl-3 sm:pl-4 basis-2/3 sm:basis-1/2 md:basis-1/3 lg:basis-1/5 xl:basis-1/6">
            <a href={`/films/${m.Id}`} class="block">
              <article class="w-full">
                <div class="overflow-hidden rounded-md">
                  <!-- Mobile: rectangular (16:9) -->
                  <div class="relative w-full aspect-video sm:hidden">
                    <img src={rectFor(m)} srcset={thumbSrcset(m, [320,480,640])} sizes={thumbSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, m.Name))} />
                  </div>
                  <!-- >= sm: classic poster (2:3) -->
                  <div class="relative w-full hidden sm:block sm:aspect-[2/3]">
                    <img src={posterFor(m)} srcset={posterSrcset(m, [200,300,450])} sizes={posterSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, m.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{m.Name}</div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>

  <!-- Series -->
  <section class="space-y-4">
    <h2 class="text-lg sm:text-xl font-semibold">Dernières séries ajoutées</h2>
    <Carousel class="w-full">
      <CarouselContent class="-ml-3 sm:-ml-4">
        {#each series as s}
          <CarouselItem class="pl-3 sm:pl-4 basis-2/3 sm:basis-1/2 md:basis-1/3 lg:basis-1/5 xl:basis-1/6">
            <a href={`/series/${s.Id}`} class="block">
              <article class="w-full">
                <div class="overflow-hidden rounded-md">
                  <!-- Mobile: rectangular (16:9) -->
                  <div class="relative w-full aspect-video sm:hidden">
                    <img src={rectFor(s)} srcset={thumbSrcset(s, [320,480,640])} sizes={thumbSizes} alt={s.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, s.Name))} />
                  </div>
                  <!-- >= sm: classic poster (2:3) -->
                  <div class="relative w-full hidden sm:block sm:aspect-[2/3]">
                    <img src={posterFor(s)} srcset={posterSrcset(s, [200,300,450])} sizes={posterSizes} alt={s.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, s.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{s.Name}</div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-[calc(50%-1.5rem)] -translate-y-1/2 sm:top-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>
</main>