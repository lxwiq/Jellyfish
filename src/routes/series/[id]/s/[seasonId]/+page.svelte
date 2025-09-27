<script lang="ts">
  import { ArrowLeft } from "@lucide/svelte";
  import { itemThumbUrl, placeholderThumbUrl } from "$lib/core/images";
  import { formatTicksToHMS } from "$lib/core/time";
  let { data } = $props<{ data: { season: any | null; episodes: any[] } }>();
  const season = data.season;
  const episodes = data.episodes ?? [];
  const back = () => history.back();
</script>

{#if !season}
  <main class="mx-auto max-w-4xl px-3 sm:px-4 py-6">
    <button class="inline-flex items-center gap-2 px-2 py-1 rounded-md hover:bg-muted" onclick={back}>
      <ArrowLeft size={18} /><span class="text-sm">Retour</span>
    </button>
    <p class="mt-6 text-sm opacity-80">Saison introuvable.</p>
  </main>
{:else}
  <main class="mx-auto max-w-5xl px-3 sm:px-4 py-4 space-y-6">
    <section class="flex items-end justify-between gap-3">
      <div>
        <h2 class="text-lg sm:text-2xl font-semibold">{season.SeriesName ?? season.Name}</h2>
        <div class="text-sm opacity-80 mt-1">{season.Name}</div>
      </div>
      <button class="hidden sm:inline-flex items-center gap-2 px-2 py-1 rounded-md hover:bg-muted" onclick={back}>
        <ArrowLeft size={18} /><span class="text-sm">Retour</span>
      </button>
    </section>

    <section>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
        {#each episodes as ep}
          <a href={`/watch/${ep.Id}${ep?.UserData?.PlaybackPositionTicks ? `?t=${ep.UserData.PlaybackPositionTicks}` : ''}`} class="block group">
            <article class="w-full">
              <div class="overflow-hidden rounded-md">
                <div class="relative w-full aspect-video bg-muted">
                  <img
                    src={itemThumbUrl(ep, { width: 480, height: 270 })}
                    alt={ep.Name}
                    class="absolute inset-0 w-full h-full object-cover group-hover:scale-[1.02] transition-transform"
                    loading="lazy" decoding="async" fetchpriority="low"
                    onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderThumbUrl(480, 270, ep.Name))}
                  />
                </div>
              </div>
              <div class="mt-2 text-xs sm:text-sm font-medium">
                {#if ep.ParentIndexNumber != null}S{ep.ParentIndexNumber}{/if}
                {#if ep.IndexNumber != null}E{ep.IndexNumber} {/if}{ep.Name}
              </div>
              {#if ep.UserData?.PlaybackPositionTicks}
                <div class="mt-1 text-[11px] opacity-70">Reprendre {formatTicksToHMS(ep.UserData.PlaybackPositionTicks)}</div>
              {/if}
            </article>
          </a>
        {/each}
      </div>
    </section>
  </main>
{/if}

