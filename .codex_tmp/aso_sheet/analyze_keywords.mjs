import { FileBlob, SpreadsheetFile } from "@oai/artifact-tool";

const workbook = await SpreadsheetFile.importXlsx(
  await FileBlob.load("/Users/walidchaybi/Downloads/scaleweight.xlsx"),
);
const sheet = workbook.worksheets.getItem("data");
const values = sheet.getRange("A1:H609").values;
const rows = values.slice(1).map((row, index) => ({
  excelRow: index + 2,
  keyword: String(row[0] ?? "").trim(),
  traffic: Number(row[1] ?? 0),
  efficiency: Number(row[3] ?? 0),
  rank: Number(row[4] ?? 0),
  date: String(row[5] ?? ""),
  suggested: String(row[6] ?? ""),
  category: String(row[7] ?? ""),
}));

const topTraffic = rows
  .filter((row) => row.traffic > 0)
  .sort((a, b) => b.traffic - a.traffic || a.rank - b.rank)
  .slice(0, 120);

const opportunityPattern =
  /scale|weight|weigh|gram|ounce|kg|kilo|food|kitchen|phone|mobile|balance|balanza|b[aá]scula|pes[ao]|mass|item|object|bluetooth|smart|luggage|postage/i;
const lowTrafficOpportunities = rows
  .filter(
    (row) =>
      row.traffic === 0 &&
      row.rank > 0 &&
      row.rank <= 5 &&
      opportunityPattern.test(row.keyword),
  )
  .sort((a, b) => a.rank - b.rank || a.keyword.localeCompare(b.keyword))
  .slice(0, 160);

const clusters = {
  coreScale: /^(scale|weight scale|digital scale|scale app|phone scale)$/i,
  gramScale: /gram|ounce|mg scale|milligram/i,
  phoneIntent: /phone|mobile|screen|app|android/i,
  foodKitchen: /food|kitchen|cooking|postage|luggage/i,
  bluetooth: /bluetooth|smart scale|bt weight/i,
  estimation: /estimate|estimator|item weight|object|mass/i,
  spanish: /balanza|b[aá]scula|pesa|pesar|gramera/i,
};

const clusterSummary = Object.fromEntries(
  Object.entries(clusters).map(([name, regex]) => {
    const matches = rows.filter((row) => regex.test(row.keyword));
    return [
      name,
      {
        count: matches.length,
        positiveTraffic: matches.reduce(
          (sum, row) => sum + Math.max(0, row.traffic),
          0,
        ),
        top: matches
          .sort((a, b) => b.traffic - a.traffic || a.rank - b.rank)
          .slice(0, 20),
      },
    ];
  }),
);

console.log(
  JSON.stringify(
    {
      rowCount: rows.length,
      positiveTrafficCount: rows.filter((row) => row.traffic > 0).length,
      suggestedYesCount: rows.filter((row) => row.suggested === "Yes").length,
      topTraffic,
      clusters: clusterSummary,
      lowTrafficOpportunities,
    },
    null,
    2,
  ),
);
