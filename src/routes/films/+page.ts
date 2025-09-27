import type { PageLoad } from "./$types";
export const ssr = false;

import { listMoviesPaged, type SortOrder } from "$lib/core/api";

export const load: PageLoad = async ({ fetch, url }) => {
  try {
    const page = Number(url.searchParams.get('page') ?? '1');
    const pageSize = Number(url.searchParams.get('pageSize') ?? '24');
    const q = url.searchParams.get('q') ?? '';
    const sort = url.searchParams.get('sort') ?? 'DateCreated';
    const order = (url.searchParams.get('order') ?? 'Descending') as SortOrder;

    const { items, total } = await listMoviesPaged({ page, pageSize, sortBy: sort, sortOrder: order, search: q }, fetch);
    return { items, total, page, pageSize, q, sort, order };
  } catch (e) {
    console.error('Failed to load movies', e);
    return { items: [], total: 0, page: 1, pageSize: 24, q: '', sort: 'DateCreated', order: 'Descending' };
  }
};

