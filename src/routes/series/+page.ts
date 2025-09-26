import type { PageLoad } from "./$types";
export const ssr = false;

import { listSeries } from "$lib/core/api";

export const load: PageLoad = async ({ fetch }) => {
  try {
    const items = await listSeries(500, fetch);
    return { items };
  } catch (e) {
    console.error('Failed to load series', e);
    return { items: [] };
  }
};

