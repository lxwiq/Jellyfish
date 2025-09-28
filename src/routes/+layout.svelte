<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import '../app.css';
  import { Progress } from '$lib/components/ui/progress';
  import { navigating } from '$app/stores';
  import { page } from '$app/stores';

  import { restoreSession } from '$lib/services/authService.js';
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { Menubar, MenubarMenu, MenubarTrigger, MenubarContent, MenubarItem } from '$lib/components/ui/menubar';
  import HomeIcon from '@lucide/svelte/icons/home';
  import LibraryIcon from '@lucide/svelte/icons/library';
  import SearchIcon from '@lucide/svelte/icons/search';


  let { children } = $props();
  let isNavigating = $state(false);
  let didRestore = $state(false);

  // Restore as early as possible so child route guards see an authenticated session
  $effect.pre(() => {
    if (!didRestore) {
      try { restoreSession(); } catch {}
      didRestore = true;
    }

  });

  // Fetch available libraries (views) to populate Libraries dropdown in bottom menubar
  let views: Array<{ Id: string; Name: string }> = $state([]);
  $effect(() => {
    const unsub = session.subscribe(async (s) => {
      try {
        if (s.authenticated && s.baseUrl && s.token && s.user?.id) {
          const res = await fetch(`${s.baseUrl}/Users/${s.user.id}/Views`, {
            headers: { 'X-Emby-Token': s.token },
          });
          const data = await res.json();
          views = data?.Items ?? [];
        } else {
          views = [];
        }
      } catch {
        views = [];
      }
    });
    return () => unsub();
  });

  // Navigation progress bar effect (can run normally)
  $effect(() => {
    const unsub = navigating.subscribe((n) => { isNavigating = !!n; });
    return () => unsub();
  });
</script>

{#if isNavigating}
  <div class="fixed inset-x-0 z-50" style="top: env(safe-area-inset-top)">
    <Progress class="h-0.5" />
  </div>
{/if}

<!-- Bottom Menubar Navigation -->

<!-- spacer to avoid content under the fixed menubar (approx height) -->


<Menubar class="fixed z-40 left-1/2 -translate-x-1/2 rounded-full border border-white/20 dark:border-white/10 bg-white/10 dark:bg-neutral-900/35 backdrop-blur-xl saturate-150 shadow-2xl px-2.5 py-1 supports-[backdrop-filter]:bg-white/10" style="bottom: calc(env(safe-area-inset-bottom) + 14px)">
  <div class="flex items-center gap-8">
    <!-- Home (hidden on /home) -->
    {#if !$page.url.pathname.startsWith('/home')}
      <button class="h-9 w-9 grid place-items-center rounded-full hover:bg-white/10 dark:hover:bg-white/5 transition" title="Accueil" aria-label="Accueil" onclick={() => goto('/home')}>
        <HomeIcon class="h-5 w-5" />
      </button>
    {/if}

    <!-- Libraries dropdown -->
    <MenubarMenu>
      <MenubarTrigger class="flex items-center justify-center py-1.5 focus:bg-transparent data-[state=open]:bg-transparent focus:text-foreground data-[state=open]:text-foreground outline-none" title="Bibliothèques" aria-label="Bibliothèques">
        <LibraryIcon class="h-5 w-5" />
      </MenubarTrigger>
      <MenubarContent side="top" align="center" class="min-w-[220px]">
        {#if views.length === 0}
          <MenubarItem disabled>Aucune bibliothèque</MenubarItem>
        {:else}
          {#each views as v (v.Id)}
            <MenubarItem on:click={() => goto(`/home?parentId=${v.Id}`)}>{v.Name}</MenubarItem>
          {/each}
        {/if}
      </MenubarContent>
    </MenubarMenu>

    <!-- Search -->
    <button class="h-9 w-9 grid place-items-center rounded-full hover:bg-white/10 dark:hover:bg-white/5 transition" title="Recherche" aria-label="Recherche" onclick={() => goto('/search')}>
      <SearchIcon class="h-5 w-5" />
    </button>
  </div>
</Menubar>


<ModeWatcher />
{@render children()}
