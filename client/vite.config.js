import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import { spawnSync } from "child_process";
import { resolve } from "path";

// Watches .gleam source files and re-runs `gleam build` on change.
// Vite then picks up the updated JS output and hot-reloads the browser.
function gleamPlugin() {
  function build() {
    const result = spawnSync("gleam", ["build"], {
      stdio: "inherit",
      cwd: resolve(__dirname),
    });
    return result.status === 0;
  }

  return {
    name: "gleam",

    buildStart() {
      build();
    },

    configureServer(server) {
      // Tell Vite's watcher to also watch gleam source files
      server.watcher.add([
        resolve(__dirname, "src/**/*.gleam"),
        resolve(__dirname, "../shared/src/**/*.gleam"),
      ]);

      server.watcher.on("change", (file) => {
        if (file.endsWith(".gleam")) {
          console.log(`[gleam] changed: ${file}`);
          const ok = build();
          if (ok) {
            server.ws.send({ type: "full-reload" });
          }
        }
      });
    },
  };
}

export default defineConfig({
  plugins: [
    tailwindcss(),
    gleamPlugin(),
  ],

  // SPA mode: serve index.html for all routes (needed for History API routing)
  appType: "spa",
  root: ".",

  server: {
    port: 3000,
    open: true,
  },

  build: {
    outDir: "dist",
  },
});
