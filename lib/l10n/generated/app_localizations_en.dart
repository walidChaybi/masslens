// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MassLens: Photo Estimates';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonDone => 'Done';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaved => 'Saved';

  @override
  String get commonShare => 'Share';

  @override
  String get commonStartOver => 'Start over';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get confidenceLow => 'Low';

  @override
  String get confidenceMedium => 'Medium';

  @override
  String get confidenceHigh => 'High';

  @override
  String get confidenceLowLabel => 'Low confidence';

  @override
  String get confidenceMediumLabel => 'Medium confidence';

  @override
  String get confidenceHighLabel => 'High confidence';

  @override
  String get measurementToday => 'Today';

  @override
  String measurementTodayAt(String time) {
    return 'Today, $time';
  }

  @override
  String get measurementYesterday => 'Yesterday';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryParcel => 'Parcel';

  @override
  String get categoryFurniture => 'Furniture';

  @override
  String get categoryElectronics => 'Electronics';

  @override
  String get categoryLuggage => 'Luggage';

  @override
  String get categoryTool => 'Tool';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryHousehold => 'Household';

  @override
  String get categoryOther => 'Other';

  @override
  String get materialUnknown => 'Unknown';

  @override
  String get materialPlastic => 'Plastic';

  @override
  String get materialMetal => 'Metal';

  @override
  String get materialGlassCeramic => 'Glass/Ceramic';

  @override
  String get materialWood => 'Wood';

  @override
  String get materialCardboardPaper => 'Cardboard/Paper';

  @override
  String get materialFabric => 'Fabric';

  @override
  String get materialFoodLiquid => 'Food/Liquid';

  @override
  String get materialMixed => 'Mixed';

  @override
  String get fillUnknown => 'Unknown';

  @override
  String get fillSolid => 'Solid';

  @override
  String get fillEmpty => 'Empty';

  @override
  String get fillPartlyFilled => 'Partly filled';

  @override
  String get fillFull => 'Full';

  @override
  String get referenceNone => 'None';

  @override
  String get referenceRuler => 'Ruler';

  @override
  String get referenceStandardCard => 'Standard card';

  @override
  String get referenceCoin => 'Coin';

  @override
  String get scanReferenceTip =>
      'Tip: for best accuracy, place a coin (or a card) next to the object.';

  @override
  String get funUnitAaBattery => 'AA battery';

  @override
  String get funUnitSmartphone => 'smartphone';

  @override
  String get funUnitBaguette => 'baguette';

  @override
  String get funUnitSodaCan => 'soda can';

  @override
  String get funUnitSoccerBall => 'soccer ball';

  @override
  String get funUnitCat => 'cat';

  @override
  String get funUnitWatermelon => 'watermelon';

  @override
  String get funUnitCarTire => 'car tire';

  @override
  String get funUnitWashingMachine => 'washing machine';

  @override
  String get axisLength => 'Length';

  @override
  String get axisWidth => 'Width';

  @override
  String get axisHeight => 'Height';

  @override
  String get axisDepth => 'Depth';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingStartScanning => 'Start scanning';

  @override
  String get onboardingNoAccountNeeded => 'No account needed';

  @override
  String get onboardingSavedHistoryControl => 'You control saved history';

  @override
  String get onboardingResponsibleEstimates =>
      'Designed for responsible estimates';

  @override
  String get onboardingPrivateBadge => 'Private';

  @override
  String get onboardingInstantBadge => 'Instant';

  @override
  String onboardingStepOfTotal(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingVisualEyebrow => 'Visual estimation';

  @override
  String get onboardingVisualTitle => 'Estimate what you cannot weigh.';

  @override
  String get onboardingVisualBody =>
      'Capture an object and get a useful weight range, AI-assumed size, and the assumptions behind the estimate.';

  @override
  String get onboardingHonestEyebrow => 'Honest by design';

  @override
  String get onboardingHonestTitle => 'A range, not a made-up exact number.';

  @override
  String get onboardingHonestBody =>
      'MassLens shows confidence and uncertainty because a photograph is an estimate—not a physical scale.';

  @override
  String get onboardingPrivateEyebrow => 'Private first';

  @override
  String get onboardingPrivateTitle => 'Your objects stay yours.';

  @override
  String get onboardingPrivateBody =>
      'Photos are stripped of metadata and sent securely for real AI analysis. Saved history remains private on your device.';

  @override
  String get onboardingAccessEyebrow => 'Scan access';

  @override
  String get onboardingAccessTitle => 'Two real AI scans are included.';

  @override
  String get onboardingAccessBody =>
      'MassLens checks your secure scan balance before analysis. Capturing or reviewing a photo never uses a scan.';

  @override
  String get onboardingAdsEyebrow => 'Scan access options';

  @override
  String get onboardingAdsTitle => '2 free scans, then 1 scan per ad';

  @override
  String get onboardingAdsBody =>
      'Get two real AI scans free. After that, watch one rewarded ad for one scan, or unlock unlimited scans and remove ads with a one-time lifetime purchase.';

  @override
  String get onboardingAccessPreparing => 'Preparing scan access…';

  @override
  String get onboardingAccessReady => 'Scan access ready';

  @override
  String get onboardingAccessRetry => 'Retry scan access';

  @override
  String get onboardingAccessUnavailable =>
      'Scan access is unavailable. Check your connection and try again.';

  @override
  String get onboardingHeroTitle => 'Know more at a glance';

  @override
  String get onboardingHeroBody =>
      'Estimate an object’s likely weight range from visible features. Photos cannot measure actual weight or reveal hidden contents.';

  @override
  String get onboardingHeroCta => 'Get started';

  @override
  String get onboardingFramingTitle => 'Keep the whole object visible';

  @override
  String get onboardingFramingBody =>
      'Leave clear space around every edge and avoid hands or clutter covering the object.';

  @override
  String get onboardingFramingCta => 'Next';

  @override
  String get onboardingLightTitle => 'Bright light, simple background';

  @override
  String get onboardingLightBody =>
      'Good lighting and a steady photo help AI recognize shape and material more accurately.';

  @override
  String get onboardingLightCta => 'Continue';

  @override
  String get onboardingPreparingTitle => 'Almost ready';

  @override
  String get onboardingPreparingBody =>
      'Preparing your two free scans and rewarded-ad access.';

  @override
  String get onboardingPreparingCta => 'Checking…';

  @override
  String get onboardingReadyTitle => 'You’re ready to scan';

  @override
  String get onboardingReadyBody => 'Your first 2 AI scans are free.';

  @override
  String get onboardingReadyCta => 'Let’s go';

  @override
  String get onboardingReviewTitle => 'Help MassLens grow';

  @override
  String get onboardingReviewBody =>
      'Would you like to leave an honest review on Google Play? It takes a moment and helps us improve.';

  @override
  String get onboardingReviewLater => 'Not now';

  @override
  String get onboardingReviewAction => 'Review app';

  @override
  String get onboardingScanAccessLabel => 'Scan access';

  @override
  String get onboardingAdSupportLabel => 'Ad-supported';

  @override
  String get onboardingThreeStarterScans => '2 free scans';

  @override
  String get onboardingPreparingStatus => 'Preparing…';

  @override
  String get onboardingReadyStatus => 'Ready';

  @override
  String get onboardingRetryStatus => 'Retry';

  @override
  String get homeAiWeight => 'Photo estimate';

  @override
  String homeScansLeftGetOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Get free scan',
      one: 'Get free scan',
      zero: 'Get free scan',
    );
    return '$_temp0';
  }

  @override
  String get homeLatestEstimate => 'Latest estimate';

  @override
  String get homeHistory => 'History';

  @override
  String get homeScanObject => 'Scan object';

  @override
  String get homePhoto => 'Photo';

  @override
  String get homeModeObject => 'Object';

  @override
  String get homeModeFoodMacros => 'Food & macros';

  @override
  String get homeFoodModeHint =>
      'Photograph one whole plate to estimate each food\'s weight, calories and macros.';

  @override
  String get homeScanFood => 'Scan food plate';

  @override
  String get nutritionHomeTitle => 'Nutrition & Trends';

  @override
  String get nutritionHomeBody =>
      'Track daily calories and macros on this device';

  @override
  String nutritionHomeTodayCalories(int count) {
    return '$count kcal logged today';
  }

  @override
  String get shellAiWeightScan => 'Photo estimates';

  @override
  String get shellNutrition => 'Nutrition';

  @override
  String get shellHistory => 'History';

  @override
  String get shellCaptureGuide => 'Capture Guide';

  @override
  String get shellSettings => 'Settings';

  @override
  String get shellOpenNavigationMenu => 'Open navigation menu';

  @override
  String get shellChooseMode => 'Photo estimates and your nutrition diary.';

  @override
  String get shellMeasurementNotice =>
      'Photo results are uncertain estimates. The phone does not measure weight. Use a physical scale for measurements.';

  @override
  String get shellExitTitle => 'Exit MassLens?';

  @override
  String get shellExitBody => 'Are you sure you want to exit the app?';

  @override
  String get navScanShort => 'AI Scan';

  @override
  String get navGuideShort => 'Guide';

  @override
  String get homeHeroTitle => 'Explore an object from a photo';

  @override
  String get homeHeroBody =>
      'Get an approximate weight range from visible features. A photo cannot measure weight or reveal hidden contents.';

  @override
  String get homeTipWhole => 'Whole object';

  @override
  String get homeTipLight => 'Good light';

  @override
  String get homeTipReference => 'Size reference';

  @override
  String get nutritionEyebrow => 'Private daily log';

  @override
  String get nutritionTitle => 'Nutrition & Trends';

  @override
  String get nutritionLocalBadge => 'On device';

  @override
  String get nutritionDayTab => 'Day';

  @override
  String get nutritionTrendsTab => 'Trends';

  @override
  String get nutritionPreviousDay => 'Previous day';

  @override
  String get nutritionNextDay => 'Next day';

  @override
  String get nutritionToday => 'Today';

  @override
  String get nutritionCaloriesUnit => 'kcal';

  @override
  String nutritionKcal(String value) {
    return '$value kcal';
  }

  @override
  String nutritionGrams(String value) {
    return '$value g';
  }

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbohydrates';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionProteinShort => 'P';

  @override
  String get nutritionCarbsShort => 'C';

  @override
  String get nutritionFatShort => 'F';

  @override
  String nutritionMacroCompact(int protein, int carbs, int fat) {
    return 'P $protein g · C $carbs g · F $fat g';
  }

  @override
  String nutritionMacroRingSemantics(
    int calories,
    int protein,
    int carbs,
    int fat,
  ) {
    return '$calories calories, $protein grams protein, $carbs grams carbohydrates, and $fat grams fat';
  }

  @override
  String get nutritionPartialNotice =>
      'Partial total: at least one food had no complete USDA nutrition match.';

  @override
  String get nutritionTrendPartialNotice =>
      'This period includes partial totals from food scans with unmatched components.';

  @override
  String get nutritionPartialShort => 'Partial';

  @override
  String get nutritionMealsTitle => 'Meals';

  @override
  String get nutritionAddFood => 'Add food';

  @override
  String get nutritionNoEntriesTitle => 'Nothing logged for this day';

  @override
  String get nutritionNoEntriesBody =>
      'Add a saved food estimate or enter calories and macros manually.';

  @override
  String get nutritionFromScans => 'From Food Scans';

  @override
  String get nutritionFromScansBody =>
      'Copy corrected nutrition from a saved food plate';

  @override
  String get nutritionManual => 'Manual entry';

  @override
  String get nutritionManualBody =>
      'Enter a meal\'s calories and macros yourself';

  @override
  String get nutritionNoScansTitle => 'No food scans available';

  @override
  String get nutritionNoScansBody =>
      'Save a Food & macros scan containing USDA nutrition, then return here to log it.';

  @override
  String get nutritionChooseScan => 'Choose a saved food scan';

  @override
  String get nutritionAddFromScanTitle => 'Add scanned meal';

  @override
  String get nutritionAddManualTitle => 'Add nutrition manually';

  @override
  String get nutritionEditEntryTitle => 'Edit nutrition entry';

  @override
  String get nutritionBreakfast => 'Breakfast';

  @override
  String get nutritionLunch => 'Lunch';

  @override
  String get nutritionDinner => 'Dinner';

  @override
  String get nutritionSnack => 'Snack';

  @override
  String get nutritionMeal => 'Meal';

  @override
  String get nutritionLabel => 'Food or meal name';

  @override
  String get nutritionWeightOptional => 'Weight (optional)';

  @override
  String get nutritionCaloriesInput => 'Calories';

  @override
  String get nutritionRequiredLabel => 'Enter a food or meal name.';

  @override
  String get nutritionInvalidNumber => 'Enter a valid positive number.';

  @override
  String get nutritionAtLeastOneValue =>
      'Enter calories or at least one macro value.';

  @override
  String get nutritionFutureDate => 'Nutrition cannot be logged in the future.';

  @override
  String get nutritionEdit => 'Edit';

  @override
  String get nutritionEntryActions => 'Nutrition entry actions';

  @override
  String get nutritionDeleteTitle => 'Delete nutrition entry?';

  @override
  String nutritionDeleteBody(String label) {
    return 'Remove “$label” from the local nutrition log?';
  }

  @override
  String get nutritionTrendsTitle => 'Nutrition overview';

  @override
  String get nutritionSevenDays => '7 days';

  @override
  String get nutritionThirtyDays => '30 days';

  @override
  String get nutritionAverageLoggedDays => 'Average kcal on logged days';

  @override
  String get nutritionLoggedDays => 'Logged days';

  @override
  String get nutritionCaloriesTrend => 'Daily calories';

  @override
  String get nutritionMacroTrend => 'Macro trend (grams)';

  @override
  String nutritionCaloriesChartSemantics(int days, int calories) {
    return 'Calories chart for $days days with $calories total calories';
  }

  @override
  String nutritionMacrosChartSemantics(int days) {
    return 'Protein, carbohydrate, and fat trend chart for $days days';
  }

  @override
  String get nutritionDisclaimer =>
      'Stored only on this device. Nutrition values are approximate and are not medical advice or dietary guidance.';

  @override
  String get nutritionScanAMeal => 'Scan a meal';

  @override
  String get nutritionOpenGallery => 'Choose from gallery';

  @override
  String get nutritionRemainingLabel => 'remaining';

  @override
  String nutritionEatenKcal(String value) {
    return '$value eaten';
  }

  @override
  String nutritionOverGoal(String value) {
    return '$value over goal';
  }

  @override
  String get nutritionStreakZero => 'Start a streak';

  @override
  String nutritionStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-day streak',
      one: '1-day streak',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDailyGoals => 'Daily goals';

  @override
  String get nutritionCalorieGoal => 'Daily calories';

  @override
  String get nutritionEmptyTitle => 'Log your first meal';

  @override
  String get nutritionEmptyBody =>
      'Photograph a plate to estimate calories and macros. Values are approximate USDA matches, not medical advice.';

  @override
  String get nutritionSaveToToday => 'Save to today';

  @override
  String get nutritionSaveHistoryOnly => 'Save to history only';

  @override
  String get nutritionScanLoggedMessage => 'Added to today’s meals';

  @override
  String get nutritionScanReviewTitle => 'Frame the whole plate';

  @override
  String get nutritionScanReviewBody => 'Confirm the whole meal is visible';

  @override
  String get nutritionScanWholePlate => 'Whole plate';

  @override
  String get nutritionHomeHint => 'Food logging lives in Nutrition';

  @override
  String get nutritionMoreActions => 'More';

  @override
  String get nutritionGoalsSave => 'Save goals';

  @override
  String nutritionOfGoalGrams(String consumed, String goal) {
    return '$consumed / $goal g';
  }

  @override
  String get nutritionEditGoals => 'Edit daily goals';

  @override
  String get guideEyebrow => 'Better input, better range';

  @override
  String get guideTitle => 'Capture guide';

  @override
  String get guideIntro =>
      'Four simple choices make a visual estimate more useful.';

  @override
  String get guideWholeObjectTitle => 'Show the whole object';

  @override
  String get guideWholeObjectBody =>
      'Leave space around every edge. Avoid hands, labels, or other objects overlapping the target.';

  @override
  String get guideLightingTitle => 'Use soft, even light';

  @override
  String get guideLightingBody =>
      'Strong shadows hide shape. Bright daylight or a well-lit room usually gives the cleanest visual evidence.';

  @override
  String get guideStructureTitle => 'Tell us solid or hollow';

  @override
  String get guideStructureBody =>
      'A suitcase and a block can occupy the same volume but weigh very differently. Structure narrows the density assumption.';

  @override
  String get guideSideViewTitle => 'Add a side view';

  @override
  String get guideSideViewBody =>
      'Move 45–90° around the same object. A second view helps AI infer shape, construction, and volume.';

  @override
  String get guideUnderstandingConfidence => 'Understanding confidence';

  @override
  String get guideTryCapture => 'Try a guided capture';

  @override
  String get guideClearSubject => 'Clear subject';

  @override
  String get guideAllEdgesVisible => 'ALL EDGES VISIBLE  •  SINGLE OBJECT';

  @override
  String get guideLowDetail => 'One photo, inferred scale or category';

  @override
  String get guideMediumDetail => 'Category plus structure confirmed';

  @override
  String get guideHighDetail => 'Two clear angles plus useful object details';

  @override
  String get historyEyebrow => 'Private on-device log';

  @override
  String get historyTitle => 'Estimate history';

  @override
  String get historyNewEstimate => 'New estimate';

  @override
  String get historyAll => 'All';

  @override
  String get historyNothingSaved => 'Nothing saved yet';

  @override
  String historyNoCategoryEstimates(String category) {
    return 'No $category estimates';
  }

  @override
  String get historyEmptyBody =>
      'Save a result after your first photo estimate and it will appear here.';

  @override
  String get historyFilteredEmptyBody =>
      'Choose another filter or make a new estimate.';

  @override
  String get historyStartEstimate => 'Start estimate';

  @override
  String get historySavedStat => 'Saved';

  @override
  String get historyCategoriesStat => 'Categories';

  @override
  String get historyLocalBadge => 'Local';

  @override
  String get detailDeleteTitle => 'Delete this estimate?';

  @override
  String get detailDeleteBody =>
      'The saved result and its private image copy will be removed.';

  @override
  String get detailSavedEstimate => 'Saved estimate';

  @override
  String get detailDeleteTooltip => 'Delete estimate';

  @override
  String get detailAiEstimate => 'AI estimate';

  @override
  String get detailEstimatedWeight => 'ESTIMATED WEIGHT';

  @override
  String get detailLikelyRange => 'Likely range';

  @override
  String get detailAiVisualSize => 'AI visual size';

  @override
  String get detailDimensionOrder =>
      'Length × width × height · visual assumption';

  @override
  String get detailAssumptions => 'Assumptions';

  @override
  String get detailSafetyNotice =>
      'This is an informed visual estimate, not a sensor reading. Do not use it for safety-critical decisions.';

  @override
  String get settingsEyebrow => 'Preferences and privacy';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsMeasurement => 'Measurement';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsUnitsBody =>
      'All values are stored canonically in metric.';

  @override
  String get settingsMetric => 'Metric';

  @override
  String get settingsImperial => 'Imperial';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeBody => 'Follow your device, or pin light or dark.';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsHelp => 'Help';

  @override
  String get settingsReplayWalkthrough => 'Replay the walkthrough';

  @override
  String get settingsReplayWalkthroughBody =>
      'See the capture tips from the first launch again.';

  @override
  String get settingsRateApp => 'Rate this app';

  @override
  String get settingsRateAppBody => 'Leave a rating on Google Play.';

  @override
  String get settingsRateAppUnavailable =>
      'Google Play is unavailable right now.';

  @override
  String get settingsEngine => 'Engine';

  @override
  String get settingsAnalysisMode => 'Analysis mode';

  @override
  String get settingsAnalysisSecureCloudAi => 'Secure cloud AI';

  @override
  String get settingsCloudUploads => 'Cloud uploads';

  @override
  String get settingsCloudViaSecureApi => 'Via secure API';

  @override
  String get settingsProductionModel => 'Production model';

  @override
  String get settingsScanCredits => 'Scan credits';

  @override
  String get settingsEarnAiScans => 'Earn AI scans';

  @override
  String settingsEarnAiScansBody(String usage) {
    return '$usage · Watch one ad for one scan';
  }

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsSavedPhotos => 'Saved photos';

  @override
  String get settingsPrivateStorage => 'Private storage';

  @override
  String get settingsAdPrivacyChoices => 'Ad privacy choices';

  @override
  String get settingsReviewConsent => 'Review or change consent';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacyPolicyBody =>
      'How photos, local history, AI analysis and USDA food searches are handled';

  @override
  String get settingsPrivacyPolicyUnavailable =>
      'Add the privacy-policy URL in the release configuration.';

  @override
  String get settingsPrivacyPolicyOpenFailed =>
      'The privacy policy could not be opened.';

  @override
  String get legalTitle => 'Legal';

  @override
  String get legalSettingsBody =>
      'Privacy policy, Terms of Use, and data handling';

  @override
  String get legalIntroTitle => 'Clear, honest policies';

  @override
  String get legalIntroBody =>
      'How MassLens handles your data and the rules that apply when you use the app.';

  @override
  String get legalPrivacyPolicy => 'Privacy policy';

  @override
  String get legalTermsOfUse => 'Terms of use';

  @override
  String get legalLastUpdated => '21 Aug 2026';

  @override
  String get legalPublishedPolicy => 'View published privacy policy';

  @override
  String get legalFooter => 'MassLens · Legal documents';

  @override
  String get legalPrivacyScopeTitle => 'Scope and who provides MassLens';

  @override
  String get legalPrivacyScopeBody =>
      'MassLens is provided by the developer identified on its Google Play listing (\"we\", \"us\", or \"our\"). This policy explains how information is handled in the MassLens Android app and its scan service. MassLens does not require an account and does not directly ask for your name, email address, profile, or precise location.';

  @override
  String get legalPrivacyPhotosTitle => 'Photos and AI analysis';

  @override
  String get legalPrivacyPhotosBody =>
      'A photo is processed only when you choose Camera or Gallery and start an AI scan. Before upload, MassLens corrects orientation, resizes the image, re-encodes it as JPEG, and removes embedded EXIF and GPS metadata. The photo, an optional second angle, and scan context are sent over HTTPS through the MassLens Cloudflare service to OpenAI to identify visible objects or food and estimate weight ranges. OpenAI is instructed not to store the response. Photos are not stored in the MassLens Worker database.';

  @override
  String get legalPrivacyNutritionTitle => 'Food scans and USDA data';

  @override
  String get legalPrivacyNutritionBody =>
      'For Food & macros scans, the AI returns food labels, approximate weight ranges, and generic English search terms; it does not create nutrient values. The server sends only normalized food search text to USDA FoodData Central to find calories and macros. USDA never receives your photos, installation identifier, or local history. All food weights, calories, and macros are estimates and may be incomplete.';

  @override
  String get legalPrivacyLocalTitle => 'Information stored on your device';

  @override
  String get legalPrivacyLocalBody =>
      'Scan results and a private image copy are saved only when you choose Save. Preferences, scan history, and nutrition diary entries are stored on your device. Nutrition entries are added only when you import a saved food scan or enter values manually; they are not uploaded. Android backup behavior may depend on your device settings.';

  @override
  String get legalPrivacyServiceTitle => 'Service data and retention';

  @override
  String get legalPrivacyServiceBody =>
      'MassLens transmits device or other IDs off the device. It creates a random installation identifier—not an IMEI, serial number, or hardware MAC—and sends it to the MassLens service to manage starter scans, rewarded scan credits, lifetime purchase verification, retries, and abuse prevention. The service hashes it before database use and records request identifiers, credit state, reward state, purchase tokens for lifetime unlocks, limited technical events, and anonymous daily totals such as completed scan mode and AI cost. A completed result JSON, never the photo, may be retained for up to 24 hours for idempotent retries. Credit, purchase, and anti-abuse records are kept as needed to operate those features. Hosting and network providers may process IP addresses and routine security logs.';

  @override
  String get legalPrivacyAdsTitle => 'Advertising and consent';

  @override
  String get legalPrivacyAdsBody =>
      'MassLens uses Google Mobile Ads (AdMob) for rewarded scan credits and other ad placements. Google and its advertising partners collect and share device or other IDs, including the Android advertising ID and App Set ID, plus device information, approximate location derived from IP address, diagnostics, consent choices, and ad interactions, for advertising, analytics, and fraud prevention under their own policies. Where required, the app requests consent. You can reset the advertising ID in Android settings. If Google makes privacy options available for you, they can be reviewed from Settings.';

  @override
  String get legalPrivacySharingTitle =>
      'Service providers, transfers, and sale';

  @override
  String get legalPrivacySharingBody =>
      'Information is shared only as needed with Cloudflare for API delivery, OpenAI for photo analysis, USDA FoodData Central for generic nutrition searches, and Google for advertising and consent. These providers may process information in countries other than yours under their own terms and safeguards. MassLens does not sell your local scan history or nutrition diary and does not use them for user-level nutrition advertising or analytics.';

  @override
  String get legalPrivacyChoicesTitle => 'Your choices and deletion';

  @override
  String get legalPrivacyChoicesBody =>
      'You can deny camera permission, use the manual nutrition diary without AI, cancel before analysis, decline to save results, delete individual scans, clear estimate history, clear the nutrition diary separately, review ad privacy choices, or uninstall the app. Uninstalling removes app-local data subject to Android backup settings. For other privacy requests, use the developer contact on the Google Play listing. Do not send photos or sensitive health information.';

  @override
  String get legalPrivacySecurityTitle => 'Security and children';

  @override
  String get legalPrivacySecurityBody =>
      'MassLens uses HTTPS, metadata removal, hashed installation identifiers, and access controls designed to reduce risk. No storage or internet transmission can be guaranteed completely secure. MassLens is not directed to children below the minimum digital-consent age in their country, and we do not knowingly request personal profiles from children.';

  @override
  String get legalPrivacyChangesTitle => 'Changes and contact';

  @override
  String get legalPrivacyChangesBody =>
      'This policy may change when MassLens, applicable law, or its service providers change. The last-updated date will be revised for material updates. The published HTTPS version linked above is the version intended for the Google Play listing. Questions may be sent using the developer contact shown on that listing.';

  @override
  String get legalTermsAcceptanceTitle => 'Acceptance and eligibility';

  @override
  String get legalTermsAcceptanceBody =>
      'By installing or using MassLens, you agree to these Terms of Use and the Privacy Policy. If you do not agree, do not use the app. You must be legally able to accept these terms where you live; otherwise, a parent or legal guardian must review and accept them for you. You are responsible for complying with applicable laws.';

  @override
  String get legalTermsServiceTitle => 'What the service provides';

  @override
  String get legalTermsServiceBody =>
      'MassLens provides AI-assisted visual estimates for objects and food plates, USDA-based approximate nutrition, local history, and an optional local nutrition diary. Photo analysis requires internet access and scan access. Some functions require permissions or ad availability.';

  @override
  String get legalTermsEstimatesTitle => 'Estimates, nutrition, and safety';

  @override
  String get legalTermsEstimatesBody =>
      'AI scans are visual estimates, not physical scale readings. Results may be inaccurate, incomplete, or unsuitable for a particular item or meal. MassLens is not a medical device and does not provide medical, dietary, allergy, dosing, legal-trade, shipping, or safety advice. Never rely on it for medication, regulated commerce, allergens, hazardous materials, or other safety-critical decisions. Use a calibrated scale or qualified professional when accuracy matters.';

  @override
  String get legalTermsContentTitle => 'Your photos and acceptable use';

  @override
  String get legalTermsContentBody =>
      'You keep your rights in photos and information you submit. You give MassLens and its necessary service providers a limited permission to process them only to deliver the requested scan, maintain security, and provide retries as described in the Privacy Policy. You must have the right to use submitted images. Do not submit illegal content, intimate imagery, confidential documents, images that violate another person\'s privacy or rights, malicious code, or content unrelated to legitimate object or food analysis.';

  @override
  String get legalTermsCreditsTitle => 'Scan credits and advertising';

  @override
  String get legalTermsCreditsBody =>
      'A new installation may receive a limited number of starter scans. A completed rewarded advertisement may grant a scan credit after confirmation by the app and service. A one-time Google Play purchase may unlock unlimited scans and remove ads for that Google account on supported devices, subject to fair-use limits and refund rules described by Google Play. Credits and lifetime access have no cash value, cannot be transferred between accounts, and may be limited to prevent abuse. Ad availability is not guaranteed. Failed qualifying scans are normally refunded, but access may be delayed by outages, fraud checks, purchase verification, or technical errors. Advertising formats, credit rules, and pricing may change with reasonable notice.';

  @override
  String get legalTermsThirdPartyTitle => 'Local data and third-party services';

  @override
  String get legalTermsThirdPartyBody =>
      'Saved results and nutrition entries are stored locally and may be lost if you delete them, clear app data, uninstall, change devices, or lose the device. You are responsible for any backup you require. MassLens relies on services from Cloudflare, OpenAI, USDA FoodData Central, Google Mobile Ads, Google Play, and device manufacturers. Their services, content, and availability are governed by their own terms; MassLens does not control them.';

  @override
  String get legalTermsLicenseTitle => 'License and intellectual property';

  @override
  String get legalTermsLicenseBody =>
      'You receive a limited, personal, revocable, non-exclusive, non-transferable license to use MassLens for lawful, non-commercial purposes. The app, design, code, branding, and original materials remain the property of their respective owners. You may not copy, sell, sublicense, reverse engineer except where law expressly permits, bypass security or credit controls, overload the service, scrape it, or use it to build a competing dataset or service.';

  @override
  String get legalTermsAvailabilityTitle => 'Availability, changes, and misuse';

  @override
  String get legalTermsAvailabilityBody =>
      'MassLens may change, suspend, or discontinue features to improve the app, address security or legal requirements, manage costs, or respond to third-party changes. Continuous, error-free availability is not promised. Access may be limited or blocked when reasonably necessary to prevent fraud, automated abuse, attacks, unlawful use, or harm to the service or others.';

  @override
  String get legalTermsLiabilityTitle =>
      'Disclaimers and limitation of liability';

  @override
  String get legalTermsLiabilityBody =>
      'To the fullest extent permitted by law, MassLens is provided \"as is\" and \"as available\" without warranties of accuracy, fitness for a particular purpose, uninterrupted operation, or error-free results. The developer is not liable for indirect, incidental, special, consequential, or exemplary losses arising from reliance on estimates, loss of local data, third-party services, ads, or inability to use the app. Nothing in these terms excludes rights or liability that cannot legally be excluded in your country.';

  @override
  String get legalTermsChangesTitle => 'Updates, severability, and contact';

  @override
  String get legalTermsChangesBody =>
      'These terms may be updated when MassLens or applicable requirements change. Continuing to use the app after an update takes effect means you accept the revised terms where permitted by law. If one provision is unenforceable, the remaining provisions continue to apply. Applicable mandatory consumer law remains unaffected. For questions or legal notices, use the developer contact details on the MassLens Google Play listing.';

  @override
  String get settingsClearHistory => 'Clear estimate history';

  @override
  String get settingsNoSavedEstimates => 'No saved estimates';

  @override
  String settingsSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved',
      one: '1 saved',
      zero: 'No saved estimates',
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsClearHistoryTitle => 'Clear all history?';

  @override
  String settingsClearHistoryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count saved estimates and their private image copies will be deleted from this device.',
      one:
          '1 saved estimate and its private image copy will be deleted from this device.',
      zero: 'No saved estimates or private image copies will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearHistoryAction => 'Clear history';

  @override
  String get settingsHistoryCleared => 'Estimate history cleared.';

  @override
  String get settingsClearNutrition => 'Clear nutrition history';

  @override
  String get settingsNoNutritionEntries => 'No nutrition entries';

  @override
  String settingsNutritionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nutrition entries',
      one: '1 nutrition entry',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionTitle => 'Clear nutrition history?';

  @override
  String settingsClearNutritionBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'All $count nutrition entries stored on this device will be deleted. Saved scans are unchanged.',
      one:
          'The nutrition entry stored on this device will be deleted. Saved scans are unchanged.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionAction => 'Clear nutrition';

  @override
  String get settingsNutritionCleared => 'Nutrition history cleared.';

  @override
  String get settingsVersion => 'Version 1.1.0';

  @override
  String get settingsSafetyBody =>
      'Photos provide uncertain visual estimates, not measurements. Use a physical scale when accuracy matters. Never use MassLens for medical dosing, legal trade, or safety-critical decisions.';

  @override
  String get cameraUnavailable => 'Camera is unavailable.';

  @override
  String get cameraAccessNeeded =>
      'Camera access is needed to photograph the object.';

  @override
  String get cameraUnavailableDevice => 'Camera is unavailable on this device.';

  @override
  String get cameraCaptureFailed =>
      'The photo could not be captured. Try again.';

  @override
  String get cameraCloseTooltip => 'Close';

  @override
  String get cameraTorchOffTooltip => 'Turn torch off';

  @override
  String get cameraTorchOnTooltip => 'Turn torch on';

  @override
  String get cameraTakePhotoSemantics => 'Take photo';

  @override
  String get scanCameraOpenFailed => 'The camera could not be opened.';

  @override
  String get scanSelectedPhotoOpenFailed =>
      'The selected photo could not be opened.';

  @override
  String get scanSecondPhotoOpenFailed =>
      'The second photo could not be opened.';

  @override
  String get scanDimensionPositive => 'Enter a dimension greater than zero.';

  @override
  String get scanAccessUnverified =>
      'Scan access could not be verified. Check the connection and try again; no scan was used.';

  @override
  String get scanLimitReached => 'You have used your available scans.';

  @override
  String get scanAnalysisStopped =>
      'Analysis stopped. Check the connection and try again.';

  @override
  String get scanCoachTitle => 'Scan Coach';

  @override
  String get scanCoachNoCredit =>
      'No scan is used until you continue to analysis.';

  @override
  String get scanCoachRetake => 'Retake';

  @override
  String get scanCoachUseAnyway => 'Use anyway';

  @override
  String get scanSavedPrivateHistory => 'Saved to your private history.';

  @override
  String get scanOptionalDetails => 'Optional details';

  @override
  String get scanMaterial => 'Material';

  @override
  String get scanFill => 'Fill';

  @override
  String get scanKnownSize => 'Known size (optional)';

  @override
  String get scanVisibleReference => 'Visible reference';

  @override
  String get scanEstimate => 'Estimate';

  @override
  String get scanAnalyzing => 'Analyzing';

  @override
  String get scanNewEstimate => 'New estimate';

  @override
  String get scanReview => 'Review';

  @override
  String get scanPhotographObject => 'Photograph an object';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanChooseGallery => 'Choose from gallery';

  @override
  String get scanConfirmObject => 'Confirm the object';

  @override
  String get scanDetails => 'Details';

  @override
  String get scanAddSideView => 'Add side view';

  @override
  String get scanSideViewAdded => 'Side view added';

  @override
  String get scanSideViewOptional =>
      'Optional · move 45–90° around the same object';

  @override
  String get scanSideViewBenefit =>
      'Another angle helps AI infer shape and volume';

  @override
  String get scanAdd => 'Add';

  @override
  String get scanReplace => 'Replace';

  @override
  String get scanRemoveSideView => 'Remove side view';

  @override
  String get scanProgressShape => 'Reading shape';

  @override
  String get scanProgressMaterial => 'Estimating material';

  @override
  String get scanProgressRange => 'Building range';

  @override
  String get scanLikelyRange => 'LIKELY RANGE';

  @override
  String get scanAiVisualSize => 'AI visual size · L × W × H';

  @override
  String get scanConfidence => 'Confidence';

  @override
  String get scanHowEstimated => 'How this was estimated';

  @override
  String get scanTryAnother => 'Scan another';

  @override
  String get scanSecondViewTitle => 'Add a side view';

  @override
  String get scanSecondViewBody =>
      'Move 45–90° around the same object and keep the whole object visible. This uses the same scan credit.';

  @override
  String get scanChoosePhoto => 'Choose photo';

  @override
  String get scanPhotoDarkWarning =>
      'The photo is dark. More even light will improve material recognition.';

  @override
  String get scanPhotoBlurryWarning =>
      'The photo looks blurry. Hold the phone steady and keep the object sharp.';

  @override
  String get scanPhotoMissing => 'The photo could not be found.';

  @override
  String get scanPhotoCorrupt =>
      'This photo is corrupt or unsupported. Retake it as a JPEG image.';

  @override
  String get scanPhotoTooSmall =>
      'This photo is too small. Use an image at least 320 × 320 pixels.';

  @override
  String get scanCloudFailure =>
      'The AI analysis could not be completed. Check the connection and try again; no fabricated result was created.';

  @override
  String get scanNoFoodDetected =>
      'No visible food was found. Try again with one whole plate in frame; the scan was refunded.';

  @override
  String get scanNutritionUnavailable =>
      'USDA nutrition data is temporarily unavailable. Try again later; the scan was refunded.';

  @override
  String get scanNutritionNoMatch =>
      'No complete USDA nutrition match was found for this meal. Try a clearer photo; the scan was refunded.';

  @override
  String get scanFoodScale => 'Food estimates';

  @override
  String get scanPhotographMeal => 'Photograph one whole plate';

  @override
  String get scanConfirmMeal => 'Confirm the whole meal is visible';

  @override
  String get scanAnalyzeMeal => 'Analyze food & macros';

  @override
  String get scanFoodOptionalDetails => 'Optional plate details';

  @override
  String get scanContainer => 'Container type';

  @override
  String get scanContainerUnknown => 'Unknown';

  @override
  String get scanContainerPlate => 'Plate';

  @override
  String get scanContainerBowl => 'Bowl';

  @override
  String get scanContainerCup => 'Cup';

  @override
  String get scanContainerTray => 'Tray';

  @override
  String get scanContainerNone => 'No container';

  @override
  String get scanPlateDiameter => 'Plate or bowl diameter (optional)';

  @override
  String get scanFoodReferenceTip =>
      'A visible coin, card, ruler, or known plate diameter can narrow the weight range.';

  @override
  String get scanProgressIdentifyFood => 'Identifying visible foods…';

  @override
  String get scanProgressMatchUsda => 'Matching USDA nutrition data…';

  @override
  String get scanProgressNutrition => 'Calculating calories and macros…';

  @override
  String get scanFoodTotalWeight => 'Estimated net food weight';

  @override
  String get scanFoodComponents => 'Food components';

  @override
  String get scanNutrition => 'Nutrition';

  @override
  String get scanCalories => 'Calories';

  @override
  String get scanProtein => 'Protein';

  @override
  String get scanCarbs => 'Carbs';

  @override
  String get scanFat => 'Fat';

  @override
  String get scanEditAmount => 'Correct amount';

  @override
  String get scanRemoveItem => 'Remove false detection';

  @override
  String get scanAmountGrams => 'Amount in grams';

  @override
  String get scanOriginalAiRange => 'Original AI range';

  @override
  String get scanUsdaSource => 'USDA source';

  @override
  String get scanNutritionMissing =>
      'Weight only — no complete USDA nutrition match';

  @override
  String get scanPartialTotal => 'Partial total';

  @override
  String get scanCompleteTotal => 'Complete total';

  @override
  String get scanFoodDisclaimer =>
      'Approximate photo-based estimate. Not a medical device or dietary advice.';

  @override
  String get scanFoodEditTitle => 'Correct food amount';

  @override
  String get scanFoodEditBody =>
      'Nutrition totals will use your amount; the original AI range stays visible.';

  @override
  String get scanFoodAmountPositive => 'Enter an amount greater than zero.';

  @override
  String get scanFoodAtLeastOne => 'Keep at least one food component.';

  @override
  String get scanRemove => 'Remove';

  @override
  String get rewardAdsFundAnalysis => 'Choose how to unlock scans';

  @override
  String get rewardHeadline => 'Get more AI scans';

  @override
  String get rewardBody =>
      'Watch one rewarded ad for one scan, or unlock unlimited scans and remove ads with a one-time purchase.';

  @override
  String rewardMaxBalance(int count) {
    return 'Max $count';
  }

  @override
  String get rewardSyncPending => 'Scan credit sync pending';

  @override
  String get rewardSafeToClose =>
      'Safe to close. We will keep checking for 24 hours.';

  @override
  String get rewardChecking => 'Checking';

  @override
  String get rewardCheck => 'Check';

  @override
  String get rewardAdding => 'Adding your scan…';

  @override
  String rewardAnotherAdMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return 'Another ad in $_temp0';
  }

  @override
  String rewardAnotherAdSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sec',
      one: '1 sec',
    );
    return 'Another ad in $_temp0';
  }

  @override
  String get rewardUnavailable => 'Rewarded ads unavailable';

  @override
  String get rewardWatchForOne => 'Watch an ad · Get 1 scan';

  @override
  String get rewardLoading => 'Rewarded ad is loading';

  @override
  String get rewardUseLegacyFirst =>
      'Use your ad-free scan credit before earning more scans.';

  @override
  String get rewardAccessStateUnavailable =>
      'Rewarded ads are not available for this access state.';

  @override
  String get rewardConsentUnavailable =>
      'Ads are unavailable because of consent or configuration. Existing scans and non-AI features remain available.';

  @override
  String get rewardPrivacyChoices => 'Privacy choices';

  @override
  String get rewardTryLoadingAgain => 'Try loading again';

  @override
  String get rewardUnlockUnlimited => 'Unlock unlimited';

  @override
  String get drawerUpgradeUnlimited => 'Upgrade to Unlimited';

  @override
  String get rewardCreditStillSyncing => 'The scan credit is still syncing.';

  @override
  String get rewardNoCreditAdded => 'No pending scan credit was added.';

  @override
  String get accessLoadingBalance => 'Loading…';

  @override
  String get accessPreview => 'Access preview';

  @override
  String accessScansLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans',
      one: '1 scan',
    );
    return '$_temp0';
  }

  @override
  String accessScansAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans',
      one: '1 scan',
    );
    return '$_temp0';
  }

  @override
  String accessBreakdown(int starter, int rewarded, int legacy) {
    return '$starter starter · $rewarded rewarded · $legacy legacy';
  }

  @override
  String get accessStarterThenAd => '2 free scans, then 1 scan per ad';

  @override
  String get accessGetOne => 'Get +1';

  @override
  String get accessUnlimitedScans => 'Unlimited scans';

  @override
  String get accessLifetimeActive => 'Lifetime unlock active';

  @override
  String accessBuyLifetime(String price) {
    return 'Unlock unlimited · $price';
  }

  @override
  String get accessRestorePurchases => 'Restore purchases';

  @override
  String get accessLifetimeUnlocked =>
      'Lifetime access is active on this device.';

  @override
  String get accessLifetimeLoadingPrice => 'Loading store price…';

  @override
  String get paywallEyebrow => 'Real AI photo analysis';

  @override
  String get paywallHeadline => 'Photo estimates.';

  @override
  String get paywallHeadlineAccent => 'Unlock';

  @override
  String get paywallHeadlineRest => 'Explore with AI.';

  @override
  String get paywallHeroSubtitle =>
      'Explore visible objects and food from photos.\nApproximate estimates, not weight measurements.';

  @override
  String get paywallSocialProof => 'Pay once · keep forever';

  @override
  String get paywallSocialSubline => 'Unlimited AI scans. Zero ads.';

  @override
  String get paywallUnlockLifetime => 'Unlock lifetime access';

  @override
  String paywallTrustPriced(String price) {
    return 'One-time purchase · $price';
  }

  @override
  String get paywallOneTimeCaption => 'One-time payment';

  @override
  String get paywallLuggageLabel => 'Luggage scan';

  @override
  String get paywallLuggageTitle => 'Carry-on suitcase';

  @override
  String get paywallLuggageWeight => '2–4 kg';

  @override
  String get paywallLuggageConfidence => 'Illustrative estimate';

  @override
  String get paywallFeatureHeading =>
      'SMALL THINGS. BIG EVERYDAY POSSIBILITIES.';

  @override
  String get paywallFeatureUnlimited => 'Unlimited scans';

  @override
  String get paywallFeatureNoAds => 'No ads';

  @override
  String get paywallFeatureNutrition => 'Know more about your plate';

  @override
  String get paywallFeatureNutritionSub =>
      'Estimated calories, protein & macros';

  @override
  String get paywallFeatureLuggage => 'Object estimates';

  @override
  String get paywallFeatureLuggageSub =>
      'Visible features only; contents are unknown';

  @override
  String get paywallFeatureObjects => 'Point. Snap. Estimate.';

  @override
  String get paywallFeatureObjectsSub =>
      'Approximate ranges from visible features';

  @override
  String get paywallPhotoScanLabel => 'AI PHOTO SCAN';

  @override
  String get paywallEstimateExample => 'AI estimate · example';

  @override
  String get paywallIllustrativeReadings =>
      'Illustrations only. Photos cannot measure actual weight.';

  @override
  String get paywallLifetimeOffer => 'Lifetime access · No ads';

  @override
  String get paywallPurchaseTrust => 'Pay once. No subscription. Google Play.';

  @override
  String get paywallTerms => 'Terms';

  @override
  String get paywallPrivacy => 'Privacy';

  @override
  String get paywallFeatureLifetime => 'Unlimited + ad-free';

  @override
  String get paywallFeatureLifetimeSub => 'Unlock once. Own it.';

  @override
  String get paywallOneTimeBadge => 'One-time';

  @override
  String get paywallLifetimePlan => 'Lifetime access';

  @override
  String get paywallContinueFree => 'Continue with free scans';

  @override
  String get paywallPurchaseUnavailable => 'Purchase unavailable';

  @override
  String get nativeSponsored => 'Sponsored content';

  @override
  String get nativeTestLoading => 'Sponsored · test ad loading…';

  @override
  String get nativeTestRetrying => 'Test ad retrying…';

  @override
  String get accessGetFreeScan => 'Get free scan';

  @override
  String get settingsReminders => 'Reminders';

  @override
  String get mealReminderTitle => 'Daily meal reminder';

  @override
  String mealReminderOnBody(String time) {
    return 'Every day at $time, unless you just logged a meal';
  }

  @override
  String get mealReminderOffBody => 'Get one nudge a day to log your meals';

  @override
  String get mealReminderTime => 'Reminder time';

  @override
  String get mealReminderPermissionDenied =>
      'Notifications are blocked. Allow them for MassLens in your phone settings.';

  @override
  String mealReminderEnabled(String time) {
    return 'Reminder set for $time every day.';
  }

  @override
  String get mealReminderPromptTitle => 'Keep your streak going';

  @override
  String get mealReminderPromptBody =>
      'Get one daily reminder to log your meals. You can change the time anytime in Settings.';

  @override
  String get mealReminderPromptAction => 'Turn on reminder';

  @override
  String get mealReminderPromptDismiss => 'Not now';

  @override
  String get mealReminderNotificationTitle => 'Time to log your meal';

  @override
  String get mealReminderNotificationBody =>
      'Snap your plate in MassLens to track calories and keep your streak.';

  @override
  String get mealReminderChannelName => 'Meal reminders';

  @override
  String get barcodeScanAction => 'Scan a barcode';

  @override
  String get barcodeScanActionBody =>
      'Packaged foods · free, no scan credit used';

  @override
  String get barcodeFreeBadge => 'FREE';

  @override
  String get barcodeScannerHint => 'Center the barcode inside the frame';

  @override
  String get barcodeTypeNumber => 'Type the number';

  @override
  String get barcodeTorch => 'Flashlight';

  @override
  String get barcodeEnterTitle => 'Enter the barcode number';

  @override
  String get barcodeInvalid => 'Enter a valid 8, 12 or 13-digit barcode.';

  @override
  String get barcodeLookingUp => 'Looking up the product…';

  @override
  String get barcodeNotFoundTitle => 'Product not found';

  @override
  String barcodeNotFoundBody(String code) {
    return 'Barcode $code isn\'t in Open Food Facts or USDA FoodData Central yet. You can enter the values from the label.';
  }

  @override
  String get barcodeUnavailableTitle => 'Couldn\'t look up this product';

  @override
  String get barcodeUnavailableBody => 'Check your connection and try again.';

  @override
  String get barcodeRetry => 'Try again';

  @override
  String get barcodeEnterManually => 'Enter manually';

  @override
  String get barcodeScanAgain => 'Scan again';

  @override
  String barcodePer100(String unit) {
    return 'Per 100 $unit';
  }

  @override
  String barcodeServing(String amount) {
    return '1 serving · $amount';
  }

  @override
  String barcodeWholePack(String amount) {
    return 'Whole pack · $amount';
  }

  @override
  String get barcodeYourPortion => 'Your portion';

  @override
  String get barcodeAmountEaten => 'Amount eaten';

  @override
  String get barcodePartialNutrition =>
      'Some macros are missing from this product\'s data and count as 0.';

  @override
  String get barcodeAddToDiary => 'Add to diary';

  @override
  String get barcodeSourceOpenFoodFacts =>
      'Label data from Open Food Facts (ODbL). Check the package: values can be incomplete or out of date.';

  @override
  String get barcodeSourceUsda =>
      'Label data from USDA FoodData Central. Check the package: values can be incomplete or out of date.';

  @override
  String get barcodeRecentTitle => 'Recent products';

  @override
  String get barcodeRecentBody => 'Log a product you scanned before';

  @override
  String barcodeKcalPer100(String value, String unit) {
    return '$value kcal / 100 $unit';
  }
}
