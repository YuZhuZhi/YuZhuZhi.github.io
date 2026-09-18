/**
 * Animates same-page anchor links with a slow-in, fast-middle, slow-out
 * curve. The native hash jump is replaced by a distance-aware rAF scroll.
 */
(() => {
	const MIN_DURATION = 500;
	const MAX_DURATION = 1600;
	const MIN_SCROLL_DISTANCE = 2;
	const TARGET_OFFSET = 16;
	const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
	let frameId = null;

	function easeInOutQuint(t) {
		return t < 0.5
			? 16 * t * t * t * t * t
			: 1 - Math.pow(-2 * t + 2, 5) / 2;
	}

	function cancelAnimation() {
		if (frameId === null) return;
		window.cancelAnimationFrame(frameId);
		frameId = null;
	}

	function scrollToElement(target) {
		cancelAnimation();

		const startY = window.scrollY;
		const maxScrollY = Math.max(
			0,
			document.documentElement.scrollHeight - window.innerHeight,
		);
		const targetY = Math.min(
			maxScrollY,
			Math.max(0, target.getBoundingClientRect().top + startY - TARGET_OFFSET),
		);
		const distance = Math.abs(targetY - startY);

		if (distance <= MIN_SCROLL_DISTANCE) {
			window.scrollTo(0, targetY);
			return;
		}

		if (reducedMotion.matches) {
			window.scrollTo(0, targetY);
			return;
		}

		const duration = Math.min(
			MAX_DURATION,
			Math.max(MIN_DURATION, 420 + Math.sqrt(distance) * 7.5),
		);
		const startTime = performance.now();

		function step(now) {
			const progress = Math.min(1, (now - startTime) / duration);
			const eased = easeInOutQuint(progress);
			window.scrollTo(0, startY + (targetY - startY) * eased);

			if (progress < 1) {
				frameId = window.requestAnimationFrame(step);
			} else {
				frameId = null;
				window.scrollTo(0, targetY);
			}
		}

		frameId = window.requestAnimationFrame(step);
	}

	function handleAnchorClick(event) {
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
		if (!link || link.target || link.hasAttribute("download") || !link.hash) {
			return;
		}

		const url = new URL(link.href, window.location.href);
		if (
			url.origin !== window.location.origin ||
			url.pathname !== window.location.pathname ||
			url.search !== window.location.search
		) {
			return;
		}

		const id = decodeURIComponent(link.hash.slice(1));
		const target = document.getElementById(id);
		if (!target) return;

		event.preventDefault();
		history.replaceState(null, "", link.hash);
		scrollToElement(target);
	}

	document.addEventListener("click", handleAnchorClick);

	["wheel", "touchstart", "pointerdown"].forEach((eventName) => {
		window.addEventListener(eventName, cancelAnimation, { passive: true });
	});

	window.addEventListener(
		"keydown",
		(event) => {
			if (
				[
					" ",
					"ArrowDown",
					"ArrowUp",
					"End",
					"Home",
					"PageDown",
					"PageUp",
				].includes(event.key)
			) {
				cancelAnimation();
			}
		},
		{ passive: true },
	);
})();
