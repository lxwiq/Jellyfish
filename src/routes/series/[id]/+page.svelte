<script lang="ts">
  import TopBar from "$lib/components/TopBar.svelte";
  import { ArrowLeft, Star } from "@lucide/svelte";
  import type { ItemDetail } from "$lib/core/api";
  import { itemPosterUrl, placeholderPosterUrl, posterSrcset, posterSizes } from "$lib/core/images";
  import { formatTicksToHMS } from "$lib/core/time";
  let { data } = $props<{ data: { item: ItemDetail | null; nextUp?: any | null } }>();
  const item = data.item;
  const nextUp = data.nextUp ?? null;
  const back = () => history.back();
  const poster = item ? itemPosterUrl(item, { width: 600, height: 900 }) : "";
  const posterSet = item ? posterSrcset(item, [200,300,450]) : "";
</script>

{#if !item}
  <main class="mx-auto max-w-4xl px-3 sm:px-4 py-6">
    <button class="inline-flex items-center gap-2 px-2 py-1 rounded-md hover:bg-muted" onclick={back}>
      <ArrowLeft size={18} /><span class="text-sm">Retour</span>
    </button>
    <p class="mt-6 text-sm opacity-80">Contenu introuvable.</p>
  </main>
{:else}
  <TopBar showBack={true} title="Séries" />

  <main class="mx-auto max-w-4xl px-3 sm:px-4 py-4 space-y-6">
    <!-- Hero poster -->
    <section>
      <div class="relative w-full aspect-[2/3] sm:aspect-video overflow-hidden rounded-md">
        <img src={poster} srcset={posterSet} sizes={posterSizes} alt={item.Name}
             class="absolute inset-0 w-full h-full object-cover" loading="eager" decoding="async" fetchpriority="high"
             onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(600, 900, item.Name))} />
        <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-black/0"></div>
        <div class="absolute bottom-0 left-0 right-0 p-3 sm:p-4 text-white">
          <h2 class="text-lg sm:text-2xl font-semibold">{item.Name}</h2>
          <div class="mt-1 text-xs sm:text-sm opacity-90">
            {#if item.ProductionYear}{item.ProductionYear}{/if}
            {#if item.Genres?.length}&nbsp;•&nbsp;{item.Genres.slice(0,3).join(', ')}{/if}
          </div>
        </div>
      </div>
    </section>

    <!-- Compact extra info / actions -->
    <section class="flex flex-col gap-3">
      <div class="flex flex-wrap items-center gap-2 text-xs sm:text-sm opacity-90">
        {#if item.OfficialRating}
          <span class="px-2 py-0.5 rounded bg-muted border">{item.OfficialRating}</span>
        {/if}
        {#if item.CommunityRating}
          <span class="inline-flex items-center gap-1"><Star size={14} class="text-yellow-500" /> {item.CommunityRating.toFixed(1)}</span>
        {/if}
        {#if (item as any).Studios?.length}
          <span class="opacity-80">{(item as any).Studios[0]?.Name}</span>
        {/if}
      </div>
      <div class="flex items-center gap-2">
        {#if nextUp}
          {#if nextUp.UserData && nextUp.UserData.PlaybackPositionTicks && nextUp.RunTimeTicks && nextUp.UserData.PlaybackPositionTicks < nextUp.RunTimeTicks}
            <a class="px-3 py-2 rounded-md bg-primary text-primary-foreground text-sm inline-flex items-center" href={`/watch/${nextUp.Id}?t=${nextUp.UserData.PlaybackPositionTicks}`}>
              Reprendre S{nextUp.ParentIndexNumber}E{nextUp.IndexNumber} ({formatTicksToHMS(nextUp.UserData.PlaybackPositionTicks)})
            </a>
          {:else}
            <a class="px-3 py-2 rounded-md bg-primary text-primary-foreground text-sm inline-flex items-center" href={`/watch/${nextUp.Id}`}>
              Lire S{nextUp.ParentIndexNumber}E{nextUp.IndexNumber}
            </a>
          {/if}
        {:else}
          <button class="px-3 py-2 rounded-md bg-primary text-primary-foreground text-sm">Lire</button>
        {/if}
        <button class="px-3 py-2 rounded-md border text-sm">Ajouter</button>
      </div>
    </section>

    <!-- Overview -->
    {#if item.Overview}
      <section>
        <h3 class="text-base font-semibold mb-2">Résumé</h3>
        <p class="text-sm leading-relaxed opacity-90">{item.Overview}</p>
      </section>
    {/if}
  </main>
{/if}

