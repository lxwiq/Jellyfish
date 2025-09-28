<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import '../app.css';
  import { Progress } from '$lib/components/ui/progress';
  import { navigating } from '$app/stores';
  import { restoreSession } from '$lib/services/authService.js';

  let { children } = $props();
  let isNavigating = $state(false);
  let didRestore = $state(false);

  // Restore as early as possible so child route guards see an authenticated session
  $effect.pre(() => {
    if (!didRestore) {
      try { restoreSession(); } catch {}
      didRestore = true;
    }
  });

  // Navigation progress bar effect (can run normally)
  $effect(() => {
    const unsub = navigating.subscribe((n) => { isNavigating = !!n; });
    return () => unsub();
  });
</script>

{#if isNavigating}
  <div class="fixed inset-x-0 z-50" style="top: env(safe-area-inset-top)">
    <Progress class="h-0.5" />
  </div>
{/if}

<ModeWatcher />
{@render children()}
