<script lang="ts">
  import { get } from 'svelte/store';
  import { session } from '$lib/state/session.js';
  import { settings } from '$lib/state/settings.js';
  import { Button } from '$lib/components/ui/button';
  import { Switch } from '$lib/components/ui/switch';
  import { goto } from '$app/navigation';
  import { fetchCurrentUser, loadUserConfiguration, saveUserConfiguration, loadServerConfiguration, saveServerConfiguration } from '$lib/services/settingsService.js';
  import { logout } from '$lib/services/authService.js';

  let expanded = $state(false);
  let isAdmin = $state(false);
  let loading = $state(false);

  // User/display/playback config
  let userConfig: Record<string, any> = $state({});
  // Server config (admin only)
  let serverConfig: Record<string, any> = $state({});

  let avatarUrl = $state<string | null>(null);
  let userName = $state<string>('');

  $effect(async () => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) return;
    userName = s.user.name;
    avatarUrl = `${s.baseUrl}/Users/${s.user.id}/Images/Primary?api_key=${encodeURIComponent(s.token)}`;
    try {
      loading = true;
      const info = await fetchCurrentUser(s.baseUrl, s.token, s.user.id);
      isAdmin = info.isAdmin;
      userConfig = await loadUserConfiguration(s.baseUrl, s.token, s.user.id);
      if (isAdmin) {
        serverConfig = await loadServerConfiguration(s.baseUrl, s.token);
      } else {
        serverConfig = {};
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn('Settings panel load failed', e);
    } finally {
      loading = false;
    }
  });

  function toggleExpanded() { expanded = !expanded; }

  async function saveUser() {
    const s = get(session);
    if (!s.baseUrl || !s.token || !s.user) return;
    await saveUserConfiguration(s.baseUrl, s.token, s.user.id, userConfig);
  }

  async function saveServer() {
    if (!isAdmin) return;
    const s = get(session);
    if (!s.baseUrl || !s.token) return;
    await saveServerConfiguration(s.baseUrl, s.token, serverConfig);
  }

  function onLogout() {
    logout();
    goto('/connect');
  }
</script>

<!-- Fixed top panel (mobile-first) -->
<div class="fixed inset-x-0 top-0 z-50 px-3 sm:px-4 pt-[env(safe-area-inset-top)]">
  <div class="mx-auto w-full max-w-6xl rounded-xl border border-white/20 dark:border-white/10 bg-white/80 dark:bg-neutral-900/70 backdrop-blur supports-[backdrop-filter]:bg-white/60 shadow-xl">
    <!-- Collapsed header -->
    <div class="flex items-center gap-3 p-2 sm:p-3">
      <!-- Expand/collapse -->
      <button class="h-8 w-8 grid place-items-center rounded-full hover:bg-black/5 dark:hover:bg-white/10 transition" aria-label={expanded ? 'Réduire' : 'Déployer'} onclick={toggleExpanded}>
        <svg viewBox="0 0 24 24" class="size-5" aria-hidden="true"><path fill="currentColor" d={expanded ? 'M7 14l5-5 5 5' : 'M7 10l5 5 5-5'} /></svg>
      </button>

      <!-- User info -->
      <div class="flex items-center gap-2 min-w-0">
        <img src={avatarUrl ?? ''} alt="avatar" class="h-7 w-7 rounded-full bg-secondary object-cover" onerror={(e) => ((e.currentTarget as HTMLImageElement).style.visibility='hidden')} />
        <div class="text-sm truncate">
          <span class="font-medium">{userName}</span>
          {#if isAdmin}
            <span class="ml-2 text-[10px] rounded bg-primary/15 text-primary px-1.5 py-0.5">Admin</span>
          {/if}
        </div>
      </div>

      <!-- Spacer -->
      <div class="flex-1"></div>

      <!-- Quick Connect toggle -->
      <div class="flex items-center gap-2">
        <span class="text-xs text-muted-foreground">Quick Connect</span>
        <Switch checked={$settings.quickConnectEnabled} onChange={(v) => settings.setQuickConnectEnabled(v)} aria-label="Quick Connect" />
      </div>

      <!-- Logout -->
      <Button variant="outline" size="sm" onclick={onLogout}>Logout</Button>
    </div>

    <!-- Expanded content -->
    {#if expanded}
      <div class="border-t border-border/60"></div>
      <div class="p-3 sm:p-4 grid grid-cols-1 sm:grid-cols-2 gap-4 max-h-[65svh] overflow-auto">
        <!-- User Settings: Personal / Display / Playback -->
        <section class="space-y-3">
          <h3 class="text-sm font-semibold">Preferences (User)</h3>
          <div class="rounded-lg border p-3 space-y-3">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium">Autoplay next episode</p>
                <p class="text-xs text-muted-foreground">Automatically play the next episode in a series.</p>
              </div>
              <Switch
                checked={!!userConfig?.EnableNextEpisodeAutoPlay}
                onChange={(v) => userConfig = { ...userConfig, EnableNextEpisodeAutoPlay: v }}
                aria-label="Autoplay next episode"
              />
            </div>
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium">Remember audio selections</p>
                <p class="text-xs text-muted-foreground">Use your last chosen audio track by default.</p>
              </div>
              <Switch
                checked={!!userConfig?.RememberAudioSelections}
                onChange={(v) => userConfig = { ...userConfig, RememberAudioSelections: v }}
                aria-label="Remember audio selections"
              />
            </div>
            <div class="pt-1">
              <Button size="sm" onclick={saveUser} disabled={loading}>Save user settings</Button>
            </div>
          </div>
        </section>

        <!-- Admin-only: Server Settings -->
        {#if isAdmin}
          <section class="space-y-3">
            <h3 class="text-sm font-semibold">Server (Admin)</h3>
            <div class="rounded-lg border p-3 space-y-3">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium">Allow remote connections</p>
                  <p class="text-xs text-muted-foreground">Permit external network access to the server.</p>
                </div>
                <Switch
                  checked={!!serverConfig?.EnableRemoteControlOfOtherUsers}
                  onChange={(v) => serverConfig = { ...serverConfig, EnableRemoteControlOfOtherUsers: v }}
                  aria-label="Allow remote"
                />
              </div>
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium">Enable Quick Connect</p>
                  <p class="text-xs text-muted-foreground">Allow signing in with Quick Connect codes.</p>
                </div>
                <Switch
                  checked={!!serverConfig?.EnableQuickConnect}
                  onChange={(v) => serverConfig = { ...serverConfig, EnableQuickConnect: v }}
                  aria-label="Enable Quick Connect"
                />
              </div>
              <div class="pt-1">
                <Button size="sm" onclick={saveServer} disabled={loading}>Save server settings</Button>
              </div>
            </div>
          </section>
        {/if}
      </div>
    {/if}
  </div>
</div>

<style>
  .size-5 { width: 20px; height: 20px; }
</style>

