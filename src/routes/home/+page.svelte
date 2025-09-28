<script lang="ts">
  import { session } from '$lib/state/session.js';
  import { get } from 'svelte/store';
  import { goto } from '$app/navigation';
  import { SafeArea } from '$lib/components/ui/safe-area';

  let name = $state<string>('');

  $effect.pre(() => {
    const { authenticated, user } = get(session);
    if (!authenticated) {
      // Not logged in: go back to connect flow
      goto('/connect');
    } else {
      name = user?.name ?? '';
    }
  });
</script>

<SafeArea class="mx-auto w-full max-w-sm min-h-[100svh] px-4 py-6 sm:py-10 flex flex-col justify-center space-y-4">
  <h1 class="text-xl sm:text-2xl font-semibold">Hello {name}</h1>
</SafeArea>

