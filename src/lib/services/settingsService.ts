import type { Api } from '@jellyfin/sdk';
import { UserApiFactory } from '@jellyfin/sdk/lib/generated-client/api/user-api';
import { ConfigurationApiFactory } from '@jellyfin/sdk/lib/generated-client/api/configuration-api';
import type { UserDto } from '@jellyfin/sdk/lib/generated-client/models/user-dto';
import type { UserConfiguration } from '@jellyfin/sdk/lib/generated-client/models/user-configuration';
import type { ServerConfiguration } from '@jellyfin/sdk/lib/generated-client/models/server-configuration';

export type CurrentUserInfo = {
  id: string;
  name: string;
  isAdmin: boolean;
};

export async function fetchCurrentUser(api: Api): Promise<CurrentUserInfo> {
  const userApi = UserApiFactory(api.configuration, api.basePath, api.axiosInstance);
  const res = await userApi.getCurrentUser();
  const u = res.data as UserDto;
  const policy = u.Policy ?? (u as any).policy ?? {};
  return {
    id: (u as any).Id ?? (u as any).id ?? '',
    name: (u as any).Name ?? (u as any).name ?? '',
    isAdmin: !!(policy.IsAdministrator ?? policy.isAdministrator ?? false),
  };
}

// User configuration
export type { UserConfiguration };

export async function loadUserConfiguration(api: Api, userId?: string): Promise<UserConfiguration> {
  const userApi = UserApiFactory(api.configuration, api.basePath, api.axiosInstance);
  const res = userId ? await userApi.getUserById({ userId }) : await userApi.getCurrentUser();
  const u = res.data as UserDto;
  return (u.Configuration ?? (u as any).configuration ?? {}) as UserConfiguration;
}

export async function saveUserConfiguration(api: Api, userId: string | undefined, config: UserConfiguration): Promise<void> {
  const userApi = UserApiFactory(api.configuration, api.basePath, api.axiosInstance);
  await userApi.updateUserConfiguration({ userConfiguration: config, userId });
}

// Server configuration (admin)
export type { ServerConfiguration };

export async function loadServerConfiguration(api: Api): Promise<ServerConfiguration> {
  const configApi = ConfigurationApiFactory(api.configuration, api.basePath, api.axiosInstance);
  const res = await configApi.getConfiguration();
  return res.data as ServerConfiguration;
}

export async function saveServerConfiguration(api: Api, config: ServerConfiguration): Promise<void> {
  const configApi = ConfigurationApiFactory(api.configuration, api.basePath, api.axiosInstance);
  await configApi.updateConfiguration({ serverConfiguration: config });
}
