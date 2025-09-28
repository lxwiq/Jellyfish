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
    /* Reserve bottom safe area + dynamic menubar height */
    padding-bottom: calc(env(safe-area-inset-bottom) + var(--menubar-reserved, 0px));
    padding-left: env(safe-area-inset-left);
  }
</style>

