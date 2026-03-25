let initialized = false;

function close_all() {
  // Early exit — skip DOM query when nothing is open
  const open = document.querySelector("details[open]");
  if (!open) return;
  document.querySelectorAll("details[open]").forEach((el) => {
    el.removeAttribute("open");
  });
}

export function setup_click_outside() {
  // Guard — only register listeners once
  if (initialized) return;
  initialized = true;

  document.addEventListener("click", (e) => {
    document.querySelectorAll("details[open]").forEach((el) => {
      if (!el.contains(e.target)) el.removeAttribute("open");
    });
  });

  document.addEventListener("visibilitychange", () => {
    if (document.hidden) close_all();
  });

  window.addEventListener("blur", () => close_all());
}
