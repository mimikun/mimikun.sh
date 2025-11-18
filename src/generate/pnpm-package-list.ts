#!/usr/bin/env -S deno run --allow-run --allow-write --allow-read --allow-env
/**
 * Generate a list of globally installed pnpm packages
 * Cross-platform compatible implementation using deno-dax
 */

import $ from "jsr:@david/dax@0.42.0";

async function main() {
  try {
    // Get user's home directory
    const homeDir = Deno.env.get("HOME") || Deno.env.get("USERPROFILE");
    if (!homeDir) {
      console.error("Error: Could not determine home directory");
      Deno.exit(1);
    }

    // Create output directory if it doesn't exist
    const outputDir = `${homeDir}/.mimikun-pkglists`;
    await $`mkdir -p ${outputDir}`.quiet();

    // Get global pnpm packages as JSON
    const pnpmOutput = await $`pnpm list --global --json`.text();

    // Parse JSON and extract package names
    const packageData = JSON.parse(pnpmOutput);
    const packageNames: string[] = [];

    // Extract dependencies from the JSON structure
    if (Array.isArray(packageData)) {
      for (const item of packageData) {
        if (item.dependencies) {
          packageNames.push(...Object.keys(item.dependencies));
        }
      }
    }

    // Sort package names (locale-independent sort for consistency)
    const sortedPackages = packageNames.sort((a, b) => a.localeCompare(b, "en", { sensitivity: "base" }));

    // Write to output file
    const outputFile = `${outputDir}/linux_pnpm_packages.txt`;
    await Deno.writeTextFile(outputFile, sortedPackages.join("\n") + "\n");

    console.log(`Successfully generated package list: ${outputFile}`);
    console.log(`Total packages: ${sortedPackages.length}`);
  } catch (error) {
    console.error("Error generating pnpm package list:", error.message);
    Deno.exit(1);
  }
}

if (import.meta.main) {
  main();
}
