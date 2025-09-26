import type { PageLoad } from "./$types";
import { getItem } from "$lib/core/api";

export const load: PageLoad = async ({ fetch, params, url }) => {
  const id = params.id;
  const tStr = url.searchParams.get("t");
  const startTicks = tStr ? Number(tStr) : 0;
  try {
    const item = await getItem(id, fetch);
    return { item, startTicks };
  } catch (e) {
    console.error("Failed to load playable item", id, e);
    return { item: null, startTicks: 0 };
  }
};

