import type { PageLoad } from "./$types";
export const ssr = false;

import { listMovies } from "$lib/core/api";

export const load: PageLoad = async ({ fetch }) => {
  try {
    const items = await listMovies(500, fetch);
    return { items };
  } catch (e) {
    console.error('Failed to load movies', e);
    return { items: [] };
  }
};

