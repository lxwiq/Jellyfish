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

<section class="p-6">
  <p>Redirecting…</p>
</section>

