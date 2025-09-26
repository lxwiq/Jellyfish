<script lang="ts">
  import TopBar from "$lib/components/TopBar.svelte";

  import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious } from "$lib/components/ui/carousel/index.js";

  import { itemPosterUrl, userAvatarUrl, placeholderPosterUrl, posterSrcset, posterSizes } from "$lib/core/images";
  let { data } = $props<{ data: { movies: any[]; series: any[] } }>();
  const { movies, series } = data;
  import { getUserId } from "$lib/core/storage";
  const uid = getUserId();
  const avatar = uid ? userAvatarUrl(uid, { width: 32, height: 32 }) : "";
  function imgFor(item: { Id: string; PrimaryImageTag?: string; Name: string }) {
    return itemPosterUrl(item, { width: 300, height: 450 });
  }
</script>

<TopBar />



<main class="mx-auto max-w-7xl px-4 py-6 space-y-10">
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
                  <div class="relative w-full aspect-[2/3]">
                    <img src={imgFor(m)} srcset={posterSrcset(m, [200,300,450])} sizes={posterSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, m.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{m.Name}</div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-1/2 -translate-y-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-1/2 -translate-y-1/2 size-9 sm:size-8" />
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
                  <div class="relative w-full aspect-[2/3]">
                    <img src={imgFor(s)} srcset={posterSrcset(s, [200,300,450])} sizes={posterSizes} alt={s.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, s.Name))} />
                  </div>
                </div>
                <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{s.Name}</div>
              </article>
            </a>
          </CarouselItem>
        {/each}
      </CarouselContent>
      <CarouselPrevious class="-left-3 sm:-left-6 top-1/2 -translate-y-1/2 size-9 sm:size-8" />
      <CarouselNext class="-right-3 sm:-right-6 top-1/2 -translate-y-1/2 size-9 sm:size-8" />
    </Carousel>
  </section>
</main>