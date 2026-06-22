// Highlight the current section in the top nav as the user scrolls.
(function () {
  const links = document.querySelectorAll(".topnav nav a[href^='#']");
  if (!links.length) return;

  const map = new Map();
  links.forEach((a) => {
    const id = a.getAttribute("href").slice(1);
    const el = document.getElementById(id);
    if (el) map.set(el, a);
  });

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        const link = map.get(entry.target);
        if (!link) return;
        if (entry.isIntersecting) {
          links.forEach((l) => l.style.removeProperty("color"));
          link.style.color = "var(--accent)";
        }
      });
    },
    { rootMargin: "-40% 0px -55% 0px", threshold: 0 }
  );

  map.forEach((_, section) => observer.observe(section));
})();
