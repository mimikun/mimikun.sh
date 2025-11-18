#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env

import $ from "@david/dax";

/**
 * Generate pip package list from pip freeze output
 * Cross-platform compatible implementation using deno-dax
 */
async function generatePipPackageList(): Promise<void> {
  try {
    // Get HOME directory (cross-platform)
    const homeDir = Deno.env.get("HOME") || Deno.env.get("USERPROFILE");
    if (!homeDir) {
      console.error("Error: HOME directory not found");
      Deno.exit(1);
    }

    // Determine output file name based on OS
    const isWindows = Deno.build.os === "windows";
    const outputFileName = isWindows
      ? "windows_pip_packages.txt"
      : "linux_pip_packages.txt";

    const outputDir = $.path(homeDir).join(".mimikun-pkglists");
    const outputFile = outputDir.join(outputFileName);

    // Ensure output directory exists
    await outputDir.ensureDir();

    // Run pip freeze and capture output
    const pipFreezeOutput = await $`pip freeze`.text();

    // Process the output:
    // 1. Split into lines
    // 2. Remove version info (=... or @...)
    // 3. Filter out empty lines
    // 4. Sort
    const packageNames = pipFreezeOutput
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line.length > 0)
      .map((line) => {
        // Remove =... and @... patterns
        return line.replace(/=.*/, "").replace(/ @.*/, "");
      })
      .filter((name) => name.length > 0)
      .sort((a, b) => a.localeCompare(b, "C"));

    // Write to output file
    await outputFile.writeText(packageNames.join("\n") + "\n");

    console.log(`✓ Generated pip package list: ${outputFile}`);
  } catch (error) {
    console.error("Error generating pip package list:", error);
    Deno.exit(1);
  }
}

// Run the main function
if (import.meta.main) {
  await generatePipPackageList();
}
