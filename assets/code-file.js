document.getElementById("copy")?.addEventListener("click", async (event) => {
  const button = event.currentTarget;
  try {
    await navigator.clipboard.writeText(document.getElementById("source").textContent);
    button.textContent = "已复制";
    setTimeout(() => { button.textContent = "复制代码"; }, 2000);
  } catch {
    button.textContent = "复制失败";
    setTimeout(() => { button.textContent = "复制代码"; }, 2000);
  }
});
