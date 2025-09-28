<script lang="ts">
  import { SafeArea } from '$lib/components/ui/safe-area';
  import { Input } from '$lib/components/ui/input';
  import { goto } from '$app/navigation';
  let q = $state('');
  function submit(e: Event) {
    e.preventDefault();
    if (q.trim().length > 0) goto(`/search?q=${encodeURIComponent(q.trim())}`);
  }
</script>

<SafeArea class="mx-auto w-full min-h-[100svh] px-5 sm:px-8 py-6 sm:py-8 space-y-6">
  <div class="pl-4 pr-4 sm:pl-6 sm:pr-6 space-y-4">
    <h1 class="text-lg sm:text-xl font-semibold">Recherche</h1>
    <form class="flex gap-3" onsubmit={submit}>
      <Input placeholder="Titre, acteur, genre..." bind:value={q} class="flex-1" />
      <button type="submit" class="sr-only">Rechercher</button>
    </form>
    <p class="text-sm text-muted-foreground">Tapez votre recherche ci-dessus.</p>
  </div>
</SafeArea>

