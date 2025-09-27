import type { PageLoad } from "./$types";
export const ssr = false;

import { getItem, getShowNextUp, getSeriesSeasons } from "$lib/core/api";

export const load: PageLoad = async ({ fetch, params }) => {
  const id = params.id;
  try {
    const [item, nextUp, seasons] = await Promise.all([
      getItem(id, fetch),
      getShowNextUp(id, fetch),
      getSeriesSeasons(id, fetch)
    ]);
    return { item, nextUp, seasons };
  } catch (e) {
    console.error("Failed to load item", id, e);
    return { item: null, nextUp: null, seasons: [] };
  }
};

