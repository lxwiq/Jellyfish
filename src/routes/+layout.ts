// Tauri doesn't have a Node.js server to do proper SSR
// so we use adapter-static with a fallback to index.html to put the site in SPA mode
// See: https://svelte.dev/docs/kit/single-page-apps
// See: https://v2.tauri.app/start/frontend/sveltekit/ for more info
export const ssr = false;

import type { LayoutLoad } from './$types';
import { redirect } from '@sveltejs/kit';
import { getBaseUrl, getAccessToken } from '$lib/core/storage';

export const load: LayoutLoad = ({ url }) => {
    const path = url.pathname;
    const hasHost = !!getBaseUrl();
    const hasToken = !!getAccessToken();

    if (!hasHost && path !== '/host') {
        throw redirect(307, '/host');
    }

    if (hasHost && !hasToken && path !== '/login' && path !== '/host') {
        throw redirect(307, '/login');
    }

    if (hasHost && hasToken && (path === '/login' || path === '/host')) {
        throw redirect(307, '/');
    }

    return {};
};
