<script lang="ts">
  import { goto } from '$app/navigation';
  import { session } from '$lib/state/session.js';
  import { get } from 'svelte/store';

  $effect.pre(() => {
    const { authenticated } = get(session);
    goto(authenticated ? '/home' : '/connect');
  });
</script>

<section class="p-6">
  <p>Redirecting…</p>
</section>

