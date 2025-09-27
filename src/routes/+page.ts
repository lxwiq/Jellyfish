import type { PageLoad } from './$types';
import { getLatestMovies, getLatestSeries, getNextUpEpisodes, getResumeMovies, getResumeEpisodes } from '$lib/core/api';

export const load: PageLoad = async ({ fetch }) => {
  const [movies, series, nextUp, resumeMovies, resumeEpisodes] = await Promise.all([
    getLatestMovies(20, fetch),
    getLatestSeries(20, fetch),
    getNextUpEpisodes(20, fetch),
    getResumeMovies(20, fetch),
    getResumeEpisodes(20, fetch),
  ]);
  return { movies, series, nextUp, resumeMovies, resumeEpisodes };
};

