/**
 * Adds small, irregular groups of pale blue butterflies across the site.
 */
(() => {
	const CONTAINER_ID = "home-butterflies";
	const REDUCED_MOTION = window.matchMedia("(prefers-reduced-motion: reduce)");
	const MOBILE = window.matchMedia("(max-width: 760px)");
	const DESKTOP_MIN_COUNT = 5;
	const DESKTOP_MAX_COUNT = 10;
	const MOBILE_MIN_COUNT = 1;
	const MOBILE_MAX_COUNT = 3;
	let spawnTimer = null;

	function randomBetween(min, max) {
		return min + Math.random() * (max - min);
	}

	function createButterfly(delay = 0) {
		const butterfly = document.createElement("span");
		const isDistant = Math.random() < 0.58;
		const risesHigh = Math.random() < 0.22;
		const rise = risesHigh ? randomBetween(36, 52) : randomBetween(17, 34);
		const sway = randomBetween(-3.2, 3.2);
		const size = isDistant ? randomBetween(1.9, 2.9) : randomBetween(3, 4.15);

		butterfly.className = "home-butterfly";
		butterfly.classList.add(isDistant ? "home-butterfly--far" : "home-butterfly--near");
		butterfly.style.setProperty("--butterfly-size", `${size.toFixed(2)}rem`);
		butterfly.style.setProperty(
			"--butterfly-opacity",
			randomBetween(isDistant ? 0.42 : 0.62, isDistant ? 0.62 : 0.82).toFixed(2),
		);
		butterfly.style.setProperty(
			"--butterfly-duration",
			`${randomBetween(isDistant ? 19 : 13.5, isDistant ? 27 : 19).toFixed(2)}s`,
		);
		butterfly.style.setProperty("--butterfly-delay", `${delay.toFixed(2)}s`);
		butterfly.style.setProperty(
			"--butterfly-flutter",
			`${randomBetween(isDistant ? 0.62 : 0.42, isDistant ? 0.92 : 0.7).toFixed(2)}s`,
		);
		butterfly.style.setProperty("--flight-y-1", `${(-rise * 0.16 + sway).toFixed(1)}vh`);
		butterfly.style.setProperty("--flight-y-2", `${(-rise * 0.43 - sway * 0.45).toFixed(1)}vh`);
		butterfly.style.setProperty("--flight-y-3", `${(-rise * 0.72 + sway * 0.3).toFixed(1)}vh`);
		butterfly.style.setProperty("--flight-y-4", `${(-rise).toFixed(1)}vh`);
		butterfly.style.setProperty("--flight-rotate-1", `${randomBetween(-2, 7).toFixed(1)}deg`);
		butterfly.style.setProperty("--flight-rotate-2", `${randomBetween(-8, 2).toFixed(1)}deg`);
		butterfly.style.setProperty("--flight-rotate-3", `${randomBetween(-1, 8).toFixed(1)}deg`);
		butterfly.style.bottom = `${randomBetween(-8, 12).toFixed(1)}vh`;

		const farWing = document.createElement("img");
		farWing.className = "home-butterfly__sprite home-butterfly__sprite--far";
		farWing.src = "/assets/home-butterfly-side.png";
		farWing.alt = "";
		farWing.decoding = "async";
		farWing.draggable = false;

		const nearWing = document.createElement("img");
		nearWing.className = "home-butterfly__sprite home-butterfly__sprite--near";
		nearWing.src = "/assets/home-butterfly-side.png";
		nearWing.alt = "";
		nearWing.decoding = "async";
		nearWing.draggable = false;

		butterfly.append(farWing, nearWing);
		butterfly.addEventListener("animationend", () => {
			butterfly.remove();
			const container = document.getElementById(CONTAINER_ID);
			if (!container || document.hidden) return;

			const { min, max } = countRange();
			const missing = Math.min(min - container.childElementCount, max - container.childElementCount);
			if (missing > 0) addGroup(container, missing);
		}, { once: true });
		return butterfly;
	}

	function countRange() {
		return MOBILE.matches
			? { min: MOBILE_MIN_COUNT, max: MOBILE_MAX_COUNT }
			: { min: DESKTOP_MIN_COUNT, max: DESKTOP_MAX_COUNT };
	}

	function addGroup(container, amount) {
		for (let index = 0; index < amount; index += 1) {
			window.setTimeout(() => {
				const { max } = countRange();
				if (!document.hidden && container.childElementCount < max) {
					container.append(createButterfly());
				}
			}, index * randomBetween(240, 620));
		}
	}

	function scheduleNextGroup(container) {
		window.clearTimeout(spawnTimer);
		spawnTimer = window.setTimeout(() => {
			if (!document.hidden) {
				const { min, max } = countRange();
				const current = container.childElementCount;
				const target = Math.round(randomBetween(min, max));
				const required = Math.max(min - current, target - current, 0);
				addGroup(container, Math.min(required, Math.round(randomBetween(2, 4)), max - current));
			}
			scheduleNextGroup(container);
		}, randomBetween(3200, 6200));
	}

	function init() {
		if (REDUCED_MOTION.matches || document.getElementById(CONTAINER_ID)) return;

		const container = document.createElement("div");
		container.id = CONTAINER_ID;
		container.className = "home-butterflies";
		container.setAttribute("aria-hidden", "true");
		document.body.append(container);

		const { min, max } = countRange();
		const initialCount = Math.round(randomBetween(min, max));
		for (let index = 0; index < initialCount; index += 1) {
			const butterfly = createButterfly(-randomBetween(0.8, 21));
			container.append(butterfly);
		}

		scheduleNextGroup(container);
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init, { once: true });
	} else {
		init();
	}
})();
