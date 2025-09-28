import type { Api } from '@jellyfin/sdk';
import { ItemsApiFactory } from '@jellyfin/sdk/lib/generated-client/api/items-api';

export type JellyfinItem = Record<string, any>;

export type FilmographyResult = {
  Items: JellyfinItem[];
  TotalRecordCount: number;
};

export async function getPersonFilmography(
  api: Api,
  userId: string,
  personId: string,
  opts: { startIndex?: number; limit?: number } = {}
): Promise<FilmographyResult> {
  const itemsApi = ItemsApiFactory(api.configuration, api.basePath, api.axiosInstance);
  const res = await itemsApi.getItems({
    userId,
    personIds: [personId],
    includeItemTypes: ['Movie', 'Series', 'Episode'],
    recursive: true,
    startIndex: opts.startIndex ?? 0,
    limit: opts.limit ?? 100,
    sortBy: ['PremiereDate'],
    sortOrder: ['Descending'],
    enableUserData: true,
    enableImages: true,
    enableTotalRecordCount: true,
    fields: [
      'PrimaryImageAspectRatio',
      'MediaStreams',
      'Overview',
      'People',
      'ProviderIds'
    ]
  });
  const data: any = res.data ?? {};
  return {
    Items: Array.isArray(data.Items) ? data.Items : [],
    TotalRecordCount: data.TotalRecordCount ?? (Array.isArray(data.Items) ? data.Items.length : 0)
  };
}

