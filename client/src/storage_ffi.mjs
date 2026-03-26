const KEY = "auth_token";

export function load_token() {
  return localStorage.getItem(KEY) ?? "";
}

export function save_token(token) {
  localStorage.setItem(KEY, token);
}

export function clear_token() {
  localStorage.removeItem(KEY);
}
