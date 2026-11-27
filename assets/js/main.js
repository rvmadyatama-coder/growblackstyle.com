
document.addEventListener("DOMContentLoaded", () => {
  // Mobile navigation
  const toggle = document.querySelector(".menu-toggle");
  const nav = document.querySelector(".main-nav");

  if (toggle && nav) {
    const closeMenu = () => {
      nav.classList.remove("open");
      toggle.setAttribute("aria-expanded", "false");
      toggle.textContent = "☰";
    };

    toggle.addEventListener("click", () => {
      const open = nav.classList.toggle("open");
      toggle.setAttribute("aria-expanded", String(open));
      toggle.textContent = open ? "×" : "☰";
    });

    nav.querySelectorAll("a").forEach(link => {
      link.addEventListener("click", closeMenu);
    });

    document.addEventListener("keydown", event => {
      if (event.key === "Escape" && nav.classList.contains("open")) {
        closeMenu();
        toggle.focus();
      }
    });
  }

  // News category filtering
  const filters = document.querySelectorAll(".filter");
  const cards = document.querySelectorAll(".news-card");

  filters.forEach(button => {
    button.addEventListener("click", () => {
      filters.forEach(item => {
        item.classList.remove("active");
        item.setAttribute("aria-pressed", "false");
      });

      button.classList.add("active");
      button.setAttribute("aria-pressed", "true");

      const category = button.dataset.category;

      cards.forEach(card => {
        card.hidden =
          category !== "all" &&
          card.dataset.category !== category;
      });
    });
  });
});
