// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MassLens';

  @override
  String get commonCancel => 'Cancel';

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
  String get onboardingAccessTitle => 'Three real AI scans are included.';

  @override
  String get onboardingAccessBody =>
      'MassLens checks your secure scan balance before analysis. Capturing or reviewing a photo never uses a scan.';

  @override
  String get onboardingAdsEyebrow => 'Ads support every scan';

  @override
  String get onboardingAdsTitle => 'No subscription. No scan packs.';

  @override
  String get onboardingAdsBody =>
      'After your included scans, finish one rewarded ad to add one real AI scan.';

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
      'Photograph an object to get an honest weight range, visual dimensions, and the evidence behind the estimate.';

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
      'We’re preparing your three starter scans and ad-supported access.';

  @override
  String get onboardingPreparingCta => 'Checking…';

  @override
  String get onboardingReadyTitle => 'You’re ready to scan';

  @override
  String get onboardingReadyBody => 'Your first 3 AI scans are included.';

  @override
  String get onboardingReadyCta => 'Let’s go';

  @override
  String get onboardingScanAccessLabel => 'Scan access';

  @override
  String get onboardingAdSupportLabel => 'Ad-supported';

  @override
  String get onboardingThreeStarterScans => '3 starter scans';

  @override
  String get onboardingPreparingStatus => 'Preparing…';

  @override
  String get onboardingReadyStatus => 'Ready';

  @override
  String get onboardingRetryStatus => 'Retry';

  @override
  String get homeAiWeight => 'AI weight';

  @override
  String homeScansLeftGetOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left · Get +1',
      one: '1 left · Get +1',
      zero: '0 left · Get +1',
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
  String get shellDigitalScale => 'Digital Scale';

  @override
  String get shellAiWeightScan => 'AI Weight Scan';

  @override
  String get shellHistory => 'History';

  @override
  String get shellCaptureGuide => 'Capture Guide';

  @override
  String get shellSettings => 'Settings';

  @override
  String get shellOpenNavigationMenu => 'Open navigation menu';

  @override
  String get shellChooseMode =>
      'Choose a physical scale or an AI photo estimate.';

  @override
  String get shellMeasurementNotice =>
      'Bluetooth readings are measurements. Touch mode is a simulator; AI scans are real visual estimates.';

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
  String get settingsBluetoothSupport => 'Bluetooth scale support';

  @override
  String get settingsStandardBle => 'Standard BLE WSS';

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
    return '$usage · watch one ad for one scan';
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
  String get settingsVersion => 'MVP 1.0.0';

  @override
  String get settingsSafetyBody =>
      'A compatible Bluetooth scale provides physical readings. Touch mode is an interactive simulator and AI scans are real visual estimates. Never use MassLens for medical dosing, legal trade, or other safety-critical decisions.';

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
  String get scanTryAnother => 'Try another';

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
  String get scaleWatchAdGetScan => 'Watch ad · Get +1 scan';

  @override
  String get scaleSimulatorStatus => 'SIMULATOR · NOT A MEASUREMENT';

  @override
  String get scaleLiveStatus => 'LIVE · BLUETOOTH SCALE';

  @override
  String get scaleDisconnectedStatus => 'BLUETOOTH · NOT CONNECTED';

  @override
  String get scaleSimulatorSemantics =>
      'Touch scale simulator, not a physical measurement';

  @override
  String get scaleLiveSemantics => 'Live Bluetooth scale reading';

  @override
  String get scaleDisconnectedSemantics => 'Bluetooth scale disconnected';

  @override
  String get scaleOpenNavigation => 'Open navigation menu';

  @override
  String get scaleOpenAiScan => 'AI weight scan';

  @override
  String get scaleBluetooth => 'Bluetooth scale';

  @override
  String get scaleGenericDevice => 'Bluetooth weight scale';

  @override
  String get scaleUnit => 'UNIT';

  @override
  String get scaleTare => 'TARE';

  @override
  String get scaleCloseBluetooth => 'Close Bluetooth panel';

  @override
  String get scaleReceivingMeasurements =>
      'Receiving standard Weight Scale measurements';

  @override
  String get scaleBleSupport => 'Supports BLE Weight Scale Service (0x181D)';

  @override
  String get scaleDisconnect => 'Disconnect scale';

  @override
  String get scaleSearching => 'Searching…';

  @override
  String get scaleFindCompatible => 'Find compatible scales';

  @override
  String get scaleAvailableScales => 'AVAILABLE SCALES';

  @override
  String get scaleCompatible => 'Compatible scale';

  @override
  String scaleSignal(int rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get scaleNoneFound =>
      'No standard scale found. Make sure the scale is awake and not connected to another app, then try again.';

  @override
  String get scalePrivateProtocolNotice =>
      'Many kitchen scales use private manufacturer protocols. Those need a model-specific integration even if they appear in phone Bluetooth settings.';

  @override
  String get scalePermissionNeeded =>
      'Nearby devices permission is required to find a scale.';

  @override
  String get scalePowerOnBluetooth => 'Turn on Bluetooth, then search again.';

  @override
  String get scaleCommunicationFailed =>
      'Could not communicate with this scale.';

  @override
  String get scalePhaseIdle => 'No scale connected';

  @override
  String get scalePhasePermission => 'Requesting permission';

  @override
  String get scalePhaseScanning => 'Searching nearby';

  @override
  String get scalePhaseConnecting => 'Connecting';

  @override
  String get scalePhaseDiscovering => 'Checking compatibility';

  @override
  String get scalePhaseSubscribing => 'Starting live readings';

  @override
  String get scalePhaseConnected => 'Scale connected';

  @override
  String get scalePhaseDisconnecting => 'Disconnecting';

  @override
  String get scalePhaseUnavailable => 'Bluetooth unavailable';

  @override
  String get scalePhaseError => 'Connection needs attention';

  @override
  String get scalePhaseClosed => 'Reader closed';

  @override
  String get rewardAdsFundAnalysis => 'Ads fund real AI analysis';

  @override
  String get rewardHeadline => 'Watch one ad. Get one scan.';

  @override
  String get rewardBody =>
      'Finish the ad and MassLens adds one scan. No subscription, purchase, or fabricated result.';

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
  String get rewardCreditStillSyncing => 'The scan credit is still syncing.';

  @override
  String get rewardNoCreditAdded => 'No pending scan credit was added.';

  @override
  String get accessLoadingBalance => 'Loading scan balance…';

  @override
  String get accessPreview => 'Access preview';

  @override
  String accessScansLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans left',
      one: '1 scan left',
      zero: 'No scans available',
    );
    return '$_temp0';
  }

  @override
  String accessScansAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans available',
      one: '1 scan available',
      zero: 'No scans available',
    );
    return '$_temp0';
  }

  @override
  String accessBreakdown(int starter, int rewarded, int legacy) {
    return '$starter starter · $rewarded rewarded · $legacy legacy';
  }

  @override
  String get accessStarterThenAd => '3 starter scans, then watch an ad';

  @override
  String get accessGetOne => 'Get +1';

  @override
  String get nativeSponsored => 'Sponsored content';

  @override
  String get nativeTestLoading => 'Sponsored · test ad loading…';

  @override
  String get nativeTestRetrying => 'Test ad retrying…';
}
