/**
 * Lightweight client-side search over /search-index.json.
 */
(() => {
	function init() {
		const input = document.querySelector(".site-search-input");
		const resultBox = document.querySelector(".site-search-results");
		if (!input || !resultBox) return;

	const MAX_RESULTS = 8;
	let indexPromise = null;
	let debounceTimer = null;
	let activeIndex = -1;

	function normalize(value) {
		return String(value || "").toLocaleLowerCase("zh-CN").trim();
	}

	function loadIndex() {
		if (!indexPromise) {
			indexPromise = fetch("/search-index.json")
				.then((response) => (response.ok ? response.json() : []))
				.catch(() => []);
		}
		return indexPromise;
	}

	function resultHref(url) {
		try {
			const parsed = new URL(url, window.location.origin);
			return parsed.origin === window.location.origin
				? `${parsed.pathname}${parsed.search}${parsed.hash}`
				: url;
		} catch {
			return url;
		}
	}

	function scoreEntry(entry, query) {
		const title = normalize(entry.title);
		const description = normalize(entry.description);
		const headings = (entry.headings || []).map(normalize);
		let score = 0;

		if (title === query) score += 120;
		if (title.includes(query)) score += 80;
		if (description.includes(query)) score += 30;

		headings.forEach((heading) => {
			if (heading === query) score += 45;
			else if (heading.includes(query)) score += 20;
		});

		return score;
	}

	function closeResults() {
		resultBox.classList.remove("is-open");
		resultBox.replaceChildren();
		activeIndex = -1;
	}

	function renderResults(entries) {
		resultBox.replaceChildren();
		activeIndex = -1;

		if (entries.length === 0) {
			const empty = document.createElement("div");
			empty.className = "site-search-empty";
			empty.textContent = "没有找到匹配内容";
			resultBox.append(empty);
			resultBox.classList.add("is-open");
			return;
		}

		entries.forEach((entry) => {
			const link = document.createElement("a");
			link.className = "site-search-result";
			link.href = resultHref(entry.url);
			link.setAttribute("role", "option");

			const title = document.createElement("span");
			title.className = "site-search-result-title";
			title.textContent = entry.title;

			const meta = document.createElement("span");
			meta.className = "site-search-result-meta";
			meta.textContent =
				entry.description ||
				(entry.headings || []).slice(1, 4).join(" / ") ||
				entry.url;

			link.append(title, meta);
			resultBox.append(link);
		});

		resultBox.classList.add("is-open");
	}

	async function runSearch() {
		const query = normalize(input.value);
		if (!query) {
			closeResults();
			return;
		}

		const index = await loadIndex();
		const matches = index
			.map((entry) => ({ entry, score: scoreEntry(entry, query) }))
			.filter((item) => item.score > 0)
			.sort((a, b) => b.score - a.score)
			.slice(0, MAX_RESULTS)
			.map((item) => item.entry);

		renderResults(matches);
	}

	function focusResult(index) {
		const links = Array.from(resultBox.querySelectorAll(".site-search-result"));
		if (links.length === 0) return;
		activeIndex = (index + links.length) % links.length;
		links[activeIndex].focus();
	}

	input.addEventListener("input", () => {
		window.clearTimeout(debounceTimer);
		debounceTimer = window.setTimeout(runSearch, 120);
	});

	input.addEventListener("focus", () => {
		if (input.value.trim()) runSearch();
	});

	input.addEventListener("keydown", (event) => {
		if (event.key === "Escape") {
			closeResults();
			input.blur();
			return;
		}

		if (event.key === "ArrowDown") {
			event.preventDefault();
			focusResult(activeIndex + 1);
			return;
		}

		if (event.key === "ArrowUp") {
			event.preventDefault();
			focusResult(activeIndex - 1);
			return;
		}

		if (event.key === "Enter" && resultBox.classList.contains("is-open")) {
			const first = resultBox.querySelector(".site-search-result");
			if (first) {
				event.preventDefault();
				first.click();
			}
		}
	});

	document.addEventListener("click", (event) => {
		if (!event.target.closest(".site-search")) {
			closeResults();
		}
	});
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init);
	} else {
		init();
	}
})();
