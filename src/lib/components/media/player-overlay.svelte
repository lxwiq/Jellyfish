<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import XIcon from '@lucide/svelte/icons/x';
  import { player, closePlayer, nextCandidate } from '$lib/state/player';

  let videoEl: HTMLVideoElement | null = null;

  function onKey(e: KeyboardEvent) {
    if (e.key === 'Escape') closePlayer();
  }

  onMount(() => {
    window.addEventListener('keydown', onKey);
  });
  onDestroy(() => {
    window.removeEventListener('keydown', onKey);
  });
</script>

{#if $player.isOpen}
  <div class="fixed inset-0 z-[60] bg-black/90">
    <!-- Close button -->
    <button class="absolute top-[calc(env(safe-area-inset-top)+8px)] right-[calc(env(safe-area-inset-right)+8px)] h-9 w-9 grid place-items-center rounded-full bg-black/40 hover:bg-black/60 text-white/90 border border-white/10" aria-label="Fermer" title="Fermer" onclick={closePlayer}>
      <XIcon class="h-5 w-5" />
    </button>

    {#if $player.loading}
      <div class="w-full h-full grid place-items-center text-white/80 text-sm">Chargement…</div>
    {:else if $player.error}
      <div class="w-full h-full grid place-items-center">
        <div class="text-red-400 text-sm">{$player.error}</div>
      </div>
    {:else if $player.src}
      <div class="w-full h-full">
        <video
          bind:this={videoEl}
          src={$player.src}
          controls
          autoplay
          playsinline
          class="w-full h-full object-contain bg-black"
          onerror={() => nextCandidate()}
        ></video>
      </div>
    {/if}
  </div>
{/if}

<style>
  :global(video::-webkit-media-controls-panel) {
    backdrop-filter: blur(6px);
  }
</style>

