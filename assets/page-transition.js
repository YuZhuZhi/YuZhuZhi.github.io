/**
 * Site-controlled navigation transition and staggered blog-entry reveal.
 *
 * The page header and fixed widgets are deliberately not animated; only the
 * article body and footer participate in the transition.
 */
(() => {
	const TRANSITION_KEY = "codex-page-transition";
	const OUT_DURATION = 180;
	const ENTER_DURATION = 360;
	const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

	document.documentElement.classList.add("js");

	function readFlag() {
		try {
			return sessionStorage.getItem(TRANSITION_KEY) === "1";
		} catch {
			return false;
		}
	}

	function writeFlag(value) {
		try {
			if (value) {
				sessionStorage.setItem(TRANSITION_KEY, "1");
			} else {
				sessionStorage.removeItem(TRANSITION_KEY);
			}
		} catch {
			// Storage can be unavailable in strict privacy modes.
		}
	}

	function revealBlogEntries() {
		const entries = Array.from(document.querySelectorAll(".blog-entry"));
		if (entries.length === 0) return;

		if (reducedMotion.matches) {
			entries.forEach((entry) => entry.classList.add("is-revealed"));
			return;
		}

		entries.forEach((entry, index) => {
			if (
				entry.classList.contains("is-entering") ||
				entry.classList.contains("is-revealed")
			) {
				return;
			}

			entry.style.setProperty("--entry-index", String(Math.min(index, 8)));
			entry.classList.add("is-entering");

			const finish = () => {
				entry.classList.remove("is-entering");
				entry.classList.add("is-revealed");
			};

			entry.addEventListener("animationend", finish, { once: true });
			window.setTimeout(finish, 900 + Math.min(index, 8) * 90);
		});
	}

	function finishPageEnter() {
		if (document.documentElement.classList.contains("page-entering")) {
			window.setTimeout(() => {
				document.documentElement.classList.remove("page-entering");
			}, ENTER_DURATION);
		}

		revealBlogEntries();
	}

	function handleNavigationClick(event) {
		if (
			event.defaultPrevented ||
			event.button !== 0 ||
			event.metaKey ||
			event.ctrlKey ||
			event.altKey ||
			event.shiftKey
		) {
			return;
		}

		const link = event.target.closest("a[href]");
		if (!link || link.target || link.hasAttribute("download") || link.hash) {
			return;
		}

		const url = new URL(link.href, window.location.href);
		if (url.origin !== window.location.origin) {
			return;
		}

		if (
			url.pathname === window.location.pathname &&
			url.search === window.location.search &&
			url.hash === window.location.hash
		) {
			return;
		}

		event.preventDefault();

		if (reducedMotion.matches) {
			window.location.href = url.href;
			return;
		}

		writeFlag(true);
		document.documentElement.classList.add("page-leaving");
		window.setTimeout(() => {
			window.location.href = url.href;
		}, OUT_DURATION);
	}

	function init() {
		if (readFlag()) {
			writeFlag(false);
			document.documentElement.classList.add("page-entering");
		}

		document.addEventListener("click", handleNavigationClick);
		window.addEventListener("pageshow", (event) => {
			if (event.persisted) {
				document.documentElement.classList.remove("page-leaving", "page-entering");
				writeFlag(false);
			}

			revealBlogEntries();
		});

		if (document.readyState === "loading") {
			document.addEventListener("DOMContentLoaded", finishPageEnter, {
				once: true,
			});
		} else {
			finishPageEnter();
		}
	}

	init();
})();
