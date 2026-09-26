#!/usr/bin/env node
// Reads Mermaid diagram source on stdin, prints a JSON array of Excalidraw
// elements on stdout.
//
// `@excalidraw/mermaid-to-excalidraw` is a browser library: it needs an SVG
// DOM to lay out text (mermaid.js measures label bounding boxes via
// getBBox/getComputedTextLength). We fake that with jsdom + fixed-size
// stubs, since jsdom doesn't implement real layout — this means box sizes
// are a constant guess, not measured from the actual text. Good enough for
// a first-pass diagram; nudge things in the editor after.
//
// `parseMermaidToExcalidraw` returns the convenience "skeleton" format
// (elements carry a `.label` string and arrows carry `.start`/`.end`
// `{id}` refs). The real Excalidraw app expands that via
// `convertToExcalidrawElements`, but that package is built for
// webpack/vite bundlers and doesn't run under plain Node ESM (breaks on
// extensionless `roughjs` subpath imports and unattributed JSON imports).
// `expandSkeleton` below is a small hand-rolled equivalent: it fills the
// standard Excalidraw element defaults and turns `.label`/`.start`/`.end`
// into proper bound-text elements and arrow bindings. It won't be
// pixel-identical to Excalidraw's own expansion (no fine-tuned
// gap/focus/text-centering math) but produces elements the app will happily
// open and let you tidy up.

import { JSDOM } from "jsdom";

const dom = new JSDOM("<!DOCTYPE html><body></body>", { pretendToBeVisual: true });
globalThis.window = dom.window;
globalThis.document = dom.window.document;
globalThis.DOMParser = dom.window.DOMParser;
globalThis.SVGElement = dom.window.SVGElement;
globalThis.HTMLElement = dom.window.HTMLElement;
globalThis.getComputedStyle = dom.window.getComputedStyle;

// Fixed-size stand-ins for real text measurement (see module comment).
dom.window.SVGElement.prototype.getBBox = () => ({ x: 0, y: 0, width: 100, height: 30 });
dom.window.SVGElement.prototype.getComputedTextLength = () => 60;

const randomId = () => Math.random().toString(36).slice(2, 12);
const randomSeed = () => Math.floor(Math.random() * 2 ** 31);

const baseDefaults = () => ({
  angle: 0,
  strokeColor: "#1e1e1e",
  backgroundColor: "transparent",
  fillStyle: "solid",
  strokeWidth: 2,
  strokeStyle: "solid",
  roughness: 1,
  opacity: 100,
  groupIds: [],
  frameId: null,
  boundElements: [],
  updated: Date.now(),
  link: null,
  locked: false,
  isDeleted: false,
  version: 1,
  versionNonce: randomSeed(),
  seed: randomSeed(),
});

const textElementFor = (containerId, text, fontSize, x, y, width, height) => ({
  ...baseDefaults(),
  id: `${containerId}-label-${randomId()}`,
  type: "text",
  x,
  y,
  width,
  height,
  strokeWidth: 1,
  text,
  originalText: text,
  fontSize: fontSize ?? 20,
  fontFamily: 1,
  textAlign: "center",
  verticalAlign: "middle",
  containerId,
  lineHeight: 1.25,
  baseline: (fontSize ?? 20) * 0.8,
});

/** Expands the mermaid-to-excalidraw skeleton format into real, flat
 * Excalidraw scene elements (see module comment for what's approximated). */
function expandSkeleton(skeletonElements) {
  const out = [];
  const byId = new Map(skeletonElements.map((el) => [el.id, el]));

  for (const el of skeletonElements) {
    const { label, start, end, ...rest } = el;
    const full = { ...baseDefaults(), ...rest };

    if (start && end) {
      full.startBinding = { elementId: start.id, focus: 0, gap: 4 };
      full.endBinding = { elementId: end.id, focus: 0, gap: 4 };
      for (const boundId of [start.id, end.id]) {
        const boundEl = byId.get(boundId);
        if (boundEl) {
          boundEl.boundElements ??= [];
          boundEl.boundElements.push({ id: full.id, type: "arrow" });
        }
      }
    }

    out.push(full);

    if (label?.text) {
      const cx = (full.x ?? 0) + (full.width ?? 0) / 2;
      const cy = (full.y ?? 0) + (full.height ?? 0) / 2;
      const textWidth = Math.max(20, label.text.length * (label.fontSize ?? 20) * 0.55);
      const textHeight = (label.fontSize ?? 20) * 1.25;
      const textEl = textElementFor(
        full.id,
        label.text,
        label.fontSize,
        cx - textWidth / 2,
        cy - textHeight / 2,
        textWidth,
        textHeight,
      );
      full.boundElements = [...(full.boundElements ?? []), { id: textEl.id, type: "text" }];
      out.push(textEl);
    }
  }

  return out;
}

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) chunks.push(chunk);
  return Buffer.concat(chunks).toString("utf8");
}

async function main() {
  const mermaidText = await readStdin();
  if (!mermaidText.trim()) {
    process.stderr.write("no mermaid source on stdin\n");
    process.exit(1);
  }

  const { parseMermaidToExcalidraw } = await import("@excalidraw/mermaid-to-excalidraw");
  const { elements } = await parseMermaidToExcalidraw(mermaidText);
  process.stdout.write(JSON.stringify(expandSkeleton(elements)));
}

main().catch((error) => {
  process.stderr.write(`${error.stack ?? error}\n`);
  process.exit(1);
});
