import type { PageLoad } from './$types';
import { getLatestMovies, getLatestSeries } from '$lib/core/api';

export const load: PageLoad = async ({ fetch }) => {
  const [movies, series] = await Promise.all([
    getLatestMovies(20, fetch),
    getLatestSeries(20, fetch),
  ]);
  return { movies, series };
};

