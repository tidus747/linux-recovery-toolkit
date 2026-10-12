import tailwindcss from "@tailwindcss/vite";
import { defineConfig } from "astro/config";
import { fileURLToPath, URL } from "node:url";

export default defineConfig({
  site: "https://tidus747.github.io",
  base: "/linux-recovery-toolkit",
  vite: {
    plugins: [tailwindcss()],
    resolve: { alias: { "@": fileURLToPath(new URL("./src", import.meta.url)) } },
  },
});
