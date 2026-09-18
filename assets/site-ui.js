/**
 * Marks the current top-level navigation item and keeps the state correct
 * across normal loads and browser history restores.
 */
(() => {
	function normalizePath(pathname) {
		let path = pathname || "/";

		if (path.endsWith("/index.html")) {
			path = path.slice(0, -"index.html".length);
		} else if (path === "/index.html") {
			path = "/";
		}

		if (!path.endsWith("/")) {
			path += "/";
		}

		return path;
	}

	function updateActiveNav() {
		const links = Array.from(document.querySelectorAll(".site-nav a[href]"));
		if (links.length === 0) return;

		const currentPath = normalizePath(window.location.pathname);

		links.forEach((link) => {
			const targetPath = normalizePath(
				new URL(link.getAttribute("href") || link.href, window.location.href).pathname,
			);
			const isActive =
				targetPath === "/"
					? currentPath === "/"
					: currentPath === targetPath || currentPath.startsWith(targetPath);

			link.classList.toggle("is-active", isActive);

			if (isActive) {
				link.setAttribute("aria-current", "page");
			} else {
				link.removeAttribute("aria-current");
			}
		});
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", updateActiveNav);
	} else {
		updateActiveNav();
	}

	window.addEventListener("pageshow", updateActiveNav);
	window.addEventListener("pagereveal", updateActiveNav);
})();
