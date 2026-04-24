import { getMediaByImdbID, OmdbSearchResult } from '../api/mediaApi';

const normalizeGenre = (value: string): string =>
  value.trim().toLowerCase().replace(/[-_\s]/g, '');

export const genreMatches = (genre: string, candidate: string): boolean =>
  normalizeGenre(candidate).includes(normalizeGenre(genre));

export const filterMediaByGenre = async (
  results: OmdbSearchResult[],
  genre: string,
): Promise<OmdbSearchResult[]> => {
  const normalizedGenre = normalizeGenre(genre);

  const filtered = await Promise.all(
    results.map(async (item) => {
      try {
        const detail = await getMediaByImdbID(item.imdbID);
        const genres = detail.data.genres ?? [];
        const matches = genres.some((g) => normalizeGenre(g).includes(normalizedGenre));
        return matches ? item : null;
      } catch {
        return null;
      }
    }),
  );

  return filtered.filter((item): item is OmdbSearchResult => item !== null);
};
