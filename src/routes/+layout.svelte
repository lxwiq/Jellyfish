<script lang="ts">
    import '../app.css';
    import { ModeWatcher } from "mode-watcher";
    import BottomBar from "$lib/components/BottomBar.svelte";
    import { page } from "$app/stores";

    let { children } = $props();
    const pathname = $derived($page.url.pathname);
    const showBottomBar = $derived(pathname === '/' || pathname.startsWith('/films') || pathname.startsWith('/series'));
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
