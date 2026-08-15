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

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

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

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

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

  /// No description provided for @referenceCoin.
  ///
  /// In en, this message translates to:
  /// **'Coin'**
  String get referenceCoin;

  /// No description provided for @scanReferenceTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: for best accuracy, place a coin (or a card) next to the object.'**
  String get scanReferenceTip;

  /// No description provided for @funUnitAaBattery.
  ///
  /// In en, this message translates to:
  /// **'AA battery'**
  String get funUnitAaBattery;

  /// No description provided for @funUnitSmartphone.
  ///
  /// In en, this message translates to:
  /// **'smartphone'**
  String get funUnitSmartphone;

  /// No description provided for @funUnitBaguette.
  ///
  /// In en, this message translates to:
  /// **'baguette'**
  String get funUnitBaguette;

  /// No description provided for @funUnitSodaCan.
  ///
  /// In en, this message translates to:
  /// **'soda can'**
  String get funUnitSodaCan;

  /// No description provided for @funUnitSoccerBall.
  ///
  /// In en, this message translates to:
  /// **'soccer ball'**
  String get funUnitSoccerBall;

  /// No description provided for @funUnitCat.
  ///
  /// In en, this message translates to:
  /// **'cat'**
  String get funUnitCat;

  /// No description provided for @funUnitWatermelon.
  ///
  /// In en, this message translates to:
  /// **'watermelon'**
  String get funUnitWatermelon;

  /// No description provided for @funUnitCarTire.
  ///
  /// In en, this message translates to:
  /// **'car tire'**
  String get funUnitCarTire;

  /// No description provided for @funUnitWashingMachine.
  ///
  /// In en, this message translates to:
  /// **'washing machine'**
  String get funUnitWashingMachine;

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

  /// No description provided for @onboardingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Help MassLens grow'**
  String get onboardingReviewTitle;

  /// No description provided for @onboardingReviewBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to leave an honest review on Google Play? It takes a moment and helps us improve.'**
  String get onboardingReviewBody;

  /// No description provided for @onboardingReviewLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingReviewLater;

  /// No description provided for @onboardingReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review app'**
  String get onboardingReviewAction;

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

  /// No description provided for @homeModeObject.
  ///
  /// In en, this message translates to:
  /// **'Object'**
  String get homeModeObject;

  /// No description provided for @homeModeFoodMacros.
  ///
  /// In en, this message translates to:
  /// **'Food & macros'**
  String get homeModeFoodMacros;

  /// No description provided for @homeFoodModeHint.
  ///
  /// In en, this message translates to:
  /// **'Photograph one whole plate to estimate each food\'s weight, calories and macros.'**
  String get homeFoodModeHint;

  /// No description provided for @homeScanFood.
  ///
  /// In en, this message translates to:
  /// **'Scan food plate'**
  String get homeScanFood;

  /// No description provided for @nutritionHomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Trends'**
  String get nutritionHomeTitle;

  /// No description provided for @nutritionHomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track daily calories and macros on this device'**
  String get nutritionHomeBody;

  /// No description provided for @nutritionHomeTodayCalories.
  ///
  /// In en, this message translates to:
  /// **'{count} kcal logged today'**
  String nutritionHomeTodayCalories(int count);

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

  /// No description provided for @shellNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get shellNutrition;

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

  /// No description provided for @shellExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit MassLens?'**
  String get shellExitTitle;

  /// No description provided for @shellExitBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the app?'**
  String get shellExitBody;

  /// No description provided for @nutritionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Private daily log'**
  String get nutritionEyebrow;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & Trends'**
  String get nutritionTitle;

  /// No description provided for @nutritionLocalBadge.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get nutritionLocalBadge;

  /// No description provided for @nutritionDayTab.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get nutritionDayTab;

  /// No description provided for @nutritionTrendsTab.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get nutritionTrendsTab;

  /// No description provided for @nutritionPreviousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get nutritionPreviousDay;

  /// No description provided for @nutritionNextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nutritionNextDay;

  /// No description provided for @nutritionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutritionToday;

  /// No description provided for @nutritionCaloriesUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get nutritionCaloriesUnit;

  /// No description provided for @nutritionKcal.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String nutritionKcal(String value);

  /// No description provided for @nutritionGrams.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String nutritionGrams(String value);

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionProteinShort.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get nutritionProteinShort;

  /// No description provided for @nutritionCarbsShort.
  ///
  /// In en, this message translates to:
  /// **'C'**
  String get nutritionCarbsShort;

  /// No description provided for @nutritionFatShort.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get nutritionFatShort;

  /// No description provided for @nutritionMacroCompact.
  ///
  /// In en, this message translates to:
  /// **'P {protein} g · C {carbs} g · F {fat} g'**
  String nutritionMacroCompact(int protein, int carbs, int fat);

  /// No description provided for @nutritionMacroRingSemantics.
  ///
  /// In en, this message translates to:
  /// **'{calories} calories, {protein} grams protein, {carbs} grams carbohydrates, and {fat} grams fat'**
  String nutritionMacroRingSemantics(
    int calories,
    int protein,
    int carbs,
    int fat,
  );

  /// No description provided for @nutritionPartialNotice.
  ///
  /// In en, this message translates to:
  /// **'Partial total: at least one food had no complete USDA nutrition match.'**
  String get nutritionPartialNotice;

  /// No description provided for @nutritionTrendPartialNotice.
  ///
  /// In en, this message translates to:
  /// **'This period includes partial totals from food scans with unmatched components.'**
  String get nutritionTrendPartialNotice;

  /// No description provided for @nutritionPartialShort.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get nutritionPartialShort;

  /// No description provided for @nutritionMealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get nutritionMealsTitle;

  /// No description provided for @nutritionAddFood.
  ///
  /// In en, this message translates to:
  /// **'Add food'**
  String get nutritionAddFood;

  /// No description provided for @nutritionNoEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged for this day'**
  String get nutritionNoEntriesTitle;

  /// No description provided for @nutritionNoEntriesBody.
  ///
  /// In en, this message translates to:
  /// **'Add a saved Food Scale result or enter calories and macros manually.'**
  String get nutritionNoEntriesBody;

  /// No description provided for @nutritionFromScans.
  ///
  /// In en, this message translates to:
  /// **'From Food Scans'**
  String get nutritionFromScans;

  /// No description provided for @nutritionFromScansBody.
  ///
  /// In en, this message translates to:
  /// **'Copy corrected nutrition from a saved food plate'**
  String get nutritionFromScansBody;

  /// No description provided for @nutritionManual.
  ///
  /// In en, this message translates to:
  /// **'Manual entry'**
  String get nutritionManual;

  /// No description provided for @nutritionManualBody.
  ///
  /// In en, this message translates to:
  /// **'Enter a meal\'s calories and macros yourself'**
  String get nutritionManualBody;

  /// No description provided for @nutritionNoScansTitle.
  ///
  /// In en, this message translates to:
  /// **'No food scans available'**
  String get nutritionNoScansTitle;

  /// No description provided for @nutritionNoScansBody.
  ///
  /// In en, this message translates to:
  /// **'Save a Food & macros scan containing USDA nutrition, then return here to log it.'**
  String get nutritionNoScansBody;

  /// No description provided for @nutritionChooseScan.
  ///
  /// In en, this message translates to:
  /// **'Choose a saved food scan'**
  String get nutritionChooseScan;

  /// No description provided for @nutritionAddFromScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Add scanned meal'**
  String get nutritionAddFromScanTitle;

  /// No description provided for @nutritionAddManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Add nutrition manually'**
  String get nutritionAddManualTitle;

  /// No description provided for @nutritionEditEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit nutrition entry'**
  String get nutritionEditEntryTitle;

  /// No description provided for @nutritionBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get nutritionBreakfast;

  /// No description provided for @nutritionLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get nutritionLunch;

  /// No description provided for @nutritionDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get nutritionDinner;

  /// No description provided for @nutritionSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get nutritionSnack;

  /// No description provided for @nutritionMeal.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get nutritionMeal;

  /// No description provided for @nutritionLabel.
  ///
  /// In en, this message translates to:
  /// **'Food or meal name'**
  String get nutritionLabel;

  /// No description provided for @nutritionWeightOptional.
  ///
  /// In en, this message translates to:
  /// **'Weight (optional)'**
  String get nutritionWeightOptional;

  /// No description provided for @nutritionCaloriesInput.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionCaloriesInput;

  /// No description provided for @nutritionRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter a food or meal name.'**
  String get nutritionRequiredLabel;

  /// No description provided for @nutritionInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid positive number.'**
  String get nutritionInvalidNumber;

  /// No description provided for @nutritionAtLeastOneValue.
  ///
  /// In en, this message translates to:
  /// **'Enter calories or at least one macro value.'**
  String get nutritionAtLeastOneValue;

  /// No description provided for @nutritionFutureDate.
  ///
  /// In en, this message translates to:
  /// **'Nutrition cannot be logged in the future.'**
  String get nutritionFutureDate;

  /// No description provided for @nutritionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get nutritionEdit;

  /// No description provided for @nutritionEntryActions.
  ///
  /// In en, this message translates to:
  /// **'Nutrition entry actions'**
  String get nutritionEntryActions;

  /// No description provided for @nutritionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete nutrition entry?'**
  String get nutritionDeleteTitle;

  /// No description provided for @nutritionDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Remove “{label}” from the local nutrition log?'**
  String nutritionDeleteBody(String label);

  /// No description provided for @nutritionTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition overview'**
  String get nutritionTrendsTitle;

  /// No description provided for @nutritionSevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get nutritionSevenDays;

  /// No description provided for @nutritionThirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get nutritionThirtyDays;

  /// No description provided for @nutritionAverageLoggedDays.
  ///
  /// In en, this message translates to:
  /// **'Average kcal on logged days'**
  String get nutritionAverageLoggedDays;

  /// No description provided for @nutritionLoggedDays.
  ///
  /// In en, this message translates to:
  /// **'Logged days'**
  String get nutritionLoggedDays;

  /// No description provided for @nutritionCaloriesTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily calories'**
  String get nutritionCaloriesTrend;

  /// No description provided for @nutritionMacroTrend.
  ///
  /// In en, this message translates to:
  /// **'Macro trend (grams)'**
  String get nutritionMacroTrend;

  /// No description provided for @nutritionCaloriesChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Calories chart for {days} days with {calories} total calories'**
  String nutritionCaloriesChartSemantics(int days, int calories);

  /// No description provided for @nutritionMacrosChartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Protein, carbohydrate, and fat trend chart for {days} days'**
  String nutritionMacrosChartSemantics(int days);

  /// No description provided for @nutritionDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Stored only on this device. Nutrition values are approximate and are not medical advice or dietary guidance.'**
  String get nutritionDisclaimer;

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

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'How photos, local history, AI analysis and USDA food searches are handled'**
  String get settingsPrivacyPolicyBody;

  /// No description provided for @settingsPrivacyPolicyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Add the privacy-policy URL in the release configuration.'**
  String get settingsPrivacyPolicyUnavailable;

  /// No description provided for @settingsPrivacyPolicyOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The privacy policy could not be opened.'**
  String get settingsPrivacyPolicyOpenFailed;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// No description provided for @legalSettingsBody.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy, Terms of Use, and data handling'**
  String get legalSettingsBody;

  /// No description provided for @legalIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear, honest policies'**
  String get legalIntroTitle;

  /// No description provided for @legalIntroBody.
  ///
  /// In en, this message translates to:
  /// **'How MassLens handles your data and the rules that apply when you use the app.'**
  String get legalIntroBody;

  /// No description provided for @legalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get legalPrivacyPolicy;

  /// No description provided for @legalTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get legalTermsOfUse;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'15 Aug 2026'**
  String get legalLastUpdated;

  /// No description provided for @legalPublishedPolicy.
  ///
  /// In en, this message translates to:
  /// **'View published privacy policy'**
  String get legalPublishedPolicy;

  /// No description provided for @legalFooter.
  ///
  /// In en, this message translates to:
  /// **'MassLens · Legal documents'**
  String get legalFooter;

  /// No description provided for @legalPrivacyScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Scope and who provides MassLens'**
  String get legalPrivacyScopeTitle;

  /// No description provided for @legalPrivacyScopeBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens is provided by the developer identified on its Google Play listing (\"we\", \"us\", or \"our\"). This policy explains how information is handled in the MassLens Android app and its scan service. MassLens does not require an account and does not directly ask for your name, email address, profile, or precise location.'**
  String get legalPrivacyScopeBody;

  /// No description provided for @legalPrivacyPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and AI analysis'**
  String get legalPrivacyPhotosTitle;

  /// No description provided for @legalPrivacyPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'A photo is processed only when you choose Camera or Gallery and start an AI scan. Before upload, MassLens corrects orientation, resizes the image, re-encodes it as JPEG, and removes embedded EXIF and GPS metadata. The photo, an optional second angle, and scan context are sent over HTTPS through the MassLens Cloudflare service to OpenAI to identify visible objects or food and estimate weight ranges. OpenAI is instructed not to store the response. Photos are not stored in the MassLens Worker database.'**
  String get legalPrivacyPhotosBody;

  /// No description provided for @legalPrivacyNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Food scans and USDA data'**
  String get legalPrivacyNutritionTitle;

  /// No description provided for @legalPrivacyNutritionBody.
  ///
  /// In en, this message translates to:
  /// **'For Food & macros scans, the AI returns food labels, approximate weight ranges, and generic English search terms; it does not create nutrient values. The server sends only normalized food search text to USDA FoodData Central to find calories and macros. USDA never receives your photos, installation identifier, or local history. All food weights, calories, and macros are estimates and may be incomplete.'**
  String get legalPrivacyNutritionBody;

  /// No description provided for @legalPrivacyLocalTitle.
  ///
  /// In en, this message translates to:
  /// **'Information stored on your device'**
  String get legalPrivacyLocalTitle;

  /// No description provided for @legalPrivacyLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Scan results and a private image copy are saved only when you choose Save. Preferences, local scan history, and Nutrition & Trends entries are stored inside the app on your device. Nutrition entries are added only when you explicitly import a saved food scan or enter values manually; they are not uploaded. Bluetooth device information is used only to find and connect to compatible scales and is not sent to MassLens. Android backup behavior may depend on your device settings.'**
  String get legalPrivacyLocalBody;

  /// No description provided for @legalPrivacyServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Service data and retention'**
  String get legalPrivacyServiceTitle;

  /// No description provided for @legalPrivacyServiceBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens creates a random installation identifier to manage starter scans, rewarded scan credits, retries, and abuse prevention. The service hashes it before database use and records request identifiers, credit state, reward state, limited technical events, and anonymous daily totals such as completed scan mode and AI cost. A completed result JSON, never the photo, may be retained for up to 24 hours for idempotent retries. Credit and anti-abuse records are kept as needed to operate those features. Hosting and network providers may process IP addresses and routine security logs.'**
  String get legalPrivacyServiceBody;

  /// No description provided for @legalPrivacyAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advertising and consent'**
  String get legalPrivacyAdsTitle;

  /// No description provided for @legalPrivacyAdsBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens uses Google Mobile Ads for rewarded scan credits and other ad placements. Google and its advertising partners may process advertising identifiers, device information, approximate location derived from network signals, diagnostics, consent choices, and ad interactions under their own policies. Where required, the app requests consent. If Google makes privacy options available for you, they can be reviewed from Settings.'**
  String get legalPrivacyAdsBody;

  /// No description provided for @legalPrivacySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Service providers, transfers, and sale'**
  String get legalPrivacySharingTitle;

  /// No description provided for @legalPrivacySharingBody.
  ///
  /// In en, this message translates to:
  /// **'Information is shared only as needed with Cloudflare for API delivery, OpenAI for photo analysis, USDA FoodData Central for generic nutrition searches, and Google for advertising and consent. These providers may process information in countries other than yours under their own terms and safeguards. MassLens does not sell your local scan history or nutrition diary and does not use them for user-level nutrition advertising or analytics.'**
  String get legalPrivacySharingBody;

  /// No description provided for @legalPrivacyChoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your choices and deletion'**
  String get legalPrivacyChoicesTitle;

  /// No description provided for @legalPrivacyChoicesBody.
  ///
  /// In en, this message translates to:
  /// **'You can deny camera or Bluetooth permission, use the simulator or compatible Bluetooth scale without AI, cancel before analysis, decline to save results, delete individual scans, clear all estimate history, clear Nutrition & Trends separately, review available ad privacy choices, or uninstall the app. Uninstalling removes app-local data subject to Android backup settings. For privacy requests that cannot be completed on-device, use the developer contact details on the MassLens Google Play listing. Do not send photos or sensitive health information with your request.'**
  String get legalPrivacyChoicesBody;

  /// No description provided for @legalPrivacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security and children'**
  String get legalPrivacySecurityTitle;

  /// No description provided for @legalPrivacySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens uses HTTPS, metadata removal, hashed installation identifiers, and access controls designed to reduce risk. No storage or internet transmission can be guaranteed completely secure. MassLens is not directed to children below the minimum digital-consent age in their country, and we do not knowingly request personal profiles from children.'**
  String get legalPrivacySecurityBody;

  /// No description provided for @legalPrivacyChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes and contact'**
  String get legalPrivacyChangesTitle;

  /// No description provided for @legalPrivacyChangesBody.
  ///
  /// In en, this message translates to:
  /// **'This policy may change when MassLens, applicable law, or its service providers change. The last-updated date will be revised for material updates. The published HTTPS version linked above is the version intended for the Google Play listing. Questions may be sent using the developer contact shown on that listing.'**
  String get legalPrivacyChangesBody;

  /// No description provided for @legalTermsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance and eligibility'**
  String get legalTermsAcceptanceTitle;

  /// No description provided for @legalTermsAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'By installing or using MassLens, you agree to these Terms of Use and the Privacy Policy. If you do not agree, do not use the app. You must be legally able to accept these terms where you live; otherwise, a parent or legal guardian must review and accept them for you. You are responsible for complying with applicable laws.'**
  String get legalTermsAcceptanceBody;

  /// No description provided for @legalTermsServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'What the service provides'**
  String get legalTermsServiceTitle;

  /// No description provided for @legalTermsServiceBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens provides compatible Bluetooth-scale readings, a clearly labeled touch simulator, AI-assisted visual estimates for objects and food plates, USDA-based approximate nutrition, local history, and an optional local nutrition diary. Features may require a supported device, internet access, permissions, ad availability, or a remaining scan credit.'**
  String get legalTermsServiceBody;

  /// No description provided for @legalTermsEstimatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimates, nutrition, and safety'**
  String get legalTermsEstimatesTitle;

  /// No description provided for @legalTermsEstimatesBody.
  ///
  /// In en, this message translates to:
  /// **'AI scans are visual estimates, not physical scale readings. Results may be inaccurate, incomplete, or unsuitable for a particular item or meal. MassLens is not a medical device and does not provide medical, dietary, allergy, dosing, legal-trade, shipping, or safety advice. Never rely on it for medication, regulated commerce, allergens, hazardous materials, or other safety-critical decisions. Use a calibrated scale or qualified professional when accuracy matters.'**
  String get legalTermsEstimatesBody;

  /// No description provided for @legalTermsContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your photos and acceptable use'**
  String get legalTermsContentTitle;

  /// No description provided for @legalTermsContentBody.
  ///
  /// In en, this message translates to:
  /// **'You keep your rights in photos and information you submit. You give MassLens and its necessary service providers a limited permission to process them only to deliver the requested scan, maintain security, and provide retries as described in the Privacy Policy. You must have the right to use submitted images. Do not submit illegal content, intimate imagery, confidential documents, images that violate another person\'s privacy or rights, malicious code, or content unrelated to legitimate object or food analysis.'**
  String get legalTermsContentBody;

  /// No description provided for @legalTermsCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan credits and advertising'**
  String get legalTermsCreditsTitle;

  /// No description provided for @legalTermsCreditsBody.
  ///
  /// In en, this message translates to:
  /// **'A new installation may receive a limited number of starter scans. A completed rewarded advertisement may grant a scan credit after confirmation by the app and service. Credits have no cash value, cannot be transferred, and may be limited to prevent abuse. Ad availability is not guaranteed. Failed qualifying scans are normally refunded, but access may be delayed by outages, fraud checks, or technical errors. Advertising formats and credit rules may change with reasonable notice.'**
  String get legalTermsCreditsBody;

  /// No description provided for @legalTermsThirdPartyTitle.
  ///
  /// In en, this message translates to:
  /// **'Local data and third-party services'**
  String get legalTermsThirdPartyTitle;

  /// No description provided for @legalTermsThirdPartyBody.
  ///
  /// In en, this message translates to:
  /// **'Saved results and nutrition entries are stored locally and may be lost if you delete them, clear app data, uninstall, change devices, or lose the device. You are responsible for any backup you require. MassLens relies on services from Cloudflare, OpenAI, USDA FoodData Central, Google Mobile Ads, Google Play, and device manufacturers. Their services, content, and availability are governed by their own terms; MassLens does not control them.'**
  String get legalTermsThirdPartyBody;

  /// No description provided for @legalTermsLicenseTitle.
  ///
  /// In en, this message translates to:
  /// **'License and intellectual property'**
  String get legalTermsLicenseTitle;

  /// No description provided for @legalTermsLicenseBody.
  ///
  /// In en, this message translates to:
  /// **'You receive a limited, personal, revocable, non-exclusive, non-transferable license to use MassLens for lawful, non-commercial purposes. The app, design, code, branding, and original materials remain the property of their respective owners. You may not copy, sell, sublicense, reverse engineer except where law expressly permits, bypass security or credit controls, overload the service, scrape it, or use it to build a competing dataset or service.'**
  String get legalTermsLicenseBody;

  /// No description provided for @legalTermsAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Availability, changes, and misuse'**
  String get legalTermsAvailabilityTitle;

  /// No description provided for @legalTermsAvailabilityBody.
  ///
  /// In en, this message translates to:
  /// **'MassLens may change, suspend, or discontinue features to improve the app, address security or legal requirements, manage costs, or respond to third-party changes. Continuous, error-free availability is not promised. Access may be limited or blocked when reasonably necessary to prevent fraud, automated abuse, attacks, unlawful use, or harm to the service or others.'**
  String get legalTermsAvailabilityBody;

  /// No description provided for @legalTermsLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimers and limitation of liability'**
  String get legalTermsLiabilityTitle;

  /// No description provided for @legalTermsLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'To the fullest extent permitted by law, MassLens is provided \"as is\" and \"as available\" without warranties of accuracy, fitness for a particular purpose, uninterrupted operation, or error-free results. The developer is not liable for indirect, incidental, special, consequential, or exemplary losses arising from reliance on estimates, loss of local data, third-party services, ads, or inability to use the app. Nothing in these terms excludes rights or liability that cannot legally be excluded in your country.'**
  String get legalTermsLiabilityBody;

  /// No description provided for @legalTermsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates, severability, and contact'**
  String get legalTermsChangesTitle;

  /// No description provided for @legalTermsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'These terms may be updated when MassLens or applicable requirements change. Continuing to use the app after an update takes effect means you accept the revised terms where permitted by law. If one provision is unenforceable, the remaining provisions continue to apply. Applicable mandatory consumer law remains unaffected. For questions or legal notices, use the developer contact details on the MassLens Google Play listing.'**
  String get legalTermsChangesBody;

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

  /// No description provided for @settingsClearNutrition.
  ///
  /// In en, this message translates to:
  /// **'Clear nutrition history'**
  String get settingsClearNutrition;

  /// No description provided for @settingsNoNutritionEntries.
  ///
  /// In en, this message translates to:
  /// **'No nutrition entries'**
  String get settingsNoNutritionEntries;

  /// No description provided for @settingsNutritionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 nutrition entry} other{{count} nutrition entries}}'**
  String settingsNutritionCount(int count);

  /// No description provided for @settingsClearNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear nutrition history?'**
  String get settingsClearNutritionTitle;

  /// No description provided for @settingsClearNutritionBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{The nutrition entry stored on this device will be deleted. Saved scans are unchanged.} other{All {count} nutrition entries stored on this device will be deleted. Saved scans are unchanged.}}'**
  String settingsClearNutritionBody(int count);

  /// No description provided for @settingsClearNutritionAction.
  ///
  /// In en, this message translates to:
  /// **'Clear nutrition'**
  String get settingsClearNutritionAction;

  /// No description provided for @settingsNutritionCleared.
  ///
  /// In en, this message translates to:
  /// **'Nutrition history cleared.'**
  String get settingsNutritionCleared;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.1.0'**
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

  /// No description provided for @scanNoFoodDetected.
  ///
  /// In en, this message translates to:
  /// **'No visible food was found. Try again with one whole plate in frame; the scan was refunded.'**
  String get scanNoFoodDetected;

  /// No description provided for @scanNutritionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'USDA nutrition data is temporarily unavailable. Try again later; the scan was refunded.'**
  String get scanNutritionUnavailable;

  /// No description provided for @scanNutritionNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No complete USDA nutrition match was found for this meal. Try a clearer photo; the scan was refunded.'**
  String get scanNutritionNoMatch;

  /// No description provided for @scanFoodScale.
  ///
  /// In en, this message translates to:
  /// **'Food Scale'**
  String get scanFoodScale;

  /// No description provided for @scanPhotographMeal.
  ///
  /// In en, this message translates to:
  /// **'Photograph one whole plate'**
  String get scanPhotographMeal;

  /// No description provided for @scanConfirmMeal.
  ///
  /// In en, this message translates to:
  /// **'Confirm the whole meal is visible'**
  String get scanConfirmMeal;

  /// No description provided for @scanAnalyzeMeal.
  ///
  /// In en, this message translates to:
  /// **'Analyze food & macros'**
  String get scanAnalyzeMeal;

  /// No description provided for @scanFoodOptionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Optional plate details'**
  String get scanFoodOptionalDetails;

  /// No description provided for @scanContainer.
  ///
  /// In en, this message translates to:
  /// **'Container type'**
  String get scanContainer;

  /// No description provided for @scanContainerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get scanContainerUnknown;

  /// No description provided for @scanContainerPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get scanContainerPlate;

  /// No description provided for @scanContainerBowl.
  ///
  /// In en, this message translates to:
  /// **'Bowl'**
  String get scanContainerBowl;

  /// No description provided for @scanContainerCup.
  ///
  /// In en, this message translates to:
  /// **'Cup'**
  String get scanContainerCup;

  /// No description provided for @scanContainerTray.
  ///
  /// In en, this message translates to:
  /// **'Tray'**
  String get scanContainerTray;

  /// No description provided for @scanContainerNone.
  ///
  /// In en, this message translates to:
  /// **'No container'**
  String get scanContainerNone;

  /// No description provided for @scanPlateDiameter.
  ///
  /// In en, this message translates to:
  /// **'Plate or bowl diameter (optional)'**
  String get scanPlateDiameter;

  /// No description provided for @scanFoodReferenceTip.
  ///
  /// In en, this message translates to:
  /// **'A visible coin, card, ruler, or known plate diameter can narrow the weight range.'**
  String get scanFoodReferenceTip;

  /// No description provided for @scanProgressIdentifyFood.
  ///
  /// In en, this message translates to:
  /// **'Identifying visible foods…'**
  String get scanProgressIdentifyFood;

  /// No description provided for @scanProgressMatchUsda.
  ///
  /// In en, this message translates to:
  /// **'Matching USDA nutrition data…'**
  String get scanProgressMatchUsda;

  /// No description provided for @scanProgressNutrition.
  ///
  /// In en, this message translates to:
  /// **'Calculating calories and macros…'**
  String get scanProgressNutrition;

  /// No description provided for @scanFoodTotalWeight.
  ///
  /// In en, this message translates to:
  /// **'Estimated net food weight'**
  String get scanFoodTotalWeight;

  /// No description provided for @scanFoodComponents.
  ///
  /// In en, this message translates to:
  /// **'Food components'**
  String get scanFoodComponents;

  /// No description provided for @scanNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get scanNutrition;

  /// No description provided for @scanCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get scanCalories;

  /// No description provided for @scanProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get scanProtein;

  /// No description provided for @scanCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get scanCarbs;

  /// No description provided for @scanFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get scanFat;

  /// No description provided for @scanEditAmount.
  ///
  /// In en, this message translates to:
  /// **'Correct amount'**
  String get scanEditAmount;

  /// No description provided for @scanRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove false detection'**
  String get scanRemoveItem;

  /// No description provided for @scanAmountGrams.
  ///
  /// In en, this message translates to:
  /// **'Amount in grams'**
  String get scanAmountGrams;

  /// No description provided for @scanOriginalAiRange.
  ///
  /// In en, this message translates to:
  /// **'Original AI range'**
  String get scanOriginalAiRange;

  /// No description provided for @scanUsdaSource.
  ///
  /// In en, this message translates to:
  /// **'USDA source'**
  String get scanUsdaSource;

  /// No description provided for @scanNutritionMissing.
  ///
  /// In en, this message translates to:
  /// **'Weight only — no complete USDA nutrition match'**
  String get scanNutritionMissing;

  /// No description provided for @scanPartialTotal.
  ///
  /// In en, this message translates to:
  /// **'Partial total'**
  String get scanPartialTotal;

  /// No description provided for @scanCompleteTotal.
  ///
  /// In en, this message translates to:
  /// **'Complete total'**
  String get scanCompleteTotal;

  /// No description provided for @scanFoodDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Approximate photo-based estimate. Not a medical device or dietary advice.'**
  String get scanFoodDisclaimer;

  /// No description provided for @scanFoodEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct food amount'**
  String get scanFoodEditTitle;

  /// No description provided for @scanFoodEditBody.
  ///
  /// In en, this message translates to:
  /// **'Nutrition totals will use your amount; the original AI range stays visible.'**
  String get scanFoodEditBody;

  /// No description provided for @scanFoodAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero.'**
  String get scanFoodAmountPositive;

  /// No description provided for @scanFoodAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Keep at least one food component.'**
  String get scanFoodAtLeastOne;

  /// No description provided for @scanRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get scanRemove;

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
