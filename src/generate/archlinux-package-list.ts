#!/usr/bin/env -S deno run --allow-read --allow-write --allow-run --allow-env

/**
 * @description Print a list of explicitly installed Arch Linux packages
 *
 * This script generates two package lists:
 * 1. Packages from the official repository
 * 2. Packages from the Arch User Repository (AUR)
 *
 * Both lists are sorted and saved to the ~/.mimikun-pkglists directory.
 */

import $ from "@david/dax";

async function main() {
  // Get home directory
  const homeDir = Deno.env.get("HOME");
  if (!homeDir) {
    console.error("Error: HOME environment variable is not set");
    Deno.exit(1);
  }

  // Create output directory if it doesn't exist
  const outputDir = `${homeDir}/.mimikun-pkglists`;
  await $`mkdir -p ${outputDir}`;

  try {
    // Generate list of packages from official repository
    console.log("Generating official repository package list...");
    const officialPackages = await $`sudo pacman -Qqen`.text();
    const sortedOfficialPackages = officialPackages
      .trim()
      .split("\n")
      .filter((line) => line.length > 0)
      .sort((a, b) => a.localeCompare(b, "C"))
      .join("\n");

    const officialPackagesFile = `${outputDir}/linux_arch_official_packages.txt`;
    await Deno.writeTextFile(
      officialPackagesFile,
      sortedOfficialPackages + "\n",
    );
    console.log(`✓ Saved to ${officialPackagesFile}`);

    // Generate list of packages from AUR
    console.log("Generating AUR package list...");
    const aurPackages = await $`sudo pacman -Qqem`.text();
    const sortedAurPackages = aurPackages
      .trim()
      .split("\n")
      .filter((line) => line.length > 0)
      .sort((a, b) => a.localeCompare(b, "C"))
      .join("\n");

    const aurPackagesFile = `${outputDir}/linux_arch_aur_packages.txt`;
    await Deno.writeTextFile(aurPackagesFile, sortedAurPackages + "\n");
    console.log(`✓ Saved to ${aurPackagesFile}`);

    console.log("\nPackage lists generated successfully!");
  } catch (error) {
    console.error("Error generating package lists:", error);
    Deno.exit(1);
  }
}

if (import.meta.main) {
  await main();
}
