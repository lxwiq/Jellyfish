<script lang="ts">
  import TopBar from "$lib/components/TopBar.svelte";

  import { ArrowLeft } from "@lucide/svelte";
  import { itemPosterUrl, placeholderPosterUrl, posterSrcset, posterSizes } from "$lib/core/images";
  let { data } = $props<{ data: { items: any[] } }>();
  const items = data.items ?? [];
  const back = () => history.back();
  const imgFor = (i: any) => itemPosterUrl(i, { width: 300, height: 450 });
</script>

<TopBar />

<main class="mx-auto max-w-7xl px-3 sm:px-4 py-4">
  <section class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3 sm:gap-4">
    {#each items as s}
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
    {/each}
  </section>
</main>

