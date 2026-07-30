/**
 * Adds a soft halo at the pointer that deepens while pressed.
 */
(() => {
	const HALO_ID = "cursor-halo";
	const REDUCED_MOTION = window.matchMedia("(prefers-reduced-motion: reduce)");

	function init() {
		if (REDUCED_MOTION.matches || document.getElementById(HALO_ID)) return;

		const halo = document.createElement("span");
		halo.id = HALO_ID;
		halo.setAttribute("aria-hidden", "true");
		const breath = document.createElement("span");
		breath.className = "cursor-halo-breath";
		halo.append(breath);
		document.body.append(halo);

		let pointerX = -100;
		let pointerY = -100;
		let frame = null;

		function placeHalo() {
			halo.style.transform = `translate3d(${pointerX}px, ${pointerY}px, 0) translate(-50%, -50%)`;
			frame = null;
		}

		function updatePointer(event) {
			if (event.pointerType === "touch") return;

			pointerX = event.clientX;
			pointerY = event.clientY;
			halo.classList.add("cursor-halo--visible");
			halo.classList.toggle(
				"cursor-halo--link",
				Boolean(event.target.closest?.("a[href]")),
			);

			if (frame === null) {
				frame = window.requestAnimationFrame(placeHalo);
			}
		}

		function pressHalo(event) {
			if (event.pointerType === "touch") return;
			halo.classList.remove("cursor-halo--clicked");
			void halo.offsetWidth;
			halo.classList.add("cursor-halo--clicked");
			halo.classList.add("cursor-halo--pressed");
		}

		function releaseHalo() {
			halo.classList.remove("cursor-halo--pressed");
		}

		window.addEventListener("pointermove", updatePointer, { passive: true });
		window.addEventListener("pointerdown", pressHalo, { passive: true });
		window.addEventListener("pointerup", releaseHalo, { passive: true });
		window.addEventListener("pointercancel", releaseHalo, { passive: true });
		window.addEventListener("blur", releaseHalo);
		window.addEventListener("pointerleave", () => {
			releaseHalo();
			halo.classList.remove("cursor-halo--link");
			halo.classList.remove("cursor-halo--visible");
		});
		halo.addEventListener("animationend", (event) => {
			if (event.animationName === "cursor-halo-expansion") {
				halo.classList.remove("cursor-halo--clicked");
			}
		});
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init, { once: true });
	} else {
		init();
	}
})();
