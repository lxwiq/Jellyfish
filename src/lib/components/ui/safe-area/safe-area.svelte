<script lang="ts">
  import { cn } from '$lib/utils.js';
  let { class: className, children } = $props();
</script>

<div class={cn('safe-area overflow-x-hidden w-full max-w-[100vw]', className)}>
  {@render children?.()}
</div>

<style>
  .safe-area {
    box-sizing: border-box;
    padding-top: env(safe-area-inset-top);
    padding-right: env(safe-area-inset-right);
    padding-bottom: env(safe-area-inset-bottom);
    padding-left: env(safe-area-inset-left);
  }
</style>

