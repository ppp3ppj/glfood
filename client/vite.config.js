import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [
    // Tailwind v4 Vite plugin — faster than PostCSS, no config file needed
    tailwindcss(),
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
