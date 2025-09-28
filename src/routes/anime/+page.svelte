<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { Button } from '$lib/components/ui/button';
  import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '$lib/components/ui/dropdown-menu';
  import { MediaCard } from '$lib/components/system';
  import { fetchLibraryItems, getUserViews, type SortBy, type SortOrder } from '$lib/services/mediaService.js';

  type ViewMode = 'grid' | 'rect' | 'list';
  type SortOpt = { id: string; label: string; sortBy: SortBy; sortOrder: SortOrder };

  const SORT_OPTS: SortOpt[] = [
    { id: 'title', label: 'Titre (A → Z)', sortBy: 'SortName', sortOrder: 'Ascending' },
    { id: 'dateAdded', label: 'Ajouté récemment', sortBy: 'DateCreated', sortOrder: 'Descending' },
    { id: 'release', label: 'Date de sortie', sortBy: 'PremiereDate', sortOrder: 'Descending' },
    { id: 'rating', label: 'Note', sortBy: 'CommunityRating', sortOrder: 'Descending' },
  ];

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let libraryId = $state<string | null>(null);
  let libraryName = $state<string>('Anime');

  let viewMode = $state<ViewMode>('grid');
  let sort = $state<SortOpt>(SORT_OPTS[1]);
  let pageSize = $state(24);

  let items: any[] = $state([]);
  let total = $state(0);
  let pageIndex = $state(0);
  let loading = $state(true);
  let loadingMore = $state(false);
  let hasMore = $state(false);

  let io: IntersectionObserver | null = null;
  let sentinel: HTMLDivElement | null = null;

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) {
      goto('/connect');
      return;
    }
    baseUrl = s.baseUrl;
    token = s.token;
    userId = s.user.id;
    void init();
  });

  async function init() {
    loading = true;
    try {
      const curr = get(page);
      const pid = curr.url.searchParams.get('parentId');
      if (pid) {
        libraryId = pid;
        libraryName = 'Anime';
      } else {
        // try find a view named like Anime
        const views = await getUserViews(baseUrl, token, userId);
        const normalize = (s: string | undefined) => (s ?? '').toLowerCase().normalize('NFD').replace(/[^a-z0-9\s-]/g, '').replace(/\s+/g, ' ').trim();
        const anime = views.find(v => normalize(v.Name).includes('anime')) ?? null;
        libraryId = anime?.Id ?? null;
        libraryName = anime?.Name ?? 'Anime';
      }
      pageIndex = 0;
      items = [];
      await loadPage(true);
    } catch (e) {
      console.error('Failed to init anime page', e);
    } finally {
      loading = false;
    }
  }

  async function loadPage(reset = false) {
    if (!libraryId) return;
    if (reset) {
      pageIndex = 0; items = []; total = 0; hasMore = false;
    }
    const startIndex = pageIndex * pageSize;
    // Anime libraries are usually TV series; fetch Series items by default
    const res = await fetchLibraryItems(baseUrl, token, userId, libraryId, 'Series', {
      startIndex,
      limit: pageSize,
      sortBy: sort.sortBy,
      sortOrder: sort.sortOrder,
    });
    if (reset) items = res.Items; else items = [...items, ...res.Items];
    total = res.TotalRecordCount;
    const loaded = (pageIndex + 1) * pageSize;
    hasMore = loaded < total;
  }

  function onLoadMore() {
    if (loadingMore || !hasMore) return;
    loadingMore = true;
    pageIndex += 1;
    loadPage(false).finally(() => (loadingMore = false));
  }

  $effect(() => {
    // re-run when sort or pageSize changes
    sort; pageSize; libraryId;
    if (libraryId) void loadPage(true);
  });

  // react to URL parentId changes when navigating
  $effect(() => {
    const unsub = page.subscribe((p) => {
      const pid = p.url.searchParams.get('parentId');
      if (pid && pid !== libraryId) {
        libraryId = pid;
        libraryName = 'Anime';
        void loadPage(true);
      }
    });
    return () => unsub();
  });

  function setupIO() {
    if (io) io.disconnect();
    if (!sentinel) return;
    io = new IntersectionObserver((entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting && hasMore && !loadingMore) onLoadMore();
      });
    });
    io.observe(sentinel);
  }

  $effect(() => { sentinel; setupIO(); return () => io?.disconnect(); });
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 space-y-6">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
    <div class="mb-3 flex items-center justify-between gap-3">
      <div class="flex items-center gap-2">
        <h1 class="text-xl font-semibold tracking-tight">{libraryName}</h1>
        <span class="text-xs text-muted-foreground">{total} titres</span>
      </div>
      <div class="flex items-center gap-2">
        <DropdownMenu>
          <DropdownMenuTrigger>
            <Button variant="outline" size="sm">Affichage</Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="min-w-[180px]">
            <DropdownMenuItem onclick={() => (viewMode = 'grid')}>Grille</DropdownMenuItem>
            <DropdownMenuItem onclick={() => (viewMode = 'rect')}>Rectangle</DropdownMenuItem>
            <DropdownMenuItem onclick={() => (viewMode = 'list')}>Liste</DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <DropdownMenu>
          <DropdownMenuTrigger>
            <Button variant="outline" size="sm">Trier</Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" class="min-w-[220px]">
            {#each SORT_OPTS as o (o.id)}
              <DropdownMenuItem onclick={() => (sort = o)}>{o.label}</DropdownMenuItem>
            {/each}
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </div>

    {#if loading}
      <!-- Loading skeletons matching viewMode -->
      {#if viewMode === 'list'}
        <div class="grid grid-cols-1 gap-2">
          {#each Array(10) as _, i}
            <div class="flex items-center gap-3">
              <Skeleton class="h-16 w-28 rounded-md" />
              <div class="flex-1 space-y-2">
                <Skeleton class="h-4 w-3/5" />
                <Skeleton class="h-3 w-2/5" />
              </div>
            </div>
          {/each}
        </div>
      {:else if viewMode === 'rect'}
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 sm:gap-4">
          {#each Array(12) as _, i}
            <Skeleton class="h-28 sm:h-32 w-full rounded-lg" />
          {/each}
        </div>
      {:else}
        <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-3 sm:gap-4">
          {#each Array(16) as _, i}
            <Skeleton class="aspect-[2/3] w-full rounded-lg" />
          {/each}
        </div>
      {/if}
    {:else}
      {#if items.length === 0}
        <div class="py-12 text-center text-sm text-muted-foreground">Aucun titre anime</div>
      {:else}
        {#if viewMode === 'list'}
          <div class="grid grid-cols-1 gap-2">
            {#each items as it (it.Id)}
              <MediaCard item={it} {baseUrl} {token} kind="series" variant="list" />
            {/each}
          </div>
        {:else if viewMode === 'rect'}
          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3 sm:gap-4">
            {#each items as it (it.Id)}
              <MediaCard item={it} {baseUrl} {token} kind="series" variant="rect" />
            {/each}
          </div>
        {:else}
          <div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-3 sm:gap-4">
            {#each items as it (it.Id)}
              <MediaCard item={it} {baseUrl} {token} kind="series" variant="grid" />
            {/each}
          </div>
        {/if}
        <!-- Infinite scroll sentinel -->
        <div bind:this={sentinel} class="h-1"></div>
        {#if loadingMore}
          <div class="py-4 text-center text-xs text-muted-foreground">Chargement…</div>
        {/if}
        <!-- Fallback pager -->
        <div class="mt-4 flex items-center gap-2">
          <Button variant="outline" size="sm" disabled={pageIndex === 0} onclick={() => { pageIndex = Math.max(0, pageIndex - 1); void loadPage(true); }}>Précédent</Button>
          <Button variant="outline" size="sm" disabled={!hasMore} onclick={() => onLoadMore()}>Suivant</Button>
        </div>
      {/if}
    {/if}
  </div>
</SafeArea>

