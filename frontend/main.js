document.addEventListener("DOMContentLoaded", () => {
    getVisitCount().catch(console.error);
  });
  
  const functionApiUrl = "/api/GetResumeCounter";
  
  async function getVisitCount() {
    const el = document.getElementById("counter");
    if (!el) return;
  
    // Optional: avoid re-calling on every hard refresh navigation within session
    const cached = sessionStorage.getItem("resumeCounter");
    if (cached) {
      el.textContent = cached;
      return;
    }
  
    const res = await fetch(functionApiUrl, { cache: "no-store" });
    if (!res.ok) throw new Error(`Counter API failed: ${res.status}`);
  
    const data = await res.json();
    const count = Number(data?.count ?? 0).toLocaleString("en-US");
  
    el.textContent = count;
    sessionStorage.setItem("resumeCounter", count);
  }
  