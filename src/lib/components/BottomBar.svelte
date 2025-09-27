<script lang="ts">
  import { Home, Clapperboard, Tv } from "@lucide/svelte";
  import { page } from "$app/stores";
  import { Menubar } from "$lib/components/ui/menubar/index.js";
  $: pathname = $page.url.pathname;
  const isActive = (href: string) => pathname === href || pathname.startsWith(href + "/");
</script>

<nav class="fixed bottom-0 inset-x-0 z-20 border-t bg-background sm:bg-background/80 sm:backdrop-blur sm:supports-[backdrop-filter]:bg-background/60" aria-label="Navigation principale">
  <!-- Paint the safe-area at the bottom (non-interactive) -->
  <div class="pointer-events-none absolute inset-x-0 -bottom-[env(safe-area-inset-bottom)] h-[env(safe-area-inset-bottom)] bg-background sm:hidden"></div>

  <Menubar class="w-full h-14 rounded-none border-0 shadow-none bg-transparent p-0 grid grid-cols-3 place-items-center pb-[env(safe-area-inset-bottom)] sm:pb-0">
    <a href="/" class={isActive('/') ? 'flex h-full w-full items-center justify-center hover:bg-muted text-primary' : 'flex h-full w-full items-center justify-center hover:bg-muted opacity-80'} aria-label="Accueil" title="Accueil" aria-current={isActive('/') ? 'page' : undefined} data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover"><Home size={22} /></a>
    <a href="/films" class={isActive('/films') ? 'flex h-full w-full items-center justify-center hover:bg-muted text-primary' : 'flex h-full w-full items-center justify-center hover:bg-muted opacity-80'} aria-label="Films" title="Films" aria-current={isActive('/films') ? 'page' : undefined} data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover"><Clapperboard size={22} /></a>
    <a href="/series" class={isActive('/series') ? 'flex h-full w-full items-center justify-center hover:bg-muted text-primary' : 'flex h-full w-full items-center justify-center hover:bg-muted opacity-80'} aria-label="Séries" title="Séries" aria-current={isActive('/series') ? 'page' : undefined} data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover"><Tv size={22} /></a>
  </Menubar>
</nav>

