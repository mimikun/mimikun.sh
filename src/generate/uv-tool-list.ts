#!/usr/bin/env -S deno run -A

import { $ } from "@david/dax";

/**
 * Generate UV tool list for Linux/Windows cross-platform
 * Saves the list of installed UV tools to ~/.mimikun-pkglists/linux_uv_tools.txt
 */
async function main() {
  try {
    // Get HOME directory (cross-platform)
    const homeDir = Deno.env.get("HOME") || Deno.env.get("USERPROFILE");
    if (!homeDir) {
      throw new Error("HOME or USERPROFILE environment variable not found");
    }

    // Ensure the output directory exists
    const outputDir = `${homeDir}/.mimikun-pkglists`;
    await $.path(outputDir).ensureDir();

    // Execute uv tool list command
    const output = await $`uv tool list`.text();

    // Process the output:
    // 1. Filter lines containing version patterns (v[0-9])
    // 2. Extract the first word (tool name) from each line
    // 3. Sort the results
    const toolList = output
      .split("\n")
      .filter((line) => /v[0-9]/.test(line)) // grep "v[0-9]"
      .map((line) => line.split(/\s+/)[0]) // sed -e "s/\s.*//g" (remove space and after)
      .filter((name) => name.length > 0) // Remove empty lines
      .sort(); // LC_ALL=C sort

    // Write to output file
    const outputFile = `${outputDir}/linux_uv_tools.txt`;
    await Deno.writeTextFile(outputFile, toolList.join("\n") + "\n");

    console.log(`Successfully generated UV tool list: ${outputFile}`);
    console.log(`Total tools: ${toolList.length}`);
  } catch (error) {
    console.error("Error generating UV tool list:", error.message);
    Deno.exit(1);
  }
}

// Run main function
if (import.meta.main) {
  await main();
}
