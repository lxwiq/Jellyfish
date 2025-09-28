<script lang="ts">
  import { ModeWatcher } from 'mode-watcher';
  import '../app.css';
  import { Progress } from '$lib/components/ui/progress';
  import { navigating } from '$app/stores';

  let { children } = $props();
  let isNavigating = $state(false);
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
