<script lang="ts">
  import { goto } from '$app/navigation';
  import { validateServerUrl, connectToServer } from '$lib/services/authService.js';
  import { Input } from '$lib/components/ui/input';
  import { Button } from '$lib/components/ui/button';
  import { Progress } from '$lib/components/ui/progress';
  import { SafeArea } from '$lib/components/ui/safe-area';

  let serverUrl = $state('');
  let error = $state<string | null>(null);
  let loading = $state(false);

  async function onSubmit(e: Event) {
    e.preventDefault();
    error = null;
    const v = validateServerUrl(serverUrl.trim());
    if (!v.ok) {
      error = v.error;
      return;
    }
    try {
      loading = true;
      connectToServer(v.url);
      await goto('/login');
    } catch (err) {
      error = 'Failed to connect to server';
    } finally {
      loading = false;
    }
  }
</script>

<SafeArea class="mx-auto w-full max-w-sm min-h-[100svh] px-4 py-6 sm:py-10 flex flex-col justify-center space-y-4">
  <h1 class="text-xl sm:text-2xl font-semibold">Connect to Jellyfin</h1>
  {#if loading}
    <Progress class="h-1" />
  {/if}
  <form onsubmit={onSubmit} class="space-y-3">
    <div class="space-y-1">
      <label class="text-sm font-medium" for="server-url">Server URL</label>
      <Input id="server-url" placeholder="https://serv.host.fr[/jellyfin]" bind:value={serverUrl} type="url" required aria-invalid={!!error} />
      {#if error}
        <p class="text-sm text-destructive">{error}</p>
      {/if}
    </div>
    <Button class="w-full" type="submit" disabled={loading || !serverUrl.trim()}>Continue</Button>
  </form>
</SafeArea>

