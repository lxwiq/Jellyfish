<script lang="ts">
  import { get } from 'svelte/store';
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { settings } from '$lib/state/settings.js';
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Button } from '$lib/components/ui/button';
  import { Switch } from '$lib/components/ui/switch';
  import { fetchCurrentUser, loadUserConfiguration, saveUserConfiguration, loadServerConfiguration, saveServerConfiguration } from '$lib/services/settingsService.js';
  import { logout } from '$lib/services/authService.js';
  import { SubtitlePlaybackMode } from '@jellyfin/sdk/lib/generated-client/models/subtitle-playback-mode';

  let loading = $state(false);
  let isAdmin = $state(false);
  let userConfig: Record<string, any> = $state({});
  let serverConfig: Record<string, any> = $state({});
  let userName = $state('');
  let avatarUrl = $state<string | null>(null);

  const subtitleModes = [
    SubtitlePlaybackMode.Default,
    SubtitlePlaybackMode.Always,
    SubtitlePlaybackMode.OnlyForced,
    SubtitlePlaybackMode.None,
    SubtitlePlaybackMode.Smart,
  ];

  $effect(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user || !s.api) {
      goto('/connect');
      return;
    }
    userName = s.user.name;
    avatarUrl = `${s.baseUrl}/Users/${s.user.id}/Images/Primary?api_key=${encodeURIComponent(s.token)}`;
    void (async () => {
      try {
        loading = true;
        const api = s.api!; const user = s.user!;
        const info = await fetchCurrentUser(api);
        isAdmin = info.isAdmin;
        userConfig = await loadUserConfiguration(api, user.id);
        serverConfig = isAdmin ? await loadServerConfiguration(api) : {};
      } finally {
        loading = false;
      }
    })();
  });

  async function saveUser() {
    const s = get(session);
    if (!s.api || !s.user) return;
    await saveUserConfiguration(s.api, s.user.id, userConfig);
  }
  async function saveServer() {
    if (!isAdmin) return;
    const s = get(session);
    if (!s.api) return;
    await saveServerConfiguration(s.api, serverConfig);
  }
  function onLogout() {
    logout();
    goto('/connect');
  }
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 space-y-6">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
    <header class="flex items-center gap-3">
      <img src={avatarUrl ?? ''} alt="avatar" class="h-9 w-9 rounded-full bg-secondary object-cover" onerror={(e) => ((e.currentTarget as HTMLImageElement).style.visibility='hidden')} />
      <div class="min-w-0">
        <h1 class="text-lg sm:text-xl font-semibold truncate">Paramètres</h1>
        <p class="text-xs text-muted-foreground truncate">{userName}{#if isAdmin} · Administrateur{/if}</p>
      </div>
      <div class="flex-1"></div>
      <Button variant="outline" size="sm" onclick={onLogout}>Déconnexion</Button>
    </header>
  </div>

  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-base font-semibold">Général</h2>
    </div>
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <div class="rounded-xl border p-4 space-y-4">
        <div class="flex items-center justify-between gap-4">
          <div>
            <p class="text-sm font-medium">Quick Connect</p>
            <p class="text-xs text-muted-foreground">Activer/désactiver la connexion rapide.</p>
          </div>
          <Switch checked={$settings.quickConnectEnabled} onChange={(v) => settings.setQuickConnectEnabled(v)} aria-label="Quick Connect" />
        </div>
      </div>
    </div>
  </section>

  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-base font-semibold">Préférences utilisateur</h2>
    <div class="rounded-xl border p-4 space-y-4">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm font-medium">Lecture automatique épisode suivant</p>
          <p class="text-xs text-muted-foreground">Lance automatiquement l'épisode suivant.</p>
        </div>
        <Switch checked={!!userConfig?.EnableNextEpisodeAutoPlay} onChange={(v) => (userConfig = { ...userConfig, EnableNextEpisodeAutoPlay: v })} />
      </div>
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm font-medium">Mémoriser la piste audio</p>
          <p class="text-xs text-muted-foreground">Réutiliser la dernière piste audio utilisée.</p>
        </div>
        <Switch checked={!!userConfig?.RememberAudioSelections} onChange={(v) => (userConfig = { ...userConfig, RememberAudioSelections: v })} />
      </div>
      <div>
        <Button size="sm" onclick={saveUser} disabled={loading}>Enregistrer</Button>
    </div>
      </div>
    </div>
  </section>

  <section class="space-y-3">
    <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
      <h2 class="text-base font-semibold">Lecteur vidéo</h2>

    <div class="rounded-xl border p-4 space-y-4">
      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="text-sm font-medium">Piste audio par défaut</p>
          <p class="text-xs text-muted-foreground">Lire la piste audio par défaut quand disponible.</p>
        </div>
        <Switch checked={!!userConfig?.PlayDefaultAudioTrack} onChange={(v) => (userConfig = { ...userConfig, PlayDefaultAudioTrack: v })} />
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div class="space-y-1.5">
          <label class="text-sm font-medium">Langue audio préférée</label>
          <input class="w-full h-9 rounded-md border bg-background px-3 text-sm" placeholder="ex: fr, en" bind:value={userConfig.AudioLanguagePreference} />
        </div>
        <div class="space-y-1.5">
          <label class="text-sm font-medium">Langue des sous-titres préférée</label>
          <input class="w-full h-9 rounded-md border bg-background px-3 text-sm" placeholder="ex: fr, en" bind:value={userConfig.SubtitleLanguagePreference} />
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div class="space-y-1.5">
          <label class="text-sm font-medium">Mode des sous-titres</label>
          <select class="w-full h-9 rounded-md border bg-background px-2 text-sm" bind:value={userConfig.SubtitleMode}>
            {#each subtitleModes as m}
              <option value={m}>{m}</option>
            {/each}
          </select>
        </div>
        <div class="flex items-center justify-between gap-4">
          <div>
            <p class="text-sm font-medium">Mémoriser les sous-titres</p>
            <p class="text-xs text-muted-foreground">Réutiliser les derniers sous-titres utilisés.</p>
          </div>
          <Switch checked={!!userConfig?.RememberSubtitleSelections} onChange={(v) => (userConfig = { ...userConfig, RememberSubtitleSelections: v })} />
        </div>
      </div>

      <div>
        <Button size="sm" onclick={saveUser} disabled={loading}>Enregistrer</Button>
    </div>
      </div>
    </div>
  </section>

  {#if isAdmin}
    <section class="space-y-3">
      <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
        <h2 class="text-base font-semibold">Serveur (Administrateur)</h2>

      <div class="rounded-xl border p-4 space-y-4">
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div class="space-y-1.5">
            <label class="text-sm font-medium">Débit maximum clients distants (Kbps)</label>
            <input type="number" min="0" class="w-full h-9 rounded-md border bg-background px-3 text-sm" bind:value={serverConfig.RemoteClientBitrateLimit} />
          </div>
          <div class="flex items-center justify-between gap-4">
            <div>
              <p class="text-sm font-medium">Contenu externe dans les suggestions</p>
              <p class="text-xs text-muted-foreground">Inclure des suggestions externes (bande-annonces, etc.).</p>
            </div>
            <Switch checked={!!serverConfig?.EnableExternalContentInSuggestions} onChange={(v) => (serverConfig = { ...serverConfig, EnableExternalContentInSuggestions: v })} />
          </div>
        </div>
        <div>
          <Button size="sm" onclick={saveServer} disabled={loading}>Enregistrer</Button>
      </div>
        </div>
      </div>
    </section>
  {/if}
</SafeArea>

