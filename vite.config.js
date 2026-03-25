import { defineConfig } from "vite";

export default defineConfig({
  // Serve index.html from project root
  root: ".",

  server: {
    port: 3000,
    open: true,
  },

  build: {
    // Output to dist/ for production
    outDir: "dist",
  },
});
