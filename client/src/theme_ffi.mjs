const KEY = "glfood_theme";

export function load_theme() {
  return localStorage.getItem(KEY) ?? "light";
}

export function save_theme(theme) {
  localStorage.setItem(KEY, theme);
}
