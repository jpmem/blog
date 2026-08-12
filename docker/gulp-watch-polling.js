const fs = require("fs");
const path = require("path");
const chokidar = require("chokidar");
const gulp = require("gulp");

const pollingEnabled = !["false", "0", "off"].includes(
  (process.env.BLOG_WATCH_POLLING || "true").toLowerCase()
);
const sourceFolder = "articles";
const outputFolder = "source/_posts";

console.info(
  `[blog] File watching mode: ${pollingEnabled ? "polling" : "native"}`
);

const outputPath = (filePath) =>
  path.join(outputFolder, path.relative(sourceFolder, filePath));

const syncFile = (filePath) => {
  const destination = outputPath(filePath);
  fs.mkdirSync(path.dirname(destination), { recursive: true });

  if (path.extname(filePath).toLowerCase() !== ".md") {
    fs.copyFileSync(filePath, destination);
    return;
  }

  const markdown = fs
    .readFileSync(filePath, "utf8")
    .replace(/^# .*/m, "")
    .replace(/\]\((.+?).md\)/g, (match, link) => {
      const segments = link.split("/");
      const area = segments.at(-2);
      const title = segments.at(-1).replace(".md", "");
      return `](/blog/${area}/${title}/)`;
    });

  fs.writeFileSync(destination, markdown);
};

if (pollingEnabled) {
  gulp.watch = (globs) => {
    const watcher = chokidar.watch(globs, {
      ignoreInitial: true,
      usePolling: true,
      interval: 3000,
      awaitWriteFinish: {
        stabilityThreshold: 500,
        pollInterval: 100,
      },
    });

    watcher.on("add", syncFile);
    watcher.on("change", syncFile);
    watcher.on("unlink", (filePath) =>
      fs.rmSync(outputPath(filePath), { force: true })
    );
    return watcher;
  };
}