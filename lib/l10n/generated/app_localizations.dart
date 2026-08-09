import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MassLens'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @commonStartOver.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get commonStartOver;

  /// No description provided for @commonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknown;

  /// No description provided for @confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get confidenceLow;

  /// No description provided for @confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get confidenceMedium;

  /// No description provided for @confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get confidenceHigh;

  /// No description provided for @confidenceLowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get confidenceLowLabel;

  /// No description provided for @confidenceMediumLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get confidenceMediumLabel;

  /// No description provided for @confidenceHighLabel.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get confidenceHighLabel;

  /// No description provided for @measurementToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get measurementToday;

  /// No description provided for @measurementTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String measurementTodayAt(String time);

  /// No description provided for @measurementYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get measurementYesterday;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel'**
  String get categoryParcel;

  /// No description provided for @categoryFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get categoryFurniture;

  /// No description provided for @categoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get categoryElectronics;

  /// No description provided for @categoryLuggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get categoryLuggage;

  /// No description provided for @categoryTool.
  ///
  /// In en, this message translates to:
  /// **'Tool'**
  String get categoryTool;

  /// No description provided for @categoryClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// No description provided for @categoryHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get categoryHousehold;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @materialUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get materialUnknown;

  /// No description provided for @materialPlastic.
  ///
  /// In en, this message translates to:
  /// **'Plastic'**
  String get materialPlastic;

  /// No description provided for @materialMetal.
  ///
  /// In en, this message translates to:
  /// **'Metal'**
  String get materialMetal;

  /// No description provided for @materialGlassCeramic.
  ///
  /// In en, this message translates to:
  /// **'Glass/Ceramic'**
  String get materialGlassCeramic;

  /// No description provided for @materialWood.
  ///
  /// In en, this message translates to:
  /// **'Wood'**
  String get materialWood;

  /// No description provided for @materialCardboardPaper.
  ///
  /// In en, this message translates to:
  /// **'Cardboard/Paper'**
  String get materialCardboardPaper;

  /// No description provided for @materialFabric.
  ///
  /// In en, this message translates to:
  /// **'Fabric'**
  String get materialFabric;

  /// No description provided for @materialFoodLiquid.
  ///
  /// In en, this message translates to:
  /// **'Food/Liquid'**
  String get materialFoodLiquid;

  /// No description provided for @materialMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get materialMixed;

  /// No description provided for @fillUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get fillUnknown;

  /// No description provided for @fillSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get fillSolid;

  /// No description provided for @fillEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get fillEmpty;

  /// No description provided for @fillPartlyFilled.
  ///
  /// In en, this message translates to:
  /// **'Partly filled'**
  String get fillPartlyFilled;

  /// No description provided for @fillFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fillFull;

  /// No description provided for @referenceNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get referenceNone;

  /// No description provided for @referenceRuler.
  ///
  /// In en, this message translates to:
  /// **'Ruler'**
  String get referenceRuler;

  /// No description provided for @referenceStandardCard.
  ///
  /// In en, this message translates to:
  /// **'Standard card'**
  String get referenceStandardCard;

  /// No description provided for @axisLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get axisLength;

  /// No description provided for @axisWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get axisWidth;

  /// No description provided for @axisHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get axisHeight;

  /// No description provided for @axisDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get axisDepth;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStartScanning.
  ///
  /// In en, this message translates to:
  /// **'Start scanning'**
  String get onboardingStartScanning;

  /// No description provided for @onboardingNoAccountNeeded.
  ///
  /// In en, this message translates to:
  /// **'No account needed'**
  String get onboardingNoAccountNeeded;

  /// No description provided for @onboardingSavedHistoryControl.
  ///
  /// In en, this message translates to:
  /// **'You control saved history'**
  String get onboardingSavedHistoryControl;

  /// No description provided for @onboardingResponsibleEstimates.
  ///
  /// In en, this message translates to:
  /// **'Designed for responsible estimates'**
  String get onboardingResponsibleEstimates;

  /// No description provided for @onboardingPrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get onboardingPrivateBadge;

  /// No description provided for @onboardingInstantBadge.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get onboardingInstantBadge;

  /// No description provided for @onboardingStepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepOfTotal(int current, int total);

  /// No description provided for @onboardingVisualEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Visual estimation'**
  String get onboardingVisualEyebrow;

  /// No description provided for @onboardingVisualTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate what you cannot weigh.'**
  String get onboardingVisualTitle;

  /// No description provided for @onboardingVisualBody.
  ///
  /// In en, this message translates to:
  /// **'Capture an object and get a useful weight range, AI-assumed size, and the assumptions behind the estimate.'**
  String get onboardingVisualBody;

  /// No description provided for @onboardingHonestEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Honest by design'**
  String get onboardingHonestEyebrow;

  /// No description provided for @onboardingHonestTitle.
  ///
  /// In en, this message translates to:
  /// **'A range, not a made-up exact number.'**
  String get onboardingHonestTitle;

  /// No description provided for @onboardingHonestBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens shows confidence and uncertainty because a photograph is an estimate—not a physical scale.'**
  String get onboardingHonestBody;

  /// No description provided for @onboardingPrivateEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Private first'**
  String get onboardingPrivateEyebrow;

  /// No description provided for @onboardingPrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Your objects stay yours.'**
  String get onboardingPrivateTitle;

  /// No description provided for @onboardingPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Photos are stripped of metadata and sent securely for real AI analysis. Saved history remains private on your device.'**
  String get onboardingPrivateBody;

  /// No description provided for @onboardingAccessEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Scan access'**
  String get onboardingAccessEyebrow;

  /// No description provided for @onboardingAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Three real AI scans are included.'**
  String get onboardingAccessTitle;

  /// No description provided for @onboardingAccessBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens checks your secure scan balance before analysis. Capturing or reviewing a photo never uses a scan.'**
  String get onboardingAccessBody;

  /// No description provided for @onboardingAdsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Ads support every scan'**
  String get onboardingAdsEyebrow;

  /// No description provided for @onboardingAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscription. No scan packs.'**
  String get onboardingAdsTitle;

  /// No description provided for @onboardingAdsBody.
  ///
  /// In en, this message translates to:
  /// **'After your included scans, finish one rewarded ad to add one real AI scan.'**
  String get onboardingAdsBody;

  /// No description provided for @onboardingAccessPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing scan access…'**
  String get onboardingAccessPreparing;

  /// No description provided for @onboardingAccessReady.
  ///
  /// In en, this message translates to:
  /// **'Scan access ready'**
  String get onboardingAccessReady;

  /// No description provided for @onboardingAccessRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry scan access'**
  String get onboardingAccessRetry;

  /// No description provided for @onboardingAccessUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Scan access is unavailable. Check your connection and try again.'**
  String get onboardingAccessUnavailable;

  /// No description provided for @onboardingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Know more at a glance'**
  String get onboardingHeroTitle;

  /// No description provided for @onboardingHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Photograph an object to get an honest weight range, visual dimensions, and the evidence behind the estimate.'**
  String get onboardingHeroBody;

  /// No description provided for @onboardingHeroCta.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingHeroCta;

  /// No description provided for @onboardingFramingTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the whole object visible'**
  String get onboardingFramingTitle;

  /// No description provided for @onboardingFramingBody.
  ///
  /// In en, this message translates to:
  /// **'Leave clear space around every edge and avoid hands or clutter covering the object.'**
  String get onboardingFramingBody;

  /// No description provided for @onboardingFramingCta.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingFramingCta;

  /// No description provided for @onboardingLightTitle.
  ///
  /// In en, this message translates to:
  /// **'Bright light, simple background'**
  String get onboardingLightTitle;

  /// No description provided for @onboardingLightBody.
  ///
  /// In en, this message translates to:
  /// **'Good lighting and a steady photo help AI recognize shape and material more accurately.'**
  String get onboardingLightBody;

  /// No description provided for @onboardingLightCta.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingLightCta;

  /// No description provided for @onboardingPreparingTitle.
  ///
  /// In en, this message translates to:
  /// **'Almost ready'**
  String get onboardingPreparingTitle;

  /// No description provided for @onboardingPreparingBody.
  ///
  /// In en, this message translates to:
  /// **'We’re preparing your three starter scans and ad-supported access.'**
  String get onboardingPreparingBody;

  /// No description provided for @onboardingPreparingCta.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get onboardingPreparingCta;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You’re ready to scan'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your first 3 AI scans are included.'**
  String get onboardingReadyBody;

  /// No description provided for @onboardingReadyCta.
  ///
  /// In en, this message translates to:
  /// **'Let’s go'**
  String get onboardingReadyCta;

  /// No description provided for @onboardingScanAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Scan access'**
  String get onboardingScanAccessLabel;

  /// No description provided for @onboardingAdSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Ad-supported'**
  String get onboardingAdSupportLabel;

  /// No description provided for @onboardingThreeStarterScans.
  ///
  /// In en, this message translates to:
  /// **'3 starter scans'**
  String get onboardingThreeStarterScans;

  /// No description provided for @onboardingPreparingStatus.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get onboardingPreparingStatus;

  /// No description provided for @onboardingReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get onboardingReadyStatus;

  /// No description provided for @onboardingRetryStatus.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onboardingRetryStatus;

  /// No description provided for @homeAiWeight.
  ///
  /// In en, this message translates to:
  /// **'AI weight'**
  String get homeAiWeight;

  /// No description provided for @homeScansLeftGetOne.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 left · Get +1} =1{1 left · Get +1} other{{count} left · Get +1}}'**
  String homeScansLeftGetOne(int count);

  /// No description provided for @homeLatestEstimate.
  ///
  /// In en, this message translates to:
  /// **'Latest estimate'**
  String get homeLatestEstimate;

  /// No description provided for @homeHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get homeHistory;

  /// No description provided for @homeScanObject.
  ///
  /// In en, this message translates to:
  /// **'Scan object'**
  String get homeScanObject;

  /// No description provided for @homePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get homePhoto;

  /// No description provided for @shellDigitalScale.
  ///
  /// In en, this message translates to:
  /// **'Digital Scale'**
  String get shellDigitalScale;

  /// No description provided for @shellAiWeightScan.
  ///
  /// In en, this message translates to:
  /// **'AI Weight Scan'**
  String get shellAiWeightScan;

  /// No description provided for @shellHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get shellHistory;

  /// No description provided for @shellCaptureGuide.
  ///
  /// In en, this message translates to:
  /// **'Capture Guide'**
  String get shellCaptureGuide;

  /// No description provided for @shellSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get shellSettings;

  /// No description provided for @shellOpenNavigationMenu.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get shellOpenNavigationMenu;

  /// No description provided for @shellChooseMode.
  ///
  /// In en, this message translates to:
  /// **'Choose a physical scale or an AI photo estimate.'**
  String get shellChooseMode;

  /// No description provided for @shellMeasurementNotice.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth readings are measurements. Touch mode is a simulator; AI scans are real visual estimates.'**
  String get shellMeasurementNotice;

  /// No description provided for @guideEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Better input, better range'**
  String get guideEyebrow;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture guide'**
  String get guideTitle;

  /// No description provided for @guideIntro.
  ///
  /// In en, this message translates to:
  /// **'Four simple choices make a visual estimate more useful.'**
  String get guideIntro;

  /// No description provided for @guideWholeObjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Show the whole object'**
  String get guideWholeObjectTitle;

  /// No description provided for @guideWholeObjectBody.
  ///
  /// In en, this message translates to:
  /// **'Leave space around every edge. Avoid hands, labels, or other objects overlapping the target.'**
  String get guideWholeObjectBody;

  /// No description provided for @guideLightingTitle.
  ///
  /// In en, this message translates to:
  /// **'Use soft, even light'**
  String get guideLightingTitle;

  /// No description provided for @guideLightingBody.
  ///
  /// In en, this message translates to:
  /// **'Strong shadows hide shape. Bright daylight or a well-lit room usually gives the cleanest visual evidence.'**
  String get guideLightingBody;

  /// No description provided for @guideStructureTitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us solid or hollow'**
  String get guideStructureTitle;

  /// No description provided for @guideStructureBody.
  ///
  /// In en, this message translates to:
  /// **'A suitcase and a block can occupy the same volume but weigh very differently. Structure narrows the density assumption.'**
  String get guideStructureBody;

  /// No description provided for @guideSideViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a side view'**
  String get guideSideViewTitle;

  /// No description provided for @guideSideViewBody.
  ///
  /// In en, this message translates to:
  /// **'Move 45–90° around the same object. A second view helps AI infer shape, construction, and volume.'**
  String get guideSideViewBody;

  /// No description provided for @guideUnderstandingConfidence.
  ///
  /// In en, this message translates to:
  /// **'Understanding confidence'**
  String get guideUnderstandingConfidence;

  /// No description provided for @guideTryCapture.
  ///
  /// In en, this message translates to:
  /// **'Try a guided capture'**
  String get guideTryCapture;

  /// No description provided for @guideClearSubject.
  ///
  /// In en, this message translates to:
  /// **'Clear subject'**
  String get guideClearSubject;

  /// No description provided for @guideAllEdgesVisible.
  ///
  /// In en, this message translates to:
  /// **'ALL EDGES VISIBLE  •  SINGLE OBJECT'**
  String get guideAllEdgesVisible;

  /// No description provided for @guideLowDetail.
  ///
  /// In en, this message translates to:
  /// **'One photo, inferred scale or category'**
  String get guideLowDetail;

  /// No description provided for @guideMediumDetail.
  ///
  /// In en, this message translates to:
  /// **'Category plus structure confirmed'**
  String get guideMediumDetail;

  /// No description provided for @guideHighDetail.
  ///
  /// In en, this message translates to:
  /// **'Two clear angles plus useful object details'**
  String get guideHighDetail;

  /// No description provided for @historyEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Private on-device log'**
  String get historyEyebrow;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate history'**
  String get historyTitle;

  /// No description provided for @historyNewEstimate.
  ///
  /// In en, this message translates to:
  /// **'New estimate'**
  String get historyNewEstimate;

  /// No description provided for @historyAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get historyAll;

  /// No description provided for @historyNothingSaved.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get historyNothingSaved;

  /// No description provided for @historyNoCategoryEstimates.
  ///
  /// In en, this message translates to:
  /// **'No {category} estimates'**
  String historyNoCategoryEstimates(String category);

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save a result after your first photo estimate and it will appear here.'**
  String get historyEmptyBody;

  /// No description provided for @historyFilteredEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Choose another filter or make a new estimate.'**
  String get historyFilteredEmptyBody;

  /// No description provided for @historyStartEstimate.
  ///
  /// In en, this message translates to:
  /// **'Start estimate'**
  String get historyStartEstimate;

  /// No description provided for @historySavedStat.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get historySavedStat;

  /// No description provided for @historyCategoriesStat.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get historyCategoriesStat;

  /// No description provided for @historyLocalBadge.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get historyLocalBadge;

  /// No description provided for @detailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this estimate?'**
  String get detailDeleteTitle;

  /// No description provided for @detailDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The saved result and its private image copy will be removed.'**
  String get detailDeleteBody;

  /// No description provided for @detailSavedEstimate.
  ///
  /// In en, this message translates to:
  /// **'Saved estimate'**
  String get detailSavedEstimate;

  /// No description provided for @detailDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete estimate'**
  String get detailDeleteTooltip;

  /// No description provided for @detailAiEstimate.
  ///
  /// In en, this message translates to:
  /// **'AI estimate'**
  String get detailAiEstimate;

  /// No description provided for @detailEstimatedWeight.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED WEIGHT'**
  String get detailEstimatedWeight;

  /// No description provided for @detailLikelyRange.
  ///
  /// In en, this message translates to:
  /// **'Likely range'**
  String get detailLikelyRange;

  /// No description provided for @detailAiVisualSize.
  ///
  /// In en, this message translates to:
  /// **'AI visual size'**
  String get detailAiVisualSize;

  /// No description provided for @detailDimensionOrder.
  ///
  /// In en, this message translates to:
  /// **'Length × width × height · visual assumption'**
  String get detailDimensionOrder;

  /// No description provided for @detailAssumptions.
  ///
  /// In en, this message translates to:
  /// **'Assumptions'**
  String get detailAssumptions;

  /// No description provided for @detailSafetyNotice.
  ///
  /// In en, this message translates to:
  /// **'This is an informed visual estimate, not a sensor reading. Do not use it for safety-critical decisions.'**
  String get detailSafetyNotice;

  /// No description provided for @settingsEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Preferences and privacy'**
  String get settingsEyebrow;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Measurement'**
  String get settingsMeasurement;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsUnitsBody.
  ///
  /// In en, this message translates to:
  /// **'All values are stored canonically in metric.'**
  String get settingsUnitsBody;

  /// No description provided for @settingsMetric.
  ///
  /// In en, this message translates to:
  /// **'Metric'**
  String get settingsMetric;

  /// No description provided for @settingsImperial.
  ///
  /// In en, this message translates to:
  /// **'Imperial'**
  String get settingsImperial;

  /// No description provided for @settingsBluetoothSupport.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scale support'**
  String get settingsBluetoothSupport;

  /// No description provided for @settingsStandardBle.
  ///
  /// In en, this message translates to:
  /// **'Standard BLE WSS'**
  String get settingsStandardBle;

  /// No description provided for @settingsEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get settingsEngine;

  /// No description provided for @settingsAnalysisMode.
  ///
  /// In en, this message translates to:
  /// **'Analysis mode'**
  String get settingsAnalysisMode;

  /// No description provided for @settingsAnalysisSecureCloudAi.
  ///
  /// In en, this message translates to:
  /// **'Secure cloud AI'**
  String get settingsAnalysisSecureCloudAi;

  /// No description provided for @settingsCloudUploads.
  ///
  /// In en, this message translates to:
  /// **'Cloud uploads'**
  String get settingsCloudUploads;

  /// No description provided for @settingsCloudViaSecureApi.
  ///
  /// In en, this message translates to:
  /// **'Via secure API'**
  String get settingsCloudViaSecureApi;

  /// No description provided for @settingsProductionModel.
  ///
  /// In en, this message translates to:
  /// **'Production model'**
  String get settingsProductionModel;

  /// No description provided for @settingsScanCredits.
  ///
  /// In en, this message translates to:
  /// **'Scan credits'**
  String get settingsScanCredits;

  /// No description provided for @settingsEarnAiScans.
  ///
  /// In en, this message translates to:
  /// **'Earn AI scans'**
  String get settingsEarnAiScans;

  /// No description provided for @settingsEarnAiScansBody.
  ///
  /// In en, this message translates to:
  /// **'{usage} · watch one ad for one scan'**
  String settingsEarnAiScansBody(String usage);

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsSavedPhotos.
  ///
  /// In en, this message translates to:
  /// **'Saved photos'**
  String get settingsSavedPhotos;

  /// No description provided for @settingsPrivateStorage.
  ///
  /// In en, this message translates to:
  /// **'Private storage'**
  String get settingsPrivateStorage;

  /// No description provided for @settingsAdPrivacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy choices'**
  String get settingsAdPrivacyChoices;

  /// No description provided for @settingsReviewConsent.
  ///
  /// In en, this message translates to:
  /// **'Review or change consent'**
  String get settingsReviewConsent;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear estimate history'**
  String get settingsClearHistory;

  /// No description provided for @settingsNoSavedEstimates.
  ///
  /// In en, this message translates to:
  /// **'No saved estimates'**
  String get settingsNoSavedEstimates;

  /// No description provided for @settingsSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved estimates} =1{1 saved} other{{count} saved}}'**
  String settingsSavedCount(int count);

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsClearHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get settingsClearHistoryTitle;

  /// No description provided for @settingsClearHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved estimates or private image copies will be deleted.} =1{1 saved estimate and its private image copy will be deleted from this device.} other{{count} saved estimates and their private image copies will be deleted from this device.}}'**
  String settingsClearHistoryBody(int count);

  /// No description provided for @settingsClearHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get settingsClearHistoryAction;

  /// No description provided for @settingsHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Estimate history cleared.'**
  String get settingsHistoryCleared;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'MVP 1.0.0'**
  String get settingsVersion;

  /// No description provided for @settingsSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'A compatible Bluetooth scale provides physical readings. Touch mode is an interactive simulator and AI scans are real visual estimates. Never use MassLens for medical dosing, legal trade, or other safety-critical decisions.'**
  String get settingsSafetyBody;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable.'**
  String get cameraUnavailable;

  /// No description provided for @cameraAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera access is needed to photograph the object.'**
  String get cameraAccessNeeded;

  /// No description provided for @cameraUnavailableDevice.
  ///
  /// In en, this message translates to:
  /// **'Camera is unavailable on this device.'**
  String get cameraUnavailableDevice;

  /// No description provided for @cameraCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be captured. Try again.'**
  String get cameraCaptureFailed;

  /// No description provided for @cameraCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cameraCloseTooltip;

  /// No description provided for @cameraTorchOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn torch off'**
  String get cameraTorchOffTooltip;

  /// No description provided for @cameraTorchOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn torch on'**
  String get cameraTorchOnTooltip;

  /// No description provided for @cameraTakePhotoSemantics.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get cameraTakePhotoSemantics;

  /// No description provided for @scanCameraOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be opened.'**
  String get scanCameraOpenFailed;

  /// No description provided for @scanSelectedPhotoOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The selected photo could not be opened.'**
  String get scanSelectedPhotoOpenFailed;

  /// No description provided for @scanSecondPhotoOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The second photo could not be opened.'**
  String get scanSecondPhotoOpenFailed;

  /// No description provided for @scanDimensionPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a dimension greater than zero.'**
  String get scanDimensionPositive;

  /// No description provided for @scanAccessUnverified.
  ///
  /// In en, this message translates to:
  /// **'Scan access could not be verified. Check the connection and try again; no scan was used.'**
  String get scanAccessUnverified;

  /// No description provided for @scanLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You have used your available scans.'**
  String get scanLimitReached;

  /// No description provided for @scanAnalysisStopped.
  ///
  /// In en, this message translates to:
  /// **'Analysis stopped. Check the connection and try again.'**
  String get scanAnalysisStopped;

  /// No description provided for @scanCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Coach'**
  String get scanCoachTitle;

  /// No description provided for @scanCoachNoCredit.
  ///
  /// In en, this message translates to:
  /// **'No scan is used until you continue to analysis.'**
  String get scanCoachNoCredit;

  /// No description provided for @scanCoachRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get scanCoachRetake;

  /// No description provided for @scanCoachUseAnyway.
  ///
  /// In en, this message translates to:
  /// **'Use anyway'**
  String get scanCoachUseAnyway;

  /// No description provided for @scanSavedPrivateHistory.
  ///
  /// In en, this message translates to:
  /// **'Saved to your private history.'**
  String get scanSavedPrivateHistory;

  /// No description provided for @scanOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional details'**
  String get scanOptionalDetails;

  /// No description provided for @scanMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get scanMaterial;

  /// No description provided for @scanFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get scanFill;

  /// No description provided for @scanKnownSize.
  ///
  /// In en, this message translates to:
  /// **'Known size (optional)'**
  String get scanKnownSize;

  /// No description provided for @scanVisibleReference.
  ///
  /// In en, this message translates to:
  /// **'Visible reference'**
  String get scanVisibleReference;

  /// No description provided for @scanEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get scanEstimate;

  /// No description provided for @scanAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing'**
  String get scanAnalyzing;

  /// No description provided for @scanNewEstimate.
  ///
  /// In en, this message translates to:
  /// **'New estimate'**
  String get scanNewEstimate;

  /// No description provided for @scanReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get scanReview;

  /// No description provided for @scanPhotographObject.
  ///
  /// In en, this message translates to:
  /// **'Photograph an object'**
  String get scanPhotographObject;

  /// No description provided for @scanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanTakePhoto;

  /// No description provided for @scanChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get scanChooseGallery;

  /// No description provided for @scanConfirmObject.
  ///
  /// In en, this message translates to:
  /// **'Confirm the object'**
  String get scanConfirmObject;

  /// No description provided for @scanDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get scanDetails;

  /// No description provided for @scanAddSideView.
  ///
  /// In en, this message translates to:
  /// **'Add side view'**
  String get scanAddSideView;

  /// No description provided for @scanSideViewAdded.
  ///
  /// In en, this message translates to:
  /// **'Side view added'**
  String get scanSideViewAdded;

  /// No description provided for @scanSideViewOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional · move 45–90° around the same object'**
  String get scanSideViewOptional;

  /// No description provided for @scanSideViewBenefit.
  ///
  /// In en, this message translates to:
  /// **'Another angle helps AI infer shape and volume'**
  String get scanSideViewBenefit;

  /// No description provided for @scanAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get scanAdd;

  /// No description provided for @scanReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get scanReplace;

  /// No description provided for @scanRemoveSideView.
  ///
  /// In en, this message translates to:
  /// **'Remove side view'**
  String get scanRemoveSideView;

  /// No description provided for @scanProgressShape.
  ///
  /// In en, this message translates to:
  /// **'Reading shape'**
  String get scanProgressShape;

  /// No description provided for @scanProgressMaterial.
  ///
  /// In en, this message translates to:
  /// **'Estimating material'**
  String get scanProgressMaterial;

  /// No description provided for @scanProgressRange.
  ///
  /// In en, this message translates to:
  /// **'Building range'**
  String get scanProgressRange;

  /// No description provided for @scanLikelyRange.
  ///
  /// In en, this message translates to:
  /// **'LIKELY RANGE'**
  String get scanLikelyRange;

  /// No description provided for @scanAiVisualSize.
  ///
  /// In en, this message translates to:
  /// **'AI visual size · L × W × H'**
  String get scanAiVisualSize;

  /// No description provided for @scanConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get scanConfidence;

  /// No description provided for @scanHowEstimated.
  ///
  /// In en, this message translates to:
  /// **'How this was estimated'**
  String get scanHowEstimated;

  /// No description provided for @scanTryAnother.
  ///
  /// In en, this message translates to:
  /// **'Try another'**
  String get scanTryAnother;

  /// No description provided for @scanSecondViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a side view'**
  String get scanSecondViewTitle;

  /// No description provided for @scanSecondViewBody.
  ///
  /// In en, this message translates to:
  /// **'Move 45–90° around the same object and keep the whole object visible. This uses the same scan credit.'**
  String get scanSecondViewBody;

  /// No description provided for @scanChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get scanChoosePhoto;

  /// No description provided for @scanPhotoDarkWarning.
  ///
  /// In en, this message translates to:
  /// **'The photo is dark. More even light will improve material recognition.'**
  String get scanPhotoDarkWarning;

  /// No description provided for @scanPhotoBlurryWarning.
  ///
  /// In en, this message translates to:
  /// **'The photo looks blurry. Hold the phone steady and keep the object sharp.'**
  String get scanPhotoBlurryWarning;

  /// No description provided for @scanPhotoMissing.
  ///
  /// In en, this message translates to:
  /// **'The photo could not be found.'**
  String get scanPhotoMissing;

  /// No description provided for @scanPhotoCorrupt.
  ///
  /// In en, this message translates to:
  /// **'This photo is corrupt or unsupported. Retake it as a JPEG image.'**
  String get scanPhotoCorrupt;

  /// No description provided for @scanPhotoTooSmall.
  ///
  /// In en, this message translates to:
  /// **'This photo is too small. Use an image at least 320 × 320 pixels.'**
  String get scanPhotoTooSmall;

  /// No description provided for @scanCloudFailure.
  ///
  /// In en, this message translates to:
  /// **'The AI analysis could not be completed. Check the connection and try again; no fabricated result was created.'**
  String get scanCloudFailure;

  /// No description provided for @scaleWatchAdGetScan.
  ///
  /// In en, this message translates to:
  /// **'Watch ad · Get +1 scan'**
  String get scaleWatchAdGetScan;

  /// No description provided for @scaleSimulatorStatus.
  ///
  /// In en, this message translates to:
  /// **'SIMULATOR · NOT A MEASUREMENT'**
  String get scaleSimulatorStatus;

  /// No description provided for @scaleLiveStatus.
  ///
  /// In en, this message translates to:
  /// **'LIVE · BLUETOOTH SCALE'**
  String get scaleLiveStatus;

  /// No description provided for @scaleDisconnectedStatus.
  ///
  /// In en, this message translates to:
  /// **'BLUETOOTH · NOT CONNECTED'**
  String get scaleDisconnectedStatus;

  /// No description provided for @scaleSimulatorSemantics.
  ///
  /// In en, this message translates to:
  /// **'Touch scale simulator, not a physical measurement'**
  String get scaleSimulatorSemantics;

  /// No description provided for @scaleLiveSemantics.
  ///
  /// In en, this message translates to:
  /// **'Live Bluetooth scale reading'**
  String get scaleLiveSemantics;

  /// No description provided for @scaleDisconnectedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scale disconnected'**
  String get scaleDisconnectedSemantics;

  /// No description provided for @scaleOpenNavigation.
  ///
  /// In en, this message translates to:
  /// **'Open navigation menu'**
  String get scaleOpenNavigation;

  /// No description provided for @scaleOpenAiScan.
  ///
  /// In en, this message translates to:
  /// **'AI weight scan'**
  String get scaleOpenAiScan;

  /// No description provided for @scaleBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth scale'**
  String get scaleBluetooth;

  /// No description provided for @scaleGenericDevice.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth weight scale'**
  String get scaleGenericDevice;

  /// No description provided for @scaleUnit.
  ///
  /// In en, this message translates to:
  /// **'UNIT'**
  String get scaleUnit;

  /// No description provided for @scaleTare.
  ///
  /// In en, this message translates to:
  /// **'TARE'**
  String get scaleTare;

  /// No description provided for @scaleCloseBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Close Bluetooth panel'**
  String get scaleCloseBluetooth;

  /// No description provided for @scaleReceivingMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Receiving standard Weight Scale measurements'**
  String get scaleReceivingMeasurements;

  /// No description provided for @scaleBleSupport.
  ///
  /// In en, this message translates to:
  /// **'Supports BLE Weight Scale Service (0x181D)'**
  String get scaleBleSupport;

  /// No description provided for @scaleDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect scale'**
  String get scaleDisconnect;

  /// No description provided for @scaleSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get scaleSearching;

  /// No description provided for @scaleFindCompatible.
  ///
  /// In en, this message translates to:
  /// **'Find compatible scales'**
  String get scaleFindCompatible;

  /// No description provided for @scaleAvailableScales.
  ///
  /// In en, this message translates to:
  /// **'AVAILABLE SCALES'**
  String get scaleAvailableScales;

  /// No description provided for @scaleCompatible.
  ///
  /// In en, this message translates to:
  /// **'Compatible scale'**
  String get scaleCompatible;

  /// No description provided for @scaleSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal {rssi} dBm'**
  String scaleSignal(int rssi);

  /// No description provided for @scaleNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No standard scale found. Make sure the scale is awake and not connected to another app, then try again.'**
  String get scaleNoneFound;

  /// No description provided for @scalePrivateProtocolNotice.
  ///
  /// In en, this message translates to:
  /// **'Many kitchen scales use private manufacturer protocols. Those need a model-specific integration even if they appear in phone Bluetooth settings.'**
  String get scalePrivateProtocolNotice;

  /// No description provided for @scalePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices permission is required to find a scale.'**
  String get scalePermissionNeeded;

  /// No description provided for @scalePowerOnBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth, then search again.'**
  String get scalePowerOnBluetooth;

  /// No description provided for @scaleCommunicationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not communicate with this scale.'**
  String get scaleCommunicationFailed;

  /// No description provided for @scalePhaseIdle.
  ///
  /// In en, this message translates to:
  /// **'No scale connected'**
  String get scalePhaseIdle;

  /// No description provided for @scalePhasePermission.
  ///
  /// In en, this message translates to:
  /// **'Requesting permission'**
  String get scalePhasePermission;

  /// No description provided for @scalePhaseScanning.
  ///
  /// In en, this message translates to:
  /// **'Searching nearby'**
  String get scalePhaseScanning;

  /// No description provided for @scalePhaseConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get scalePhaseConnecting;

  /// No description provided for @scalePhaseDiscovering.
  ///
  /// In en, this message translates to:
  /// **'Checking compatibility'**
  String get scalePhaseDiscovering;

  /// No description provided for @scalePhaseSubscribing.
  ///
  /// In en, this message translates to:
  /// **'Starting live readings'**
  String get scalePhaseSubscribing;

  /// No description provided for @scalePhaseConnected.
  ///
  /// In en, this message translates to:
  /// **'Scale connected'**
  String get scalePhaseConnected;

  /// No description provided for @scalePhaseDisconnecting.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting'**
  String get scalePhaseDisconnecting;

  /// No description provided for @scalePhaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth unavailable'**
  String get scalePhaseUnavailable;

  /// No description provided for @scalePhaseError.
  ///
  /// In en, this message translates to:
  /// **'Connection needs attention'**
  String get scalePhaseError;

  /// No description provided for @scalePhaseClosed.
  ///
  /// In en, this message translates to:
  /// **'Reader closed'**
  String get scalePhaseClosed;

  /// No description provided for @rewardAdsFundAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Ads fund real AI analysis'**
  String get rewardAdsFundAnalysis;

  /// No description provided for @rewardHeadline.
  ///
  /// In en, this message translates to:
  /// **'Watch one ad. Get one scan.'**
  String get rewardHeadline;

  /// No description provided for @rewardBody.
  ///
  /// In en, this message translates to:
  /// **'Finish the ad and MassLens adds one scan. No subscription, purchase, or fabricated result.'**
  String get rewardBody;

  /// No description provided for @rewardMaxBalance.
  ///
  /// In en, this message translates to:
  /// **'Max {count}'**
  String rewardMaxBalance(int count);

  /// No description provided for @rewardSyncPending.
  ///
  /// In en, this message translates to:
  /// **'Scan credit sync pending'**
  String get rewardSyncPending;

  /// No description provided for @rewardSafeToClose.
  ///
  /// In en, this message translates to:
  /// **'Safe to close. We will keep checking for 24 hours.'**
  String get rewardSafeToClose;

  /// No description provided for @rewardChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get rewardChecking;

  /// No description provided for @rewardCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get rewardCheck;

  /// No description provided for @rewardAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding your scan…'**
  String get rewardAdding;

  /// No description provided for @rewardAnotherAdMinutes.
  ///
  /// In en, this message translates to:
  /// **'Another ad in {count, plural, =1{1 min} other{{count} min}}'**
  String rewardAnotherAdMinutes(int count);

  /// No description provided for @rewardAnotherAdSeconds.
  ///
  /// In en, this message translates to:
  /// **'Another ad in {count, plural, =1{1 sec} other{{count} sec}}'**
  String rewardAnotherAdSeconds(int count);

  /// No description provided for @rewardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ads unavailable'**
  String get rewardUnavailable;

  /// No description provided for @rewardWatchForOne.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad · Get 1 scan'**
  String get rewardWatchForOne;

  /// No description provided for @rewardLoading.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad is loading'**
  String get rewardLoading;

  /// No description provided for @rewardUseLegacyFirst.
  ///
  /// In en, this message translates to:
  /// **'Use your ad-free scan credit before earning more scans.'**
  String get rewardUseLegacyFirst;

  /// No description provided for @rewardAccessStateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ads are not available for this access state.'**
  String get rewardAccessStateUnavailable;

  /// No description provided for @rewardConsentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ads are unavailable because of consent or configuration. Existing scans and non-AI features remain available.'**
  String get rewardConsentUnavailable;

  /// No description provided for @rewardPrivacyChoices.
  ///
  /// In en, this message translates to:
  /// **'Privacy choices'**
  String get rewardPrivacyChoices;

  /// No description provided for @rewardTryLoadingAgain.
  ///
  /// In en, this message translates to:
  /// **'Try loading again'**
  String get rewardTryLoadingAgain;

  /// No description provided for @rewardCreditStillSyncing.
  ///
  /// In en, this message translates to:
  /// **'The scan credit is still syncing.'**
  String get rewardCreditStillSyncing;

  /// No description provided for @rewardNoCreditAdded.
  ///
  /// In en, this message translates to:
  /// **'No pending scan credit was added.'**
  String get rewardNoCreditAdded;

  /// No description provided for @accessLoadingBalance.
  ///
  /// In en, this message translates to:
  /// **'Loading scan balance…'**
  String get accessLoadingBalance;

  /// No description provided for @accessPreview.
  ///
  /// In en, this message translates to:
  /// **'Access preview'**
  String get accessPreview;

  /// No description provided for @accessScansLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No scans available} =1{1 scan left} other{{count} scans left}}'**
  String accessScansLeft(int count);

  /// No description provided for @accessScansAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No scans available} =1{1 scan available} other{{count} scans available}}'**
  String accessScansAvailable(int count);

  /// No description provided for @accessBreakdown.
  ///
  /// In en, this message translates to:
  /// **'{starter} starter · {rewarded} rewarded · {legacy} legacy'**
  String accessBreakdown(int starter, int rewarded, int legacy);

  /// No description provided for @accessStarterThenAd.
  ///
  /// In en, this message translates to:
  /// **'3 starter scans, then watch an ad'**
  String get accessStarterThenAd;

  /// No description provided for @accessGetOne.
  ///
  /// In en, this message translates to:
  /// **'Get +1'**
  String get accessGetOne;

  /// No description provided for @nativeSponsored.
  ///
  /// In en, this message translates to:
  /// **'Sponsored content'**
  String get nativeSponsored;

  /// No description provided for @nativeTestLoading.
  ///
  /// In en, this message translates to:
  /// **'Sponsored · test ad loading…'**
  String get nativeTestLoading;

  /// No description provided for @nativeTestRetrying.
  ///
  /// In en, this message translates to:
  /// **'Test ad retrying…'**
  String get nativeTestRetrying;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
