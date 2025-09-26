import type { PageLoad } from "./$types";
import { getItem, getShowNextUp } from "$lib/core/api";

export const load: PageLoad = async ({ fetch, params }) => {
  const id = params.id;
  try {
    const [item, nextUp] = await Promise.all([
      getItem(id, fetch),
      getShowNextUp(id, fetch)
    ]);
    return { item, nextUp };
  } catch (e) {
    console.error("Failed to load item", id, e);
    return { item: null, nextUp: null };
  }
};

