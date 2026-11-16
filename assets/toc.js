/**
 * Builds a small floating table of contents for pages with enough subsections.
 */
(() => {
	const MIN_TOC_HEADINGS = 3;
	const TOC_DISABLED_PATHS = new Set(["/", "/Docs/", "/Blog/"]);

	function normalizePagePath(pathname) {
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

	function collectHeadings(section) {
		return Array.from(section.querySelectorAll("h2, h3, h4")).filter(
			(heading) => !heading.closest('[role="doc-bibliography"]'),
		);
	}

	function ensureHeadingId(heading, index, usedIds) {
		const fallbackId = `toc-${index + 1}`;
		const baseId = heading.id || fallbackId;
		let id = baseId;
		let suffix = 2;

		while (
			usedIds.has(id) ||
			(document.getElementById(id) && document.getElementById(id) !== heading)
		) {
			id = `${baseId}-${suffix}`;
			suffix += 1;
		}

		heading.id = id;
		usedIds.add(id);
		return id;
	}

	function buildToc(headings) {
		const nav = document.createElement("nav");
		nav.className = "toc-sidebar";
		nav.id = "toc-sidebar";
		nav.setAttribute("aria-label", "文章目录");

		const toggle = document.createElement("button");
		toggle.className = "toc-toggle";
		toggle.type = "button";
		toggle.setAttribute("aria-label", "文章目录");
		toggle.setAttribute("aria-controls", nav.id);
		const list = document.createElement("ol");
		const usedIds = new Set();
		const entriesById = new Map();

		headings.forEach((heading, index) => {
			const id = ensureHeadingId(heading, index, usedIds);
			const item = document.createElement("li");
			const link = document.createElement("a");
			const indicator = document.createElement("span");

			const level = heading.tagName === "H2" ? 1 : 2;
			item.classList.add(`toc-${heading.tagName.toLowerCase()}`);
			item.classList.add(`toc-level-${level}`);
			link.href = `#${id}`;
			link.textContent = heading.textContent.trim();
			indicator.className = "toc-toggle-line";
			indicator.classList.toggle("is-indented", level === 2);
			indicator.setAttribute("aria-hidden", "true");

			item.appendChild(link);
			list.appendChild(item);
			toggle.appendChild(indicator);
			entriesById.set(id, { link, indicator });
		});

		nav.appendChild(list);
		return { nav, toggle, entriesById };
	}

	function bindToggle(toggle, nav) {
		function setOpen(open) {
			nav.classList.toggle("is-open", open);
			toggle.setAttribute("aria-expanded", String(open));
			nav.inert = !open;
		}

		setOpen(true);
		toggle.addEventListener("click", () => {
			setOpen(!nav.classList.contains("is-open"));
		});
		nav.addEventListener("keydown", (event) => {
			if (event.key === "Escape") {
				setOpen(false);
				toggle.focus();
			}
		});
	}

	function bindSmoothScroll(nav) {
		nav.addEventListener("click", (event) => {
			const link = event.target.closest("a");
			if (!link || !nav.contains(link)) {
				return;
			}

			const target = document.getElementById(link.hash.slice(1));
			if (!target) {
				return;
			}

			event.preventDefault();
			target.scrollIntoView({ behavior: "smooth", block: "start" });
			history.replaceState(null, "", link.hash);
		});
	}

	function bindScrollSpy(entriesById, headings) {
		let activeEntry;

		function setActive(id) {
			activeEntry?.link.classList.remove("is-active");
			activeEntry?.link.removeAttribute("aria-current");
			activeEntry?.indicator.classList.remove("is-active");
			activeEntry = entriesById.get(id);
			activeEntry.link.classList.add("is-active");
			activeEntry.link.setAttribute("aria-current", "location");
			activeEntry.indicator.classList.add("is-active");
		}

		setActive(headings[0].id);

		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (entry.isIntersecting) {
						setActive(entry.target.id);
					}
				});
			},
			{
				rootMargin: "0px 0px -70% 0px",
				threshold: 0,
			},
		);

		headings.forEach((heading) => {
			observer.observe(heading);
		});
	}

	function init() {
		if (TOC_DISABLED_PATHS.has(normalizePagePath(window.location.pathname))) {
			return;
		}

		const section = document.querySelector("article > section");
		if (!section) {
			return;
		}

		const allHeadings = collectHeadings(section);
		const headings =
			allHeadings.length > 0 && allHeadings[0].tagName === "H2"
				? allHeadings.slice(1)
				: allHeadings;
		if (headings.length < MIN_TOC_HEADINGS) {
			return;
		}

		const { nav, toggle, entriesById } = buildToc(headings);
		bindToggle(toggle, nav);
		document.querySelector("article").before(toggle, nav);
		bindSmoothScroll(nav);
		bindScrollSpy(entriesById, headings);
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init);
	} else {
		init();
	}
})();
