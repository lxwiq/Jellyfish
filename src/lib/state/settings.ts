import { writable } from 'svelte/store';
import { getQuickConnectEnabled as readQuickConnect, setQuickConnectEnabled as writeQuickConnect } from '$lib/core/storage.js';

export type AppSettings = {
  quickConnectEnabled: boolean;
};

const initial: AppSettings = {
  quickConnectEnabled: readQuickConnect() ?? true,
};

function createSettings() {
  const { subscribe, update, set } = writable<AppSettings>(initial);
  return {
    subscribe,
    setQuickConnectEnabled: (val: boolean) => {
      writeQuickConnect(val);
      update((s) => ({ ...s, quickConnectEnabled: val }));
    },
    reset: () => set(initial),
  };
}

export const settings = createSettings();

