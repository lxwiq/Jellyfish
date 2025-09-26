<script lang="ts">
    import { Input } from "$lib/components/ui/input/index.js";
    import { Button } from "$lib/components/ui/button/index.js";
    import { onMount } from "svelte";
    import { goto } from "$app/navigation";
    import { saveHostAndVerify, normalizeBaseUrl } from "$lib/core/auth";
    import { getBaseUrl } from "$lib/core/storage";

    let host = "";
    let error = "";

    onMount(() => {
        const existing = getBaseUrl();
        if (existing) host = existing;
    });

    async function connect() {
        error = "";
        const baseUrl = normalizeBaseUrl(host);
        if (!baseUrl) {
            error = "Veuillez saisir l'URL du serveur.";
            return;
        }
        try {
            await saveHostAndVerify(baseUrl);
            await goto("/login");
        } catch (e) {
            console.error(e);
            error = "Impossible d'initialiser le serveur. Vérifiez l'URL et réessayez.";
        }
    }
</script>

<main class="flex flex-col gap-4 max-w-sm mx-auto justify-center h-screen">
    <h1 class="text-xl font-semibold">Configurer le serveur Jellyfin</h1>

    <form class="flex flex-col gap-4" on:submit|preventDefault={connect}>
        <Input type="text" placeholder="URL du serveur (ex: http://192.168.1.10:8096)" bind:value={host} />

        {#if error}
            <p class="text-sm text-red-500">{error}</p>
        {/if}

        <Button variant="default" size="default" disabled={!host.trim()} type="submit">Se connecter</Button>
    </form>
</main>

