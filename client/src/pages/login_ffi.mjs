export async function post_json(url, body_str, on_ok, on_err) {
  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: body_str,
    });
    const data = await res.json();
    if (res.ok) {
      on_ok(data);
    } else {
      on_err(data.error ?? "Request failed");
    }
  } catch (e) {
    on_err(String(e));
  }
}
