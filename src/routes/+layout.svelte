<script lang="ts">
    import '../app.css';
    import { ModeWatcher } from "mode-watcher";
    import BottomBar from "$lib/components/BottomBar.svelte";
    import { page } from "$app/stores";

    let { children } = $props();
    const rawPath = $derived(String($page.url.pathname));
    const pathname = $derived(rawPath === '/index.html' ? '/' : rawPath);
    // Show the bottom bar on all app pages except a few (player/auth screens)
    const showBottomBar = $derived(!pathname.startsWith('/watch') && !pathname.startsWith('/login') && !pathname.startsWith('/host'));
</script>

<ModeWatcher defaultMode="dark" />
<!-- Paint top safe-area on iOS and keep it non-interactive -->
<div class="pointer-events-none fixed top-0 inset-x-0 h-[env(safe-area-inset-top)] bg-background sm:hidden"></div>

<div class={showBottomBar
  ? "min-h-screen pt-[env(safe-area-inset-top)] pb-[calc(3.5rem+env(safe-area-inset-bottom))]"
  : "min-h-screen pt-[env(safe-area-inset-top)] pb-[env(safe-area-inset-bottom)]"}>
  {@render children()}
</div>
{#if showBottomBar}
  <BottomBar />
{/if}
