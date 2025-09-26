import type { PageLoad } from "./$types";
import { getItem } from "$lib/core/api"; // includes user data now

export const load: PageLoad = async ({ fetch, params }) => {
  const id = params.id;
  try {
    const item = await getItem(id, fetch);
    return { item };
  } catch (e) {
    console.error("Failed to load item", id, e);
    return { item: null };
  }
};

