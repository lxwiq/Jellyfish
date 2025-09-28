<script lang="ts">
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { get } from 'svelte/store';
  import { restoreSession } from '$lib/services/authService.js';

  // On app boot, try to restore a previous session (Android/iOS/desktop)
  $effect.pre(() => {
    // Synchronous (localStorage) restore
    restoreSession();
    const { authenticated } = get(session);
    goto(authenticated ? '/home' : '/connect');
  });
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6">
    <p>Redirecting…</p>
  </div>
</SafeArea>

