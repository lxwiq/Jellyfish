<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/stores';
  import { get } from 'svelte/store';
  $effect.pre(() => {
    const id = (get(page).params as any).id as string;
    goto(`/series/${id}?isAnime=1`);
  });
</script>

