/**
 * Marks the current top-level navigation item and keeps the state correct
 * across normal loads and browser history restores.
 */
(() => {
	const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

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

	function clearGroupTimer(group) {
		if (group.dataset.toggleTimer) {
			window.clearTimeout(Number(group.dataset.toggleTimer));
			delete group.dataset.toggleTimer;
		}
	}

	function expandDocsGroup(group) {
		if (!group.classList.contains("is-collapsed")) return;

		clearGroupTimer(group);
		group.classList.remove("is-collapsed");
		const headingRow = group.querySelector(".docs-archive-heading-row");
		headingRow?.setAttribute("aria-expanded", "true");

		const list = group.querySelector(".docs-archive-list");
		if (list) {
			list.style.maxHeight = `${list.scrollHeight}px`;
			list.style.opacity = "1";
			window.setTimeout(() => {
				if (!group.classList.contains("is-collapsed")) {
					list.style.maxHeight = "none";
				}
			}, 440);
		}

		if (reducedMotion.matches) return;

		group.querySelectorAll(".docs-archive-item").forEach((item, index) => {
			item.style.setProperty("--item-index", String(Math.min(index, 10)));
			item.classList.remove("is-leaving");
			item.classList.add("is-entering");
			item.addEventListener(
				"animationend",
				() => item.classList.remove("is-entering"),
				{ once: true },
			);
		});
	}

	function collapseDocsGroup(group) {
		if (group.classList.contains("is-collapsed")) return;

		const headingRow = group.querySelector(".docs-archive-heading-row");
		headingRow?.setAttribute("aria-expanded", "false");

		clearGroupTimer(group);
		group.classList.add("is-collapsed");

		const list = group.querySelector(".docs-archive-list");
		if (list) {
			if (list.style.maxHeight === "none" || !list.style.maxHeight) {
				list.style.maxHeight = `${list.scrollHeight}px`;
				void list.offsetHeight;
			}
			list.style.maxHeight = "0px";
			list.style.opacity = "0";
		}

		if (reducedMotion.matches) return;

		const items = Array.from(group.querySelectorAll(".docs-archive-item"));
		const lastIndex = Math.max(0, items.length - 1);

		items.forEach((item, index) => {
			item.classList.remove("is-entering");
			item.style.setProperty(
				"--item-index",
				String(Math.min(lastIndex - index, 10)),
			);
			item.classList.add("is-leaving");
		});

		const delay = 360 + Math.min(items.length, 10) * 45;
		const timer = window.setTimeout(() => {
			items.forEach((item) => item.classList.remove("is-leaving"));
			delete group.dataset.toggleTimer;
		}, delay);

		group.dataset.toggleTimer = String(timer);
	}

	function toggleDocsGroup(group) {
		if (
			group.classList.contains("is-collapsed")
		) {
			clearGroupTimer(group);
			expandDocsGroup(group);
		} else {
			collapseDocsGroup(group);
		}
	}

	function updateArchiveTail(group) {
		const list = group.querySelector(".docs-archive-list");
		const items = list?.querySelectorAll(".docs-archive-item");
		if (!list || !items || items.length === 0) return;

		const lastItem = items[items.length - 1];
		const height = lastItem.getBoundingClientRect().height;
		if (height > 0) {
			list.style.setProperty("--archive-tail", `${height / 2}px`);
		}
	}

	function updateAllArchiveTails() {
		document.querySelectorAll(".docs-archive-group").forEach(updateArchiveTail);
	}

	function buildDocsArchive() {
		document.querySelectorAll(".docs-tab-panel").forEach((panel) => {
			if (panel.dataset.archiveReady === "true") return;

			let currentGroup = null;

			Array.from(panel.children).forEach((child) => {
				if (child.tagName === "H2") {
					const group = document.createElement("section");
					group.className = "docs-archive-group";

					const headingRow = document.createElement("div");
					headingRow.className = "docs-archive-heading-row";
					child.classList.add("docs-archive-heading");
					const headingNotes = Array.from(child.querySelectorAll(".marginnote"));

					panel.insertBefore(group, child);
					headingRow.append(child);
					group.append(headingRow);
					headingNotes.forEach((note) => group.append(note));
					currentGroup = group;
					return;
				}

				if (currentGroup) {
					currentGroup.append(child);
				}
			});

			panel.querySelectorAll(".docs-archive-group").forEach((group) => {
				// Essay entries are emitted as a paragraph containing a bare link
				// rather than an ordered list, so normalize them into the same list.
				Array.from(group.children).forEach((child) => {
					if (!child.matches("p, a[href]")) return;
					if (!child.matches("a[href]") && !child.querySelector("a[href]")) {
						return;
					}

					const list = document.createElement("ol");
					list.className = "docs-archive-list is-unnumbered";
					const item = document.createElement("li");
					item.className = "docs-archive-item is-unnumbered";

					while (child.firstChild) {
						item.append(child.firstChild);
					}

					list.append(item);
					child.replaceWith(list);
				});

				group.querySelectorAll("ol, ul").forEach((list) => {
					list.classList.add("docs-archive-list");
					Array.from(list.children).forEach((item) => {
						item.classList.add("docs-archive-item");

						const link = item.querySelector("a");
						if (
							link &&
							!link.querySelector(".docs-archive-link-text")
						) {
							const text = document.createElement("span");
							text.className = "docs-archive-link-text";
							while (link.firstChild) {
								text.append(link.firstChild);
							}
							link.append(text);

							const node = document.createElement("span");
							node.className = "docs-archive-node";
							node.setAttribute("aria-hidden", "true");
							link.append(node);
							link.addEventListener("pointerenter", () => {
								node.classList.add("is-active");
							});
							link.addEventListener("pointerleave", () => {
								node.classList.remove("is-active");
							});
							link.addEventListener("focus", () => {
								node.classList.add("is-active");
							});
							link.addEventListener("blur", () => {
								node.classList.remove("is-active");
							});
						}
					});

					list.style.transition = "none";
					list.style.maxHeight = "0px";
					list.style.opacity = "0";
					window.requestAnimationFrame(() => {
						list.style.transition = "";
					});
				});

				const count = group.querySelectorAll(".docs-archive-item").length;
				const countLabel = document.createElement("span");
				countLabel.className = "docs-archive-count";
				countLabel.textContent = count > 0 ? `${count} 篇` : "暂无";
				const headingRow = group.querySelector(".docs-archive-heading-row");
				headingRow?.append(countLabel);

				if (headingRow) {
					group.classList.add("is-collapsed");
					headingRow.setAttribute("role", "button");
					headingRow.setAttribute("tabindex", "0");
					headingRow.setAttribute("aria-expanded", "false");
					headingRow.addEventListener("click", () => toggleDocsGroup(group));
					headingRow.addEventListener("keydown", (event) => {
						if (event.key !== "Enter" && event.key !== " ") return;
						event.preventDefault();
						toggleDocsGroup(group);
					});
				}

				if (count === 0) {
					group.classList.add("is-empty");
				}
			});

			panel.dataset.archiveReady = "true";
		});

		window.requestAnimationFrame(updateAllArchiveTails);
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", () => {
			updateActiveNav();
			buildDocsArchive();
		});
	} else {
		updateActiveNav();
		buildDocsArchive();
	}

	window.addEventListener("pageshow", updateActiveNav);
	window.addEventListener("pagereveal", updateActiveNav);
	window.addEventListener("load", updateAllArchiveTails);
	window.addEventListener("resize", updateAllArchiveTails);
})();
