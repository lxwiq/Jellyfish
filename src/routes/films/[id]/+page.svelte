<script lang="ts">

  import { ArrowLeft, Star } from "@lucide/svelte";
  import type { ItemDetail } from "$lib/core/api";
  import { itemPosterUrl, placeholderPosterUrl, posterSrcset, posterSizes, backdropImageUrl } from "$lib/core/images";
  import { formatTicksToHMS, formatTicksToMinutes } from "$lib/core/time";
  let { data } = $props<{ data: { item: ItemDetail | null } }>();
  const item = data.item;
  const back = () => history.back();
  const poster = item ? itemPosterUrl(item, { width: 600, height: 900 }) : "";
  const posterSet = item ? posterSrcset(item, [200,300,450]) : "";
  const heroBg = item ? (
    (item as any).BackdropImageTags?.[0]
      ? backdropImageUrl(item.Id, (item as any).BackdropImageTags[0], { width: 1600, height: 900, quality: 85 })
      : backdropImageUrl(item.Id, undefined, { width: 1600, height: 900, quality: 85 })
  ) : "";
</script>

{#if !item}
  <main class="mx-auto max-w-4xl px-3 sm:px-4 py-6">
    <button class="inline-flex items-center gap-2 px-2 py-1 rounded-md hover:bg-muted" onclick={back}>
      <ArrowLeft size={18} /><span class="text-sm">Retour</span>
    </button>
    <p class="mt-6 text-sm opacity-80">Contenu introuvable.</p>
  </main>
{:else}


  <main class="mx-auto max-w-4xl px-3 sm:px-4 py-4 space-y-6">
    <!-- Full-page blurred backdrop background -->
    <section class="relative">
      <div class="fixed inset-0 z-0 pointer-events-none">
        <img src={heroBg || poster} srcset={heroBg ? undefined : posterSet} sizes={posterSizes} alt=""
             class="w-full h-full object-cover blur-2xl scale-110 opacity-80" loading="eager" decoding="async" fetchpriority="high"
             onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(1600, 900, item.Name))} />
        <div class="absolute inset-0 bg-background/70"></div>
      </div>
      <div class="relative z-10 px-3 sm:px-4 pt-4 sm:pt-6 text-white">
        <h1 class="text-xl sm:text-3xl font-semibold">{item.Name}</h1>
        <div class="mt-1 text-xs sm:text-sm opacity-90">
          {#if item.ProductionYear}{item.ProductionYear}{/if}
          {#if item.RunTimeTicks}&nbsp;•&nbsp;{Math.round(item.RunTimeTicks/600000000)} min{/if}
          {#if item.Genres?.length}&nbsp;•&nbsp;{item.Genres.slice(0,3).join(', ')}{/if}
        </div>
      </div>
    </section>

    <!-- Compact extra info / actions -->
    <section class="flex flex-col gap-3 text-white">
      <div class="flex flex-wrap items-center gap-2 text-xs sm:text-sm opacity-90">
        {#if item.OfficialRating}
          <span class="px-2 py-0.5 rounded bg-white/10 border border-white/20">{item.OfficialRating}</span>
        {/if}
        {#if item.CommunityRating}
          <span class="inline-flex items-center gap-1"><Star size={14} class="text-yellow-500" /> {item.CommunityRating.toFixed(1)}</span>
        {/if}
        {#if (item as any).Studios?.length}
          <span class="opacity-80">{(item as any).Studios[0]?.Name}</span>
        {/if}
      </div>
      <div class="flex items-center gap-2">
        {#if item.UserData && item.UserData.PlaybackPositionTicks && item.RunTimeTicks && item.UserData.PlaybackPositionTicks < item.RunTimeTicks}
          <a class="px-3 py-2 rounded-md bg-primary text-primary-foreground text-sm inline-flex items-center" href={`/watch/${item.Id}?t=${item.UserData.PlaybackPositionTicks}`}>
            Reprendre ({formatTicksToHMS(item.UserData.PlaybackPositionTicks)})
          </a>
        {:else}
          <a class="px-3 py-2 rounded-md bg-primary text-primary-foreground text-sm inline-flex items-center" href={`/watch/${item.Id}`}>Lire</a>
        {/if}
        <button class="px-3 py-2 rounded-md border text-sm text-white border-white/40 hover:bg-white/10">Ajouter</button>
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

