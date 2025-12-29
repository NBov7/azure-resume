document.addEventListener("DOMContentLoaded", () => {
  getVisitCount().catch((e) => console.error("Counter failed:", e));
});

const functionApiUrl = "/api/GetResumeCounter";

async function getVisitCount() {
  const line = document.getElementById("counter-line");
  const el = document.getElementById("counter");
  if (!line || !el) return;

  // Optional: avoid calling API multiple times per session
  const cached = sessionStorage.getItem("resumeCounter");
  if (cached) {
    el.textContent = cached;
    line.style.display = "";
    return;
  }

  const res = await fetch(functionApiUrl, { cache: "no-store" });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);

  const data = await res.json();
  const count = Number(data?.count);
  if (!Number.isFinite(count)) throw new Error("Invalid counter payload");

  const pretty = count.toLocaleString("en-US");
  el.textContent = pretty;

  sessionStorage.setItem("resumeCounter", pretty);
  line.style.display = "";
}
