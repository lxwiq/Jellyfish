<script lang="ts">
	import { Progress as ProgressPrimitive } from "bits-ui";
	import { cn, type WithoutChildrenOrChild } from "$lib/utils.js";

	let {
		ref = $bindable(null),
		class: className,
		max = 100,
		value,
		...restProps
	}: WithoutChildrenOrChild<ProgressPrimitive.RootProps> = $props();
</script>

<ProgressPrimitive.Root
	bind:ref
	data-slot="progress"
	class={cn("bg-primary/20 relative h-2 w-full overflow-hidden rounded-full", className)}
	{value}
	{max}
	{...restProps}
>
	{#if value == null}
		<div class="h-full w-2/5 bg-primary rounded-full animate-[jfbar_1.1s_infinite_ease-in-out]"></div>
	{:else}
		<div
			data-slot="progress-indicator"
			class="bg-primary h-full w-full flex-1 transition-all"
			style="transform: translateX(-{100 - (100 * (value ?? 0)) / (max ?? 1)}%)"
		></div>
	{/if}
</ProgressPrimitive.Root>


<style>
  @keyframes jfbar {
    0% { transform: translateX(-100%); }
    50% { transform: translateX(50%); }
    100% { transform: translateX(250%); }
  }
</style>
