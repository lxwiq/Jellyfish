<script lang="ts">
  import { ArrowLeft } from "@lucide/svelte";
  import { userAvatarUrl } from "$lib/core/images";
  import { getUserId } from "$lib/core/storage";
  let { showBack = false, title }: { showBack?: boolean; title?: string } = $props();
  const uid = getUserId();
  const avatar = uid ? userAvatarUrl(uid, { width: 32, height: 32 }) : "";
  const back = () => history.back();
</script>

<header class="sticky top-0 z-10 bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b">
  <div class="mx-auto max-w-7xl px-3 sm:px-4 h-14 flex items-center justify-between gap-3">
    <div class="flex items-center gap-2 min-w-0">
      {#if showBack}
        <button type="button" class="inline-flex items-center gap-2 px-2 py-1 rounded-md hover:bg-muted" onclick={back} aria-label="Retour">
          <ArrowLeft size={18} />
        </button>
      {/if}
      <div class="font-semibold tracking-tight shrink-0">Jellyfish</div>
      {#if title}
        <div class="ml-2 text-sm opacity-80 truncate">{title}</div>
      {/if}
    </div>
    <nav class="hidden sm:flex text-sm gap-4 opacity-90">
      <a href="/films" class="underline-offset-4 hover:underline" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover">Films</a>
      <a href="/series" class="underline-offset-4 hover:underline" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover">Séries</a>
    </nav>
    <div class="flex items-center gap-3">
      {#if avatar}
        <img src={avatar} alt="Avatar" class="size-8 rounded-full object-cover" />
      {:else}
        <div class="size-8 rounded-full bg-muted border"></div>
      {/if}
    </div>
  </div>
</header>

