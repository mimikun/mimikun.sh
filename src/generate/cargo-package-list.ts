#!/usr/bin/env -S deno run --allow-run --allow-env --allow-write --allow-read

import $ from "@david/dax";

/**
 * Generate a sorted list of installed Cargo packages
 * Cross-platform compatible (Windows/Linux) using deno-dax
 */
async function generateCargoPackageList(): Promise<void> {
  try {
    // Get the home directory
    const homeDir = Deno.env.get("HOME") ?? Deno.env.get("USERPROFILE");
    if (!homeDir) {
      throw new Error("Could not determine home directory");
    }

    // Ensure the output directory exists
    const outputDir = $.path(homeDir).join(".mimikun-pkglists");
    await outputDir.ensureDir();

    // Run cargo install-update --list and capture output
    const output = await $`cargo install-update --list`.text();

    // Process the output:
    // 1. Split into lines
    // 2. Skip first 3 lines (tail -n +4)
    // 3. Extract first column (package name)
    // 4. Remove empty lines
    // 5. Sort
    const lines = output.split("\n");
    const packages = lines
      .slice(3) // Skip first 3 lines
      .map((line) => line.trim().split(/\s+/)[0]) // Get first column
      .filter((pkg) => pkg && pkg.length > 0) // Remove empty lines
      .sort((a, b) => a.localeCompare(b, "en", { sensitivity: "base" })); // Sort (C locale equivalent)

    // Write to output file
    const outputFile = outputDir.join("linux_cargo_packages.txt");
    await Deno.writeTextFile(
      outputFile.toString(),
      packages.join("\n") + "\n"
    );

    console.log(`✓ Cargo package list generated at: ${outputFile}`);
  } catch (error) {
    console.error("Error generating cargo package list:", error);
    Deno.exit(1);
  }
}

// Run if executed directly
if (import.meta.main) {
  await generateCargoPackageList();
}
