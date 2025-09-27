<script lang="ts">
  import { Home, Clapperboard, Tv, Search, Plus } from "@lucide/svelte";
  import { page } from "$app/stores";
  import * as Tabs from "$lib/components/ui/tabs/index.js";
  const pathname = $derived($page.url.pathname);
  const isActive = (href: string) => pathname === href || pathname.startsWith(href + "/");
  const tabValue = $derived(
    pathname.startsWith("/search") ? "search" :
    pathname.startsWith("/add") ? "add" :
    pathname.startsWith("/films") ? "films" :
    pathname.startsWith("/series") ? "series" :
    "home"
  );
</script>

<nav class="fixed bottom-0 inset-x-0 z-20 border-t border-border/50 bg-background/95 backdrop-blur-md backdrop-saturate-100 supports-[backdrop-filter]:bg-background/95" aria-label="Navigation principale" data-testid="bottom-tabs">
  <!-- Paint the safe-area at the bottom (non-interactive) -->
  <div class="pointer-events-none absolute inset-x-0 -bottom-[env(safe-area-inset-bottom)] h-[env(safe-area-inset-bottom)] bg-background/95 supports-[backdrop-filter]:bg-background/95 sm:hidden"></div>

  <Tabs.Root value={tabValue} class="w-full pb-[env(safe-area-inset-bottom)] sm:pb-0">
    <Tabs.List class="w-full h-14 rounded-none border-0 shadow-none bg-transparent p-0 grid grid-cols-5 place-items-center">
      <Tabs.Trigger value="home" class="h-full w-full rounded-none border-transparent hover:bg-muted data-[state=active]:text-primary">
        <a href="/" aria-label="Accueil" title="Accueil" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover" class="flex h-full w-full items-center justify-center">
          <Home size={22} />
        </a>
      </Tabs.Trigger>
      <Tabs.Trigger value="films" class="h-full w-full rounded-none border-transparent hover:bg-muted data-[state=active]:text-primary">
        <a href="/films" aria-label="Films" title="Films" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover" class="flex h-full w-full items-center justify-center">
          <Clapperboard size={22} />
        </a>
      </Tabs.Trigger>
      <Tabs.Trigger value="series" class="h-full w-full rounded-none border-transparent hover:bg-muted data-[state=active]:text-primary">
        <a href="/series" aria-label="Séries" title="Séries" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover" class="flex h-full w-full items-center justify-center">
          <Tv size={22} />
        </a>
      </Tabs.Trigger>
      <Tabs.Trigger value="search" class="h-full w-full rounded-none border-transparent hover:bg-muted data-[state=active]:text-primary">
        <a href="/search" aria-label="Rechercher" title="Rechercher" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover" class="flex h-full w-full items-center justify-center">
          <Search size={22} />
        </a>
      </Tabs.Trigger>
      <Tabs.Trigger value="add" class="h-full w-full rounded-none border-transparent hover:bg-muted data-[state=active]:text-primary">
        <a href="/add" aria-label="Ajouter" title="Ajouter" data-sveltekit-preload-data="hover" data-sveltekit-preload-code="hover" class="flex h-full w-full items-center justify-center">
          <Plus size={22} />
        </a>
      </Tabs.Trigger>
    </Tabs.List>
  </Tabs.Root>
</nav>

