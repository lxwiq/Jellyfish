<script lang="ts">
  import { page } from "$app/stores";
  import { Input } from "$lib/components/ui/input";
  import { Button } from "$lib/components/ui/button";
  import { itemPosterUrl, placeholderPosterUrl, posterSrcset, posterSizes } from "$lib/core/images";
  let { data } = $props<{ data: { items: any[]; total: number; page: number; pageSize: number; q: string; sort: string; order: 'Ascending'|'Descending' } }>();
  const items = data.items ?? [];
  let query = $state(data.q ?? '');
  const sort = data.sort ?? 'DateCreated';
  const order: 'Ascending'|'Descending' = (data.order ?? 'Descending') as any;
  const pageNum = data.page ?? 1;
  const pageSize = data.pageSize ?? 24;
  const total = data.total ?? 0;
  const imgFor = (i: any) => itemPosterUrl(i, { width: 300, height: 450 });

  const totalPages = $derived(Math.max(1, Math.ceil(total / pageSize)));
  const canPrev = $derived(pageNum > 1);
  const canNext = $derived(pageNum < totalPages);

  function buildUrl(params: Record<string, string | number | undefined>) {
    const sp = new URLSearchParams($page.url.search);
    for (const [k, v] of Object.entries(params)) {
      if (v === undefined || v === "") sp.delete(k); else sp.set(k, String(v));
    }
    return `/films?${sp.toString()}`;
  }
  const nextOrder = $derived(order === 'Descending' ? 'Ascending' : 'Descending');
  const prevHref = $derived(canPrev ? buildUrl({ page: pageNum - 1 }) : undefined);
  const nextHref = $derived(canNext ? buildUrl({ page: pageNum + 1 }) : undefined);
</script>


<main class="mx-auto max-w-7xl px-3 sm:px-4 py-4 space-y-4">
  <!-- Toolbar: search, sort, pagination -->
  <section class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
    <form class="flex items-center gap-2 w-full sm:w-auto" method="GET" action="/films">
      <Input class="w-full sm:w-72" placeholder="Rechercher un film..." name="q" bind:value={query} />
      <input type="hidden" name="sort" value={sort} />
      <input type="hidden" name="order" value={order} />
      <input type="hidden" name="page" value="1" />
      <input type="hidden" name="pageSize" value={pageSize} />
      <Button variant="secondary" type="submit">Rechercher</Button>
    </form>

    <div class="flex items-center gap-2">
      <Button variant={sort === 'DateCreated' ? 'default' : 'outline'} href={buildUrl({ sort: 'DateCreated', page: 1 })}>Nouveautés</Button>
      <Button variant={sort === 'Name' ? 'default' : 'outline'} href={buildUrl({ sort: 'Name', page: 1 })}>Nom</Button>
      <Button variant={sort === 'CommunityRating' ? 'default' : 'outline'} href={buildUrl({ sort: 'CommunityRating', page: 1 })}>Note</Button>
      <Button variant="ghost" href={buildUrl({ order: nextOrder, page: 1 })} aria-label="Invert order">{order === 'Descending' ? '↓' : '↑'}</Button>
    </div>
    <div class="flex items-center gap-2">
      <Button variant="outline" disabled={!canPrev} href={prevHref}>Précédent</Button>
      <span class="text-sm opacity-80">Page {pageNum} / {totalPages}</span>
      <Button variant="outline" disabled={!canNext} href={nextHref}>Suivant</Button>
    </div>
  </section>

  <section class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3 sm:gap-4">
    {#each items as m}
      <a href={`/films/${m.Id}`} class="block">
        <article class="w-full">
          <div class="overflow-hidden rounded-md">
            <div class="relative w-full aspect-[2/3]">
              <img src={imgFor(m)} srcset={posterSrcset(m, [200,300,450])} sizes={posterSizes} alt={m.Name} class="absolute inset-0 w-full h-full object-cover" loading="lazy" decoding="async" fetchpriority="low" onerror={(e) => ((e.currentTarget as HTMLImageElement).src = placeholderPosterUrl(300, 450, m.Name))} />
            </div>
          </div>
          <div class="mt-2 text-xs sm:text-sm font-medium line-clamp-2 min-h-[2.5rem]">{m.Name}</div>
        </article>
      </a>
    {/each}
  </section>
</main>

