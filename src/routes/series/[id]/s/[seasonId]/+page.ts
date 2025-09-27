import type { PageLoad } from "./$types";
import { getItem, getSeasonEpisodes } from "$lib/core/api";

export const load: PageLoad = async ({ fetch, params }) => {
  const seasonId = params.seasonId;
  try {
    const [season, episodes] = await Promise.all([
      getItem(seasonId, fetch),
      getSeasonEpisodes(seasonId, fetch)
    ]);
    return { season, episodes };
  } catch (e) {
    console.error("Failed to load season page", seasonId, e);
    return { season: null, episodes: [] };
  }
};

