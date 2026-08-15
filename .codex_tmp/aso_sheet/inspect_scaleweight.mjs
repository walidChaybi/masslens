import fs from "node:fs/promises";
import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const inputPath = "/Users/walidchaybi/Downloads/scaleweight.xlsx";
const workbook = await SpreadsheetFile.importXlsx(await FileBlob.load(inputPath));

const overview = await workbook.inspect({
  kind: "workbook,sheet,table",
  maxChars: 12000,
  tableMaxRows: 20,
  tableMaxCols: 12,
  tableMaxCellChars: 160,
});
console.log("OVERVIEW");
console.log(overview.ndjson);

const sheets = workbook.worksheets.items;
for (const sheet of sheets) {
  const used = sheet.getUsedRange(true);
  console.log(`\nSHEET ${sheet.name}`);
  if (!used) {
    console.log("EMPTY");
    continue;
  }
  console.log(`USED ${used.address}`);
  const region = await workbook.inspect({
    kind: "region",
    sheetId: sheet.name,
    range: used.address,
    maxChars: 40000,
    tableMaxRows: 500,
    tableMaxCols: 24,
    tableMaxCellChars: 300,
  });
  console.log(region.ndjson);

  const preview = await workbook.render({
    sheetName: sheet.name,
    autoCrop: "all",
    scale: 1,
    format: "png",
  });
  const safeName = sheet.name.replace(/[^a-z0-9_-]+/gi, "_");
  await fs.writeFile(
    `.codex_tmp/aso_sheet/${safeName}.png`,
    new Uint8Array(await preview.arrayBuffer()),
  );
}
