<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Skeleton } from '$lib/components/ui/skeleton';
  import { Button } from '$lib/components/ui/button';
  import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '$lib/components/ui/dropdown-menu';
  import { MediaCard } from '$lib/components/system';
  import { fetchLibraryItems, resolveLibraryId, type SortBy, type SortOrder } from '$lib/services/mediaService.js';

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
  let libraryName = $state<string>('Films');

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
        libraryName = 'Films';
      } else {
        const lib = await resolveLibraryId(baseUrl, token, userId, 'movies');
        libraryId = lib?.id ?? null;
        libraryName = lib?.name ?? 'Films';
      }
      pageIndex = 0;
      items = [];
      await loadPage(true);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('Failed to init movies page', e);
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
    const res = await fetchLibraryItems(baseUrl, token, userId, libraryId, 'Movie', {
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

  // react to URL parentId changes when navigating via menubar
  $effect(() => {
    const unsub = page.subscribe((p) => {
      const pid = p.url.searchParams.get('parentId');
      if (pid && pid !== libraryId) {
        libraryId = pid;
        libraryName = 'Films';
        void loadPage(true);
      }
    });
    return () => unsub();
  });

  onMount(() => {
    if (sentinel) {
      io = new IntersectionObserver((entries) => {
        for (const e of entries) {
          if (e.isIntersecting) onLoadMore();
        }
      }, { rootMargin: '200px' });
      io.observe(sentinel);
    }
    return () => io?.disconnect();
  });
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 space-y-6">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
  <div class="flex items-center justify-between gap-3">
    <h1 class="text-lg sm:text-xl font-semibold">{libraryName}</h1>
    <div class="flex items-center gap-2">
      <!-- View selector -->
      <DropdownMenu>
        <DropdownMenuTrigger>
          <Button variant="outline" size="sm">Vue: {viewMode === 'grid' ? 'Grille' : viewMode === 'rect' ? 'Rectangle' : 'Liste'}</Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" class="min-w-[180px]">
          <DropdownMenuItem on:select={() => (viewMode = 'grid')}>Grille</DropdownMenuItem>
          <DropdownMenuItem on:select={() => (viewMode = 'rect')}>Rectangle</DropdownMenuItem>
          <DropdownMenuItem on:select={() => (viewMode = 'list')}>Liste</DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
      <!-- Sort selector -->
      <DropdownMenu>
        <DropdownMenuTrigger>
          <Button variant="outline" size="sm">Trier: {sort.label}</Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" class="min-w-[220px]">
          {#each SORT_OPTS as o (o.id)}
            <DropdownMenuItem on:select={() => (sort = o)}>{o.label}</DropdownMenuItem>
          {/each}
        </DropdownMenuContent>
      </DropdownMenu>
    </div>
  </div>

  {#if loading}
    <!-- Loading skeletons adapted to view mode -->
    {#if viewMode === 'grid'}
      <div class="grid grid-cols-2 xs:grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-3 sm:gap-4">
        {#each Array.from({ length: 12 }) as _, i}
          <div>
            <div class="rounded-md overflow-hidden"><Skeleton class="w-full aspect-[2/3]" /></div>
            <Skeleton class="mt-2 h-4 w-24" />
          </div>
        {/each}
      </div>
    {:else if viewMode === 'rect'}
      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
        {#each Array.from({ length: 8 }) as _, i}
          <div>
            <div class="rounded-md overflow-hidden"><Skeleton class="w-full aspect-video" /></div>
            <Skeleton class="mt-2 h-4 w-40" />
          </div>
        {/each}
      </div>
    {:else}
      <div class="space-y-3">
        {#each Array.from({ length: 8 }) as _, i}
          <div class="flex gap-3">
            <Skeleton class="w-40 aspect-video rounded-md" />
            <div class="flex-1 space-y-2">
              <Skeleton class="h-4 w-48" />
              <Skeleton class="h-4 w-32" />
            </div>
          </div>
        {/each}
      </div>
    {/if}
  {:else}
    <!-- Items -->
    {#if items.length === 0}
      <p class="text-sm text-muted-foreground">Aucun film</p>
    {:else}
      {#if viewMode === 'grid'}
        <div class="grid grid-cols-2 xs:grid-cols-3 sm:grid-cols-4 md:grid-cols-6 lg:grid-cols-8 gap-3 sm:gap-4">
          {#each items as it (it.Id)}
            <MediaCard item={it} {baseUrl} {token} kind="movie" variant="grid" />
          {/each}
        </div>
      {:else if viewMode === 'rect'}
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 sm:gap-4">
          {#each items as it (it.Id)}
            <MediaCard item={it} {baseUrl} {token} kind="movie" variant="rect" />
          {/each}
        </div>
      {:else}
        <div class="space-y-3">
          {#each items as it (it.Id)}
            <MediaCard item={it} {baseUrl} {token} kind="movie" variant="list" />
          {/each}
        </div>
      {/if}

      <!-- Pagination controls -->
      <div class="mt-4 flex items-center justify-between gap-3">
        <div class="text-xs text-muted-foreground">{Math.min((pageIndex * pageSize) + items.length, total)} / {total}</div>
        <div class="flex items-center gap-2">
          <Button variant="outline" size="sm" disabled={pageIndex === 0} on:click={() => { pageIndex = Math.max(0, pageIndex - 1); void loadPage(true); }}>Précédent</Button>
          <Button variant="outline" size="sm" disabled={!hasMore} on:click={() => onLoadMore()}>Suivant</Button>
        </div>
      </div>

      <!-- Lazy loading sentinel -->
      <div bind:this={sentinel} class="h-1" aria-hidden="true"></div>
    {/if}
  {/if}
  </div>
</SafeArea>

