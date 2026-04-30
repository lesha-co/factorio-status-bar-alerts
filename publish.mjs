#!/usr/bin/env node

import {
  readFileSync,
  mkdtempSync,
  symlinkSync,
  rmSync,
  statSync,
} from "node:fs";
import { execSync } from "node:child_process";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import assert from "node:assert";

// ── Paths ───────────────────────────────────────────────────────────────────
const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const MOD_DIR = join(SCRIPT_DIR, "macos-status-bar-alerts");
const ENV_FILE = join(SCRIPT_DIR, ".env");
const INFO_JSON = join(MOD_DIR, "info.json");

const MOD_PORTAL = "https://mods.factorio.com";
const INIT_UPLOAD_URL = `${MOD_PORTAL}/api/v2/mods/releases/init_upload`;
const INIT_PUBLISH_URL = `${MOD_PORTAL}/api/v2/mods/init_publish`;

// ── Colors ──────────────────────────────────────────────────────────────────
const GREEN = "\x1b[0;32m";
const NC = "\x1b[0m";

function info(msg) {
  console.log(`${GREEN}▸ ${msg}${NC}`);
}

// ── Load API key from .env ──────────────────────────────────────────────────
process.loadEnvFile(ENV_FILE);

const API_KEY = process.env.API_KEY;
assert(
  API_KEY,
  "API_KEY not found in .env. Add a line like: API_KEY=your_api_key_here",
);

// ── Read mod metadata from info.json ────────────────────────────────────────
const modInfo = JSON.parse(readFileSync(INFO_JSON, "utf-8"));

const MOD_NAME = modInfo.name;
const MOD_VERSION = modInfo.version;
assert(MOD_NAME, "Could not read 'name' from info.json");
assert(MOD_VERSION, "Could not read 'version' from info.json");

const ZIP_NAME = `${MOD_NAME}_${MOD_VERSION}.zip`;

info(`Mod:     ${MOD_NAME}`);
info(`Version: ${MOD_VERSION}`);
info(`Archive: ${ZIP_NAME}`);

// ── Build zip archive ───────────────────────────────────────────────────────
// Factorio expects: zip containing a top-level folder "modname_version/"
const tempDir = mkdtempSync(join(tmpdir(), "factorio-publish-"));
const linkName = `${MOD_NAME}_${MOD_VERSION}`;

try {
  symlinkSync(MOD_DIR, join(tempDir, linkName));

  info("Creating zip archive…");
  execSync(`zip -r "${ZIP_NAME}" "${linkName}"`, {
    cwd: tempDir,
    stdio: "pipe",
  });

  const zipPath = join(tempDir, ZIP_NAME);
  const zipSize = statSync(zipPath).size;
  info(`Archive created (${(zipSize / 1024).toFixed(1)} KB)`);

  // ── Check if mod already exists on the portal ───────────────────────────
  const checkRes = await fetch(`${MOD_PORTAL}/api/mods/${MOD_NAME}`);
  const isNewMod = checkRes.status === 404;

  if (isNewMod) {
    info("Mod not found on portal — will publish as new mod.");
  } else {
    info("Mod exists on portal — will upload new release.");
  }

  // ── Step 1: init_upload / init_publish ───────────────────────────────────
  const initURL = isNewMod ? INIT_PUBLISH_URL : INIT_UPLOAD_URL;
  info(`Initializing ${isNewMod ? "publish" : "upload"}…`);

  const initBody = new URLSearchParams({ mod: MOD_NAME });
  const initRes = await fetch(initURL, {
    method: "POST",
    headers: { Authorization: `Bearer ${API_KEY}` },
    body: initBody,
  });

  const initJson = await initRes.json();

  assert(
    initRes.ok && initJson.upload_url,
    `${isNewMod ? "init_publish" : "init_upload"} failed (HTTP ${initRes.status}): ${initJson.message ?? initJson.error ?? JSON.stringify(initJson)}`,
  );

  info("Upload URL received.");

  // ── Step 2: finish_upload ───────────────────────────────────────────────
  info(`Uploading ${ZIP_NAME}…`);

  const zipBuffer = readFileSync(zipPath);
  const zipFile = new File([zipBuffer], ZIP_NAME, {
    type: "application/zip",
  });

  const form = new FormData();
  form.append("file", zipFile);

  if (isNewMod && modInfo.description) {
    form.append("description", modInfo.description);
  }

  const uploadRes = await fetch(initJson.upload_url, {
    method: "POST",
    body: form,
  });

  const uploadJson = await uploadRes.json();

  assert(
    uploadRes.ok && uploadJson.success,
    `Upload failed (HTTP ${uploadRes.status}): ${uploadJson.message ?? uploadJson.error ?? JSON.stringify(uploadJson)}`,
  );

  console.log();
  info(
    `✅ Successfully published ${MOD_NAME} v${MOD_VERSION} to the Factorio mod portal!`,
  );
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}
