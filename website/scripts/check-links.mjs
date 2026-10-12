// Verify that links resolve inside the published GitHub Pages project path.
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, relative, resolve, sep } from "node:path";

const dist = resolve("dist");
const base = "/linux-recovery-toolkit/";
const origin = "https://tidus747.github.io";
const errors = [];

function htmlFiles(dir) {
  const results = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) results.push(...htmlFiles(path));
    else if (entry.isFile() && entry.name.endsWith(".html")) results.push(path);
  }
  return results;
}

if (!existsSync(join(dist, "index.html"))) {
  console.error("Missing dist/index.html. Run bun run build first.");
  process.exit(1);
}

const pages = htmlFiles(dist);
const required = ["", "getting-started/", "tools/", "guides/", "safety/"];
for (const path of required) {
  if (!existsSync(join(dist, path, "index.html"))) {
    errors.push(`Missing required route: ${base}${path}`);
  }
}

for (const page of pages) {
  const rel = relative(dist, page).split(sep).join("/");
  const pageUrl = new URL(base + rel.replace(/index\.html$/, ""), origin);
  const html = readFileSync(page, "utf8");
  const links = html.matchAll(/(?:href|src)\s*=\s*["']([^"'<>]+)["']/gi);

  for (const [, href] of links) {
    if (/^(?:#|data:|mailto:|tel:|javascript:)/i.test(href)) continue;

    let resolved;
    try { resolved = new URL(href.replaceAll("&amp;", "&"), pageUrl); }
    catch {
      errors.push(`${rel}: invalid URL ${href}`);
      continue;
    }

    if (resolved.origin !== origin) continue;
    if (!resolved.pathname.startsWith(base)) {
      errors.push(`${rel}: link escapes project base: ${href}`);
      continue;
    }

    let target;
    try { target = decodeURIComponent(resolved.pathname.slice(base.length)); }
    catch { errors.push(`${rel}: cannot decode link: ${href}`); continue; }
    const output = join(dist, target, target.endsWith("/") || !target ? "index.html" : "");
    if (!existsSync(output) && !existsSync(join(dist, target, "index.html"))) {
      errors.push(`${rel}: broken link ${href} -> ${resolved.pathname}`);
    }
  }
}

if (errors.length) {
  console.error(`Site link check failed with ${errors.length} error(s):\n${errors.join("\n")}`);
  process.exit(1);
}
console.log(`Checked ${pages.length} HTML pages and required navigation routes; all local links resolve.`);
