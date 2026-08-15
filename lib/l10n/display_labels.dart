import '../features/measurements/domain/fun_weight_comparisons.dart';
import '../features/measurements/domain/measurement.dart';
import '../features/monetization/domain/access_status.dart';
import 'generated/app_localizations.dart';

String localizedScanUsage(AppLocalizations l10n, AccessStatus access) {
  if (!access.isAuthoritative) return l10n.accessLoadingBalance;
  if (!access.scanAccessEnforced) return l10n.accessPreview;
  return l10n.accessScansLeft(access.remainingScans);
}

String localizedCategory(AppLocalizations l10n, String value) =>
    switch (value) {
      'Food' => l10n.categoryFood,
      'Parcel' => l10n.categoryParcel,
      'Furniture' => l10n.categoryFurniture,
      'Electronics' => l10n.categoryElectronics,
      'Luggage' => l10n.categoryLuggage,
      'Tool' => l10n.categoryTool,
      'Clothing' => l10n.categoryClothing,
      'Household' => l10n.categoryHousehold,
      'Other' => l10n.categoryOther,
      _ => value,
    };

String localizedMaterial(AppLocalizations l10n, String value) =>
    switch (value) {
      'Unknown' => l10n.materialUnknown,
      'Plastic' => l10n.materialPlastic,
      'Metal' => l10n.materialMetal,
      'Glass/Ceramic' => l10n.materialGlassCeramic,
      'Wood' => l10n.materialWood,
      'Cardboard/Paper' => l10n.materialCardboardPaper,
      'Fabric' => l10n.materialFabric,
      'Food/Liquid' => l10n.materialFoodLiquid,
      'Mixed' => l10n.materialMixed,
      _ => value,
    };

String localizedFillState(AppLocalizations l10n, String value) =>
    switch (value) {
      'Unknown' => l10n.fillUnknown,
      'Solid' => l10n.fillSolid,
      'Empty' => l10n.fillEmpty,
      'Partly filled' => l10n.fillPartlyFilled,
      'Full' => l10n.fillFull,
      _ => value,
    };

String localizedReferenceObject(AppLocalizations l10n, String value) =>
    switch (value) {
      'None' => l10n.referenceNone,
      'Ruler' => l10n.referenceRuler,
      'Standard card' => l10n.referenceStandardCard,
      'Coin' => l10n.referenceCoin,
      _ => value,
    };

String localizedFunWeightUnit(AppLocalizations l10n, FunWeightUnit unit) =>
    switch (unit) {
      FunWeightUnit.aaBattery => l10n.funUnitAaBattery,
      FunWeightUnit.smartphone => l10n.funUnitSmartphone,
      FunWeightUnit.baguette => l10n.funUnitBaguette,
      FunWeightUnit.sodaCan => l10n.funUnitSodaCan,
      FunWeightUnit.soccerBall => l10n.funUnitSoccerBall,
      FunWeightUnit.cat => l10n.funUnitCat,
      FunWeightUnit.watermelon => l10n.funUnitWatermelon,
      FunWeightUnit.carTire => l10n.funUnitCarTire,
      FunWeightUnit.washingMachine => l10n.funUnitWashingMachine,
    };

String localizedFunWeightComparison(
  AppLocalizations l10n,
  FunWeightComparison comparison,
) =>
    comparison.parts
        .map((part) =>
            '≈ ${part.quantityText} × ${localizedFunWeightUnit(l10n, part.unit)}')
        .join(', ');

String localizedDimensionAxis(AppLocalizations l10n, String value) =>
    switch (value) {
      'Length' => l10n.axisLength,
      'Width' => l10n.axisWidth,
      'Height' => l10n.axisHeight,
      'Depth' => l10n.axisDepth,
      _ => value,
    };

String localizedConfidence(
  AppLocalizations l10n,
  ConfidenceLevel level, {
  bool includeConfidence = false,
}) => switch ((level, includeConfidence)) {
  (ConfidenceLevel.low, false) => l10n.confidenceLow,
  (ConfidenceLevel.medium, false) => l10n.confidenceMedium,
  (ConfidenceLevel.high, false) => l10n.confidenceHigh,
  (ConfidenceLevel.low, true) => l10n.confidenceLowLabel,
  (ConfidenceLevel.medium, true) => l10n.confidenceMediumLabel,
  (ConfidenceLevel.high, true) => l10n.confidenceHighLabel,
};
