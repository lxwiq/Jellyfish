<script lang="ts">
  import { get } from 'svelte/store';
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { onMount } from 'svelte';
  import { session } from '$lib/state/session.js';
  import { getPlaybackInfo } from '$lib/services/mediaService.js';

  let baseUrl = $state('');
  let token = $state('');
  let userId = $state('');
  let itemId = $state('');

  let src = $state<string | null>(null);
  let loading = $state(true);
  let error = $state<string | null>(null);

  $effect.pre(() => {
    const s = get(session);
    if (!s.authenticated || !s.baseUrl || !s.token || !s.user) { goto('/connect'); return; }
    baseUrl = s.baseUrl; token = s.token; userId = s.user.id;
    itemId = get(page).params.id as string;
    void init();
  });

  async function init() {
    loading = true; error = null; src = null;
    try {
      const info = await getPlaybackInfo(baseUrl, token, userId, itemId);
      const ms = (info.MediaSources ?? []);
      const first = ms[0] ?? {};
      let url = first.TranscodingUrl || first.DirectStreamUrl || '';
      if (url && !url.startsWith('http')) url = `${baseUrl}${url}`;
      if (url && url.indexOf('api_key=') === -1) url += (url.includes('?') ? '&' : '?') + `api_key=${encodeURIComponent(token)}`;
      src = url || null;
    } catch (e) {
      console.error('Playback error', e); error = 'Unable to start playback';
    } finally { loading = false; }
  }
</script>

{#if loading}
  <div class="p-4">Loading…</div>
{:else if error}
  <div class="p-4 text-destructive">{error}</div>
{:else if src}
  <div class="w-full h-[100svh] bg-black">
    <video src={src} controls autoplay playsinline class="w-full h-full" />
  </div>
{/if}

