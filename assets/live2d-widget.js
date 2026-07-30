/**
 * Loads a locally hosted stevenjoezhang/live2d-widget and vert_classic model.
 */
(() => {
	const WIDGET_BASE = "/assets/vendor/live2d-widget/";
	const LINK_MESSAGE_DELAY = 120;
	const MAX_WIDGET_ATTEMPTS = 2;
	const MODEL_FRAME_TIMEOUT = 14000;
	let messageTimer = null;
	let lastLink = null;
	let recoveryInProgress = false;
	let dateMessageScheduled = false;

	function loadModule(src) {
		if (document.querySelector(`script[src="${src}"]`)) return Promise.resolve();

		return new Promise((resolve, reject) => {
			const script = document.createElement("script");
			script.type = "module";
			script.src = src;
			script.addEventListener("load", resolve, { once: true });
			script.addEventListener("error", reject, { once: true });
			document.head.append(script);
		});
	}

	function waitForElement(id, timeout = 12000) {
		return new Promise((resolve) => {
			const existing = document.getElementById(id);
			if (existing) {
				resolve(existing);
				return;
			}

			const observer = new MutationObserver(() => {
				const element = document.getElementById(id);
				if (!element) return;
				observer.disconnect();
				resolve(element);
			});

			observer.observe(document.body, { childList: true, subtree: true });
			window.setTimeout(() => {
				observer.disconnect();
				resolve(null);
			}, timeout);
		});
	}

	function delay(duration) {
		return new Promise((resolve) => window.setTimeout(resolve, duration));
	}

	function removeWidgetElements() {
		document.getElementById("waifu")?.remove();
		document.getElementById("waifu-toggle")?.remove();
	}

	function canvasHasRenderedFrame(canvas) {
		return new Promise((resolve) => {
			try {
				canvas.toBlob(
					(blob) => resolve(Boolean(blob && blob.size > 8000)),
					"image/png",
				);
			} catch {
				resolve(false);
			}
		});
	}

	async function waitForRenderedFrame(canvas, timeout = MODEL_FRAME_TIMEOUT) {
		const startedAt = performance.now();

		while (canvas.isConnected && performance.now() - startedAt < timeout) {
			if (await canvasHasRenderedFrame(canvas)) return true;
			await delay(700);
		}

		return false;
	}

	function showMessage(text, duration = 4200) {
		const tips = document.getElementById("waifu-tips");
		if (!tips || !text) return;

		window.clearTimeout(messageTimer);
		tips.replaceChildren();
		if (text instanceof Node) {
			tips.append(text);
		} else {
			tips.textContent = text;
		}
		tips.classList.add("waifu-tips-active");
		messageTimer = window.setTimeout(() => {
			tips.classList.remove("waifu-tips-active");
		}, duration);
	}

	function linkedMessage(prefix, label, href, suffix, newTab = false) {
		const content = document.createDocumentFragment();
		const link = document.createElement("a");
		link.className = "waifu-message-link";
		link.href = href;
		link.textContent = label;

		if (newTab) {
			link.target = "_blank";
			link.rel = "noopener noreferrer";
		}

		content.append(prefix, link, suffix);
		return content;
	}

	function linkLabel(link) {
		const explicitLabel = link.getAttribute("aria-label") || link.getAttribute("title");
		const visibleLabel = link.textContent.replace(/\s+/g, " ").trim();
		const label = explicitLabel || visibleLabel;
		if (label && label.length <= 36) return label;
		if (label) return `${label.slice(0, 33)}...`;

		try {
			const url = new URL(link.href, location.href);
			if (url.origin !== location.origin) return url.hostname;
			if (url.pathname === "/") return "首页";
			return decodeURIComponent(url.pathname.split("/").filter(Boolean).at(-1) || "这个页面");
		} catch {
			return "这个页面";
		}
	}

	function bindLinkMessages() {
		document.addEventListener("mouseover", (event) => {
			const link = event.target.closest?.("a[href]");
			if (!link || link === lastLink || link.closest("#waifu")) return;

			lastLink = link;
			window.setTimeout(() => {
				if (lastLink !== link || !link.matches(":hover")) return;
				const destination = new URL(link.href, location.href);
				const openInNewTab = link.target === "_blank" || destination.origin !== location.origin;
				showMessage(
					linkedMessage("要去「", linkLabel(link), destination.href, "」看看吗？", openInNewTab),
				);
			}, LINK_MESSAGE_DELAY);
		});

		document.addEventListener("mouseout", (event) => {
			const link = event.target.closest?.("a[href]");
			if (!link || link.contains(event.relatedTarget)) return;
			if (lastLink === link) lastLink = null;
		});
	}

	function bindSelectionSearch() {
		function offerSearch(event) {
			if (event.target.closest?.("#waifu, input, textarea, select")) return;

			window.setTimeout(() => {
				const selectedText = window.getSelection()?.toString().replace(/\s+/g, " ").trim();
				if (!selectedText || selectedText.length < 2) return;

				const query = selectedText.slice(0, 300);
				const label = selectedText.length > 48
					? `${selectedText.slice(0, 45)}...`
					: selectedText;
				const searchUrl = new URL("https://www.bing.com/search");
				searchUrl.searchParams.set("q", query);
				searchUrl.searchParams.set("setlang", "en-US");
				searchUrl.searchParams.set("cc", "US");

				showMessage(
					linkedMessage("要搜索「", label, searchUrl.href, "」吗？", true),
					6000,
				);
			}, 80);
		}

		document.addEventListener("pointerup", offerSearch);
		document.addEventListener("keyup", (event) => {
			if (event.key === "Shift" || event.key.startsWith("Arrow")) {
				offerSearch(event);
			}
		});
	}

	function dateMessage(now = new Date()) {
		const monthDay = `${now.getMonth() + 1}/${now.getDate()}`;
		const holidays = {
			"1/1": "新年快乐！新的一年也请多多关照。",
			"2/14": "今天是情人节。愿喜欢与被喜欢都有回应。",
			"3/8": "今天是国际妇女节，祝每一位女性节日快乐。",
			"5/1": "劳动节快乐！今天也要记得好好休息。",
			"6/1": "儿童节快乐！愿你一直保留一点好奇心。",
			"10/1": "国庆节快乐！愿今日安宁，山河常新。",
			"12/24": "平安夜到了，愿今晚平静而温暖。",
			"12/25": "圣诞快乐！愿你收到期待已久的好消息。",
			"12/31": "今天是今年的最后一天，要和这一年好好道别呀。",
		};

		if (holidays[monthDay]) return holidays[monthDay];
		if (now.getDay() === 0 || now.getDay() === 6) {
			return "周末到了。读点喜欢的东西，也别忘了休息。";
		}
		if (now.getHours() < 6) return "夜已经很深了，读完这一段就去休息吧。";
		if (now.getHours() < 11) return "早上好。今天想先从哪一篇开始看呢？";
		if (now.getHours() < 14) return "中午好。吃过饭再继续看也不迟。";
		if (now.getHours() < 18) return "下午好。要不要找篇感兴趣的文章看看？";
		return "晚上好。愿今晚有一段安静的阅读时间。";
	}

	const widgetConfig = {
		waifuPath: "/assets/live2d-tips.json?v=1",
		cubism2Path: `${WIDGET_BASE}live2d.min.js`,
		cubism5Path: "https://cubism.live2d.com/sdk-web/cubismcore/live2dcubismcore.min.js",
		tools: ["hitokoto", "photo", "info", "quit"],
		drag: true,
		showToggleAfterQuit: true,
		logLevel: "warn",
	};

	function recoverWidget(attempt) {
		const waifu = document.getElementById("waifu");
		waifu?.classList.remove("live2d-widget-ready");
		if (recoveryInProgress) return;

		recoveryInProgress = true;
		window.setTimeout(() => {
			removeWidgetElements();
			recoveryInProgress = false;

			if (attempt + 1 < MAX_WIDGET_ATTEMPTS) {
				startWidget(attempt + 1);
			} else {
				console.warn("Live2D widget stopped after repeated rendering failures.");
			}
		}, 700);
	}

	async function startWidget(attempt = 0) {
		try {
			window.initWidget(widgetConfig);
			const canvas = await waitForElement("live2d", MODEL_FRAME_TIMEOUT);
			if (!canvas) {
				recoverWidget(attempt);
				return;
			}

			canvas.addEventListener("webglcontextlost", (event) => {
				event.preventDefault();
				recoverWidget(attempt);
			}, { once: true });

			if (!await waitForRenderedFrame(canvas)) {
				recoverWidget(attempt);
				return;
			}

			const waifu = canvas.closest("#waifu");
			if (!waifu) return;
			waifu.classList.add("live2d-widget-ready");

			if (!dateMessageScheduled) {
				dateMessageScheduled = true;
				window.setTimeout(() => showMessage(dateMessage(), 6000), 7600);
			}
		} catch (error) {
			console.warn("Live2D widget failed to initialize.", error);
			recoverWidget(attempt);
		}
	}

	async function init() {
		if (window.matchMedia("(max-width: 760px)").matches) return;

		bindLinkMessages();
		bindSelectionSearch();

		try {
			await loadModule(`${WIDGET_BASE}waifu-tips.js`);
			if (typeof window.initWidget === "function") startWidget();
		} catch (error) {
			console.warn("Live2D widget loader failed.", error);
		}
	}

	if (document.readyState === "loading") {
		document.addEventListener("DOMContentLoaded", init, { once: true });
	} else {
		init();
	}
})();
