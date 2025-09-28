<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import { cn, type WithElementRef } from '$lib/utils.js';

  export type SwitchProps = WithElementRef<{}, HTMLButtonElement> & {
    checked?: boolean;
    disabled?: boolean;
    name?: string;
    onChange?: (checked: boolean) => void;
    class?: string;
    size?: 'sm' | 'md';
    label?: string;
  } & Pick<HTMLButtonAttributes, 'aria-label' | 'aria-labelledby' | 'id'>;

  let {
    ref = $bindable(null),
    checked = false,
    disabled = false,
    name,
    onChange,
    class: className,
    size = 'md',
    label,
    id,
    // aria attributes
    'aria-label': ariaLabel,
    'aria-labelledby': ariaLabelledby,
  }: SwitchProps = $props();

  function toggle() {
    if (disabled) return;
    checked = !checked;
    onChange?.(checked);
  }
</script>

<button
  bind:this={ref}
  type="button"
  role="switch"
  aria-checked={checked}
  aria-disabled={disabled}
  aria-label={ariaLabel}
  aria-labelledby={ariaLabelledby}
  {id}
  class={cn(
    'inline-flex items-center rounded-full transition-colors outline-none focus-visible:ring-[3px] focus-visible:ring-ring/50 ring-offset-background ring-offset-2',
    size === 'sm' ? 'h-5 w-9' : 'h-6 w-11',
    disabled ? 'opacity-50 pointer-events-none' : 'cursor-pointer',
    checked ? 'bg-primary' : 'bg-input/60 dark:bg-input/40',
    className
  )}
  onclick={toggle}
>
  <span
    class={cn(
      'bg-background shadow-xs block rounded-full transition-transform',
      size === 'sm' ? 'h-4 w-4 translate-x-0.5' : 'h-5 w-5 translate-x-0.5',
      checked ? (size === 'sm' ? 'translate-x-[18px]' : 'translate-x-[22px]') : ''
    )}
  ></span>
  {#if label}
    <span class="sr-only">{label}</span>
  {/if}
  {#if name}
    <!-- Hidden input to participate in forms -->
    <input class="sr-only" tabindex="-1" aria-hidden="true" value={checked ? 'on' : 'off'} name={name} />
  {/if}
</button>

