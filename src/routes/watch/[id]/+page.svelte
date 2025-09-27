<script lang="ts">

  import type { ItemDetail } from "$lib/core/api";
  import { videoStreamUrl } from "$lib/core/api";
  import { itemPosterUrl } from "$lib/core/images";
  import { formatTicksToHMS } from "$lib/core/time";

  let { data } = $props<{ data: { item: ItemDetail | null; startTicks: number } }>();
  const item = data.item;
  const startTicks = data.startTicks ?? 0;
  const src = item ? videoStreamUrl(item.Id, { startTicks }) : "";
  const poster = item ? itemPosterUrl(item, { width: 600, height: 900 }) : "";
</script>



<main class="mx-auto max-w-4xl px-3 sm:px-4 py-4 space-y-4">
  {#if item}
    <section class="space-y-3">
      <div class="relative w-full aspect-video bg-black rounded-md overflow-hidden">
        <video src={src} poster={poster} class="absolute inset-0 w-full h-full" controls autoplay playsinline>
          Votre navigateur ne supporte pas la lecture vidéo.
        </video>
      </div>
      <div class="text-sm opacity-80">
        {#if startTicks > 0}
          Reprise à {formatTicksToHMS(startTicks)}
        {/if}
      </div>
      <h1 class="text-base sm:text-lg font-semibold">{item.Name}</h1>
    </section>
  {:else}
    <p class="opacity-80">Aucun média à lire.</p>
  {/if}
</main>

