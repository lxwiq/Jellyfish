<script lang="ts">
  import { goto } from '$app/navigation';
  import { get } from 'svelte/store';
  import { session } from '$lib/state/session.js';
  import { loginWithCredentials } from '$lib/services/authService.js';
  import { Input } from '$lib/components/ui/input';
  import { Button } from '$lib/components/ui/button';
  import { Progress } from '$lib/components/ui/progress';
  import { SafeArea } from '$lib/components/ui/safe-area';

  let username = $state('');
  let password = $state('');
  let error = $state<string | null>(null);
  let loading = $state(false);

  async function onSubmit(e: Event) {
    e.preventDefault();
    error = null;
    const { api } = get(session);
    if (!api) {
      error = 'No server configured. Please connect first.';
      await goto('/connect');
      return;
    }
    try {
      loading = true;
      await loginWithCredentials(api, username.trim(), password);
      await goto('/home');
    } catch (err) {
      error = 'Invalid username or password';
    } finally {
      loading = false;
    }
  }
</script>

<SafeArea class="mx-auto w-full max-w-sm min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 flex flex-col justify-center space-y-6">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6 space-y-4">
    <h1 class="text-xl sm:text-2xl font-semibold">Sign in</h1>
    {#if loading}
      <Progress class="h-1" />
    {/if}
    <form onsubmit={onSubmit} class="space-y-3">
      <div class="space-y-1">
        <label class="text-sm font-medium" for="username">Username</label>
        <Input id="username" placeholder="Username" bind:value={username} required />
      </div>
      <div class="space-y-1">
        <label class="text-sm font-medium" for="password">Password</label>
        <Input id="password" type="password" placeholder="Password" bind:value={password} required />
      </div>
      {#if error}
        <p class="text-sm text-destructive">{error}</p>
      {/if}
      <Button class="w-full" type="submit" disabled={loading || !username.trim() || !password}>Sign in</Button>
    </form>
  </div>
</SafeArea>

