// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MassLens: Estimations photo';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonNo => 'Non';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonDone => 'Terminer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaved => 'Enregistré';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonStartOver => 'Recommencer';

  @override
  String get commonUnknown => 'Inconnu';

  @override
  String get confidenceLow => 'Faible';

  @override
  String get confidenceMedium => 'Moyenne';

  @override
  String get confidenceHigh => 'Élevée';

  @override
  String get confidenceLowLabel => 'Confiance faible';

  @override
  String get confidenceMediumLabel => 'Confiance moyenne';

  @override
  String get confidenceHighLabel => 'Confiance élevée';

  @override
  String get measurementToday => 'Aujourd’hui';

  @override
  String measurementTodayAt(String time) {
    return 'Aujourd’hui, $time';
  }

  @override
  String get measurementYesterday => 'Hier';

  @override
  String get categoryFood => 'Alimentation';

  @override
  String get categoryParcel => 'Colis';

  @override
  String get categoryFurniture => 'Meuble';

  @override
  String get categoryElectronics => 'Électronique';

  @override
  String get categoryLuggage => 'Bagage';

  @override
  String get categoryTool => 'Outil';

  @override
  String get categoryClothing => 'Vêtement';

  @override
  String get categoryHousehold => 'Objet domestique';

  @override
  String get categoryOther => 'Autre';

  @override
  String get materialUnknown => 'Inconnu';

  @override
  String get materialPlastic => 'Plastique';

  @override
  String get materialMetal => 'Métal';

  @override
  String get materialGlassCeramic => 'Verre/Céramique';

  @override
  String get materialWood => 'Bois';

  @override
  String get materialCardboardPaper => 'Carton/Papier';

  @override
  String get materialFabric => 'Tissu';

  @override
  String get materialFoodLiquid => 'Aliment/Liquide';

  @override
  String get materialMixed => 'Mixte';

  @override
  String get fillUnknown => 'Inconnu';

  @override
  String get fillSolid => 'Solide';

  @override
  String get fillEmpty => 'Vide';

  @override
  String get fillPartlyFilled => 'Partiellement rempli';

  @override
  String get fillFull => 'Rempli';

  @override
  String get referenceNone => 'Aucune';

  @override
  String get referenceRuler => 'Règle';

  @override
  String get referenceStandardCard => 'Carte standard';

  @override
  String get referenceCoin => 'Pièce de monnaie';

  @override
  String get scanReferenceTip =>
      'Astuce : pour plus de précision, placez une pièce de monnaie (ou une carte) à côté de l\'objet.';

  @override
  String get funUnitAaBattery => 'pile AA';

  @override
  String get funUnitSmartphone => 'smartphone';

  @override
  String get funUnitBaguette => 'baguette';

  @override
  String get funUnitSodaCan => 'canette de soda';

  @override
  String get funUnitSoccerBall => 'ballon de foot';

  @override
  String get funUnitCat => 'chat';

  @override
  String get funUnitWatermelon => 'pastèque';

  @override
  String get funUnitCarTire => 'pneu de voiture';

  @override
  String get funUnitWashingMachine => 'machine à laver';

  @override
  String get axisLength => 'Longueur';

  @override
  String get axisWidth => 'Largeur';

  @override
  String get axisHeight => 'Hauteur';

  @override
  String get axisDepth => 'Profondeur';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingStartScanning => 'Commencer à scanner';

  @override
  String get onboardingNoAccountNeeded => 'Aucun compte requis';

  @override
  String get onboardingSavedHistoryControl =>
      'Vous contrôlez l’historique enregistré';

  @override
  String get onboardingResponsibleEstimates =>
      'Conçu pour des estimations responsables';

  @override
  String get onboardingPrivateBadge => 'Privé';

  @override
  String get onboardingInstantBadge => 'Instantané';

  @override
  String onboardingStepOfTotal(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingVisualEyebrow => 'Estimation visuelle';

  @override
  String get onboardingVisualTitle =>
      'Estimez ce que vous ne pouvez pas peser.';

  @override
  String get onboardingVisualBody =>
      'Photographiez un objet pour obtenir une plage de poids utile, des dimensions supposées par l’IA et les hypothèses de l’estimation.';

  @override
  String get onboardingHonestEyebrow => 'Honnête par conception';

  @override
  String get onboardingHonestTitle =>
      'Une plage, pas un chiffre exact inventé.';

  @override
  String get onboardingHonestBody =>
      'MassLens indique la confiance et l’incertitude, car une photo fournit une estimation et non une mesure de balance.';

  @override
  String get onboardingPrivateEyebrow => 'Confidentialité d’abord';

  @override
  String get onboardingPrivateTitle => 'Vos objets restent les vôtres.';

  @override
  String get onboardingPrivateBody =>
      'Les métadonnées des photos sont supprimées avant leur envoi sécurisé pour une véritable analyse par IA. L’historique enregistré reste privé sur votre appareil.';

  @override
  String get onboardingAccessEyebrow => 'Accès aux scans';

  @override
  String get onboardingAccessTitle => 'Deux véritables scans IA sont inclus.';

  @override
  String get onboardingAccessBody =>
      'MassLens vérifie votre solde sécurisé avant l’analyse. Prendre ou vérifier une photo n’utilise jamais de scan.';

  @override
  String get onboardingAdsEyebrow => 'Options d’accès aux scans';

  @override
  String get onboardingAdsTitle => '2 scans gratuits, puis 1 scan par pub';

  @override
  String get onboardingAdsBody =>
      'Profitez de deux scans IA gratuits. Ensuite, regardez une publicité récompensée pour obtenir un scan, ou débloquez les scans illimités sans pub avec un achat unique à vie.';

  @override
  String get onboardingAccessPreparing => 'Préparation de l’accès aux scans…';

  @override
  String get onboardingAccessReady => 'Accès aux scans prêt';

  @override
  String get onboardingAccessRetry => 'Réessayer l’accès aux scans';

  @override
  String get onboardingAccessUnavailable =>
      'L’accès aux scans est indisponible. Vérifiez votre connexion et réessayez.';

  @override
  String get onboardingHeroTitle => 'Des informations en un clin d’œil';

  @override
  String get onboardingHeroBody =>
      'Estimez le poids probable d’un objet à partir de ses éléments visibles. Une photo ne mesure pas son poids réel et ne révèle pas son contenu caché.';

  @override
  String get onboardingHeroCta => 'Commencer';

  @override
  String get onboardingFramingTitle => 'Gardez l’objet entier visible';

  @override
  String get onboardingFramingBody =>
      'Laissez de l’espace autour de chaque bord et évitez que des mains ou des objets ne masquent le sujet.';

  @override
  String get onboardingFramingCta => 'Suivant';

  @override
  String get onboardingLightTitle => 'Bonne lumière, fond simple';

  @override
  String get onboardingLightBody =>
      'Un bon éclairage et une photo stable aident l’IA à reconnaître plus précisément la forme et le matériau.';

  @override
  String get onboardingLightCta => 'Continuer';

  @override
  String get onboardingPreparingTitle => 'Presque prêt';

  @override
  String get onboardingPreparingBody =>
      'Préparation de vos deux scans gratuits et de l’accès avec publicité récompensée.';

  @override
  String get onboardingPreparingCta => 'Vérification…';

  @override
  String get onboardingReadyTitle => 'Vous êtes prêt à scanner';

  @override
  String get onboardingReadyBody => 'Vos 2 premiers scans IA sont gratuits.';

  @override
  String get onboardingReadyCta => 'C’est parti';

  @override
  String get onboardingReviewTitle => 'Aidez MassLens à grandir';

  @override
  String get onboardingReviewBody =>
      'Souhaitez-vous laisser un avis honnête sur Google Play ? Cela ne prend qu’un instant et nous aide à nous améliorer.';

  @override
  String get onboardingReviewLater => 'Pas maintenant';

  @override
  String get onboardingReviewAction => 'Donner un avis';

  @override
  String get onboardingScanAccessLabel => 'Accès aux scans';

  @override
  String get onboardingAdSupportLabel => 'Financé par la publicité';

  @override
  String get onboardingThreeStarterScans => '2 scans gratuits';

  @override
  String get onboardingPreparingStatus => 'Préparation…';

  @override
  String get onboardingReadyStatus => 'Prêt';

  @override
  String get onboardingRetryStatus => 'Réessayer';

  @override
  String get homeAiWeight => 'Estimation photo';

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
  String get homeLatestEstimate => 'Dernière estimation';

  @override
  String get homeHistory => 'Historique';

  @override
  String get homeScanObject => 'Scanner un objet';

  @override
  String get homePhoto => 'Photo';

  @override
  String get homeModeObject => 'Objet';

  @override
  String get homeModeFoodMacros => 'Aliments et macros';

  @override
  String get homeFoodModeHint =>
      'Photographiez une assiette entière pour estimer le poids, les calories et les macros de chaque aliment.';

  @override
  String get homeScanFood => 'Scanner l’assiette';

  @override
  String get nutritionHomeTitle => 'Nutrition et tendances';

  @override
  String get nutritionHomeBody => 'Suivez calories et macros sur cet appareil';

  @override
  String nutritionHomeTodayCalories(int count) {
    return '$count kcal enregistrées aujourd’hui';
  }

  @override
  String get shellAiWeightScan => 'Estimations photo';

  @override
  String get shellNutrition => 'Nutrition';

  @override
  String get shellHistory => 'Historique';

  @override
  String get shellCaptureGuide => 'Guide de prise de vue';

  @override
  String get shellSettings => 'Réglages';

  @override
  String get shellOpenNavigationMenu => 'Ouvrir le menu de navigation';

  @override
  String get shellChooseMode => 'Estimations photo et journal alimentaire.';

  @override
  String get shellMeasurementNotice =>
      'Les résultats photo sont des estimations incertaines. Le téléphone ne mesure pas le poids. Utilisez une balance physique pour mesurer.';

  @override
  String get shellExitTitle => 'Quitter MassLens ?';

  @override
  String get shellExitBody => 'Voulez-vous vraiment quitter l’application ?';

  @override
  String get navScanShort => 'Scan IA';

  @override
  String get navGuideShort => 'Guide';

  @override
  String get homeHeroTitle => 'Explorez un objet en photo';

  @override
  String get homeHeroBody =>
      'Obtenez une fourchette de poids approximative à partir des éléments visibles. Une photo ne mesure pas le poids et ne révèle pas le contenu caché.';

  @override
  String get homeTipWhole => 'Objet entier';

  @override
  String get homeTipLight => 'Bonne lumière';

  @override
  String get homeTipReference => 'Repère de taille';

  @override
  String get nutritionEyebrow => 'Journal quotidien privé';

  @override
  String get nutritionTitle => 'Nutrition et tendances';

  @override
  String get nutritionLocalBadge => 'Sur l’appareil';

  @override
  String get nutritionDayTab => 'Jour';

  @override
  String get nutritionTrendsTab => 'Tendances';

  @override
  String get nutritionPreviousDay => 'Jour précédent';

  @override
  String get nutritionNextDay => 'Jour suivant';

  @override
  String get nutritionToday => 'Aujourd’hui';

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
  String get nutritionProtein => 'Protéines';

  @override
  String get nutritionCarbs => 'Glucides';

  @override
  String get nutritionFat => 'Lipides';

  @override
  String get nutritionProteinShort => 'Prot.';

  @override
  String get nutritionCarbsShort => 'Gluc.';

  @override
  String get nutritionFatShort => 'Lip.';

  @override
  String nutritionMacroCompact(int protein, int carbs, int fat) {
    return 'P $protein g · G $carbs g · L $fat g';
  }

  @override
  String nutritionMacroRingSemantics(
    int calories,
    int protein,
    int carbs,
    int fat,
  ) {
    return '$calories calories, $protein grammes de protéines, $carbs grammes de glucides et $fat grammes de lipides';
  }

  @override
  String get nutritionPartialNotice =>
      'Total partiel : au moins un aliment n’avait pas de correspondance nutritionnelle USDA complète.';

  @override
  String get nutritionTrendPartialNotice =>
      'Cette période contient des totaux partiels provenant d’aliments sans correspondance complète.';

  @override
  String get nutritionPartialShort => 'Partiel';

  @override
  String get nutritionMealsTitle => 'Repas';

  @override
  String get nutritionAddFood => 'Ajouter';

  @override
  String get nutritionNoEntriesTitle => 'Aucun aliment enregistré ce jour';

  @override
  String get nutritionNoEntriesBody =>
      'Ajoutez une estimation alimentaire enregistrée ou saisissez les calories et macros manuellement.';

  @override
  String get nutritionFromScans => 'Depuis les scans alimentaires';

  @override
  String get nutritionFromScansBody =>
      'Copier les données corrigées d’une assiette enregistrée';

  @override
  String get nutritionManual => 'Saisie manuelle';

  @override
  String get nutritionManualBody =>
      'Saisir vous-même les calories et macros d’un repas';

  @override
  String get nutritionNoScansTitle => 'Aucun scan alimentaire disponible';

  @override
  String get nutritionNoScansBody =>
      'Enregistrez un scan Aliment et macros contenant des données USDA, puis revenez ici.';

  @override
  String get nutritionChooseScan => 'Choisir un scan alimentaire';

  @override
  String get nutritionAddFromScanTitle => 'Ajouter le repas scanné';

  @override
  String get nutritionAddManualTitle => 'Ajouter manuellement';

  @override
  String get nutritionEditEntryTitle => 'Modifier l’entrée nutritionnelle';

  @override
  String get nutritionBreakfast => 'Petit-déjeuner';

  @override
  String get nutritionLunch => 'Déjeuner';

  @override
  String get nutritionDinner => 'Dîner';

  @override
  String get nutritionSnack => 'Collation';

  @override
  String get nutritionMeal => 'Repas';

  @override
  String get nutritionLabel => 'Nom de l’aliment ou du repas';

  @override
  String get nutritionWeightOptional => 'Poids (facultatif)';

  @override
  String get nutritionCaloriesInput => 'Calories';

  @override
  String get nutritionRequiredLabel =>
      'Saisissez un nom d’aliment ou de repas.';

  @override
  String get nutritionInvalidNumber => 'Saisissez un nombre positif valide.';

  @override
  String get nutritionAtLeastOneValue =>
      'Saisissez des calories ou au moins une macro.';

  @override
  String get nutritionFutureDate =>
      'La nutrition ne peut pas être enregistrée dans le futur.';

  @override
  String get nutritionEdit => 'Modifier';

  @override
  String get nutritionEntryActions => 'Actions de l’entrée nutritionnelle';

  @override
  String get nutritionDeleteTitle => 'Supprimer l’entrée ?';

  @override
  String nutritionDeleteBody(String label) {
    return 'Retirer « $label » du journal nutritionnel local ?';
  }

  @override
  String get nutritionTrendsTitle => 'Vue d’ensemble nutritionnelle';

  @override
  String get nutritionSevenDays => '7 jours';

  @override
  String get nutritionThirtyDays => '30 jours';

  @override
  String get nutritionAverageLoggedDays => 'Moyenne kcal des jours remplis';

  @override
  String get nutritionLoggedDays => 'Jours remplis';

  @override
  String get nutritionCaloriesTrend => 'Calories quotidiennes';

  @override
  String get nutritionMacroTrend => 'Tendance des macros (grammes)';

  @override
  String nutritionCaloriesChartSemantics(int days, int calories) {
    return 'Graphique des calories sur $days jours avec $calories calories au total';
  }

  @override
  String nutritionMacrosChartSemantics(int days) {
    return 'Graphique des protéines, glucides et lipides sur $days jours';
  }

  @override
  String get nutritionDisclaimer =>
      'Stocké uniquement sur cet appareil. Les valeurs nutritionnelles sont approximatives et ne constituent ni un avis médical ni un conseil alimentaire.';

  @override
  String get nutritionScanAMeal => 'Scanner un repas';

  @override
  String get nutritionOpenGallery => 'Choisir dans la galerie';

  @override
  String get nutritionRemainingLabel => 'restantes';

  @override
  String nutritionEatenKcal(String value) {
    return '$value consommées';
  }

  @override
  String nutritionOverGoal(String value) {
    return '$value au-dessus de l’objectif';
  }

  @override
  String get nutritionStreakZero => 'Commencez une série';

  @override
  String nutritionStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Série de $count jours',
      one: 'Série de 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDailyGoals => 'Objectifs quotidiens';

  @override
  String get nutritionCalorieGoal => 'Calories quotidiennes';

  @override
  String get nutritionEmptyTitle => 'Enregistrez votre premier repas';

  @override
  String get nutritionEmptyBody =>
      'Photographiez une assiette pour estimer calories et macros. Les valeurs sont des correspondances USDA approximatives, pas un avis médical.';

  @override
  String get nutritionSaveToToday => 'Enregistrer aujourd’hui';

  @override
  String get nutritionSaveHistoryOnly =>
      'Enregistrer dans l’historique seulement';

  @override
  String get nutritionScanLoggedMessage => 'Ajouté aux repas du jour';

  @override
  String get nutritionScanReviewTitle => 'Cadrez toute l’assiette';

  @override
  String get nutritionScanReviewBody =>
      'Confirmez que tout le repas est visible';

  @override
  String get nutritionScanWholePlate => 'Assiette entière';

  @override
  String get nutritionHomeHint =>
      'Le journal alimentaire se trouve dans Nutrition';

  @override
  String get nutritionMoreActions => 'Plus';

  @override
  String get nutritionGoalsSave => 'Enregistrer les objectifs';

  @override
  String nutritionOfGoalGrams(String consumed, String goal) {
    return '$consumed / $goal g';
  }

  @override
  String get nutritionEditGoals => 'Modifier les objectifs';

  @override
  String get guideEyebrow => 'Meilleure photo, meilleure plage';

  @override
  String get guideTitle => 'Guide de prise de vue';

  @override
  String get guideIntro =>
      'Quatre choix simples rendent une estimation visuelle plus utile.';

  @override
  String get guideWholeObjectTitle => 'Montrez l’objet en entier';

  @override
  String get guideWholeObjectBody =>
      'Laissez de l’espace autour de chaque bord. Évitez que des mains, étiquettes ou autres objets ne recouvrent le sujet.';

  @override
  String get guideLightingTitle => 'Utilisez une lumière douce et uniforme';

  @override
  String get guideLightingBody =>
      'Les ombres marquées cachent la forme. La lumière du jour ou une pièce bien éclairée fournit généralement les meilleurs indices visuels.';

  @override
  String get guideStructureTitle => 'Indiquez si l’objet est plein ou creux';

  @override
  String get guideStructureBody =>
      'Une valise et un bloc peuvent occuper le même volume tout en ayant des poids très différents. La structure affine l’hypothèse de densité.';

  @override
  String get guideSideViewTitle => 'Ajoutez une vue latérale';

  @override
  String get guideSideViewBody =>
      'Déplacez-vous de 45 à 90° autour du même objet. Une deuxième vue aide l’IA à déduire sa forme, sa construction et son volume.';

  @override
  String get guideUnderstandingConfidence =>
      'Comprendre le niveau de confiance';

  @override
  String get guideTryCapture => 'Essayer une prise de vue guidée';

  @override
  String get guideClearSubject => 'Sujet dégagé';

  @override
  String get guideAllEdgesVisible =>
      'TOUS LES BORDS VISIBLES  •  UN SEUL OBJET';

  @override
  String get guideLowDetail => 'Une photo, échelle ou catégorie déduite';

  @override
  String get guideMediumDetail => 'Catégorie et structure confirmées';

  @override
  String get guideHighDetail => 'Deux angles nets et des détails utiles';

  @override
  String get historyEyebrow => 'Journal privé sur l’appareil';

  @override
  String get historyTitle => 'Historique des estimations';

  @override
  String get historyNewEstimate => 'Nouvelle estimation';

  @override
  String get historyAll => 'Tout';

  @override
  String get historyNothingSaved => 'Aucune estimation enregistrée';

  @override
  String historyNoCategoryEstimates(String category) {
    return 'Aucune estimation « $category »';
  }

  @override
  String get historyEmptyBody =>
      'Enregistrez le résultat de votre première estimation par photo pour le retrouver ici.';

  @override
  String get historyFilteredEmptyBody =>
      'Choisissez un autre filtre ou créez une nouvelle estimation.';

  @override
  String get historyStartEstimate => 'Démarrer une estimation';

  @override
  String get historySavedStat => 'Enregistrées';

  @override
  String get historyCategoriesStat => 'Catégories';

  @override
  String get historyLocalBadge => 'Local';

  @override
  String get detailDeleteTitle => 'Supprimer cette estimation ?';

  @override
  String get detailDeleteBody =>
      'Le résultat enregistré et sa copie d’image privée seront supprimés.';

  @override
  String get detailSavedEstimate => 'Estimation enregistrée';

  @override
  String get detailDeleteTooltip => 'Supprimer l’estimation';

  @override
  String get detailAiEstimate => 'Estimation par IA';

  @override
  String get detailEstimatedWeight => 'POIDS ESTIMÉ';

  @override
  String get detailLikelyRange => 'Plage probable';

  @override
  String get detailAiVisualSize => 'Dimensions visuelles par IA';

  @override
  String get detailDimensionOrder =>
      'Longueur × largeur × hauteur · hypothèse visuelle';

  @override
  String get detailAssumptions => 'Hypothèses';

  @override
  String get detailSafetyNotice =>
      'Il s’agit d’une estimation visuelle argumentée, et non d’une mesure par capteur. Ne l’utilisez pas pour des décisions critiques pour la sécurité.';

  @override
  String get settingsEyebrow => 'Préférences et confidentialité';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsMeasurement => 'Mesure';

  @override
  String get settingsUnits => 'Unités';

  @override
  String get settingsUnitsBody =>
      'Toutes les valeurs sont enregistrées en unités métriques de référence.';

  @override
  String get settingsMetric => 'Métrique';

  @override
  String get settingsImperial => 'Impérial';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsThemeBody =>
      'Suivez votre appareil ou choisissez clair ou sombre.';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsHelp => 'Aide';

  @override
  String get settingsReplayWalkthrough => 'Revoir le guide de départ';

  @override
  String get settingsReplayWalkthroughBody =>
      'Revoyez les conseils de prise de vue du premier lancement.';

  @override
  String get settingsRateApp => 'Noter cette application';

  @override
  String get settingsRateAppBody => 'Laissez une note sur Google Play.';

  @override
  String get settingsRateAppUnavailable =>
      'Google Play est indisponible pour le moment.';

  @override
  String get settingsEngine => 'Moteur';

  @override
  String get settingsAnalysisMode => 'Mode d’analyse';

  @override
  String get settingsAnalysisSecureCloudAi => 'IA cloud sécurisée';

  @override
  String get settingsCloudUploads => 'Envois vers le cloud';

  @override
  String get settingsCloudViaSecureApi => 'Via une API sécurisée';

  @override
  String get settingsProductionModel => 'Modèle de production';

  @override
  String get settingsScanCredits => 'Crédits de scan';

  @override
  String get settingsEarnAiScans => 'Obtenir des scans IA';

  @override
  String settingsEarnAiScansBody(String usage) {
    return '$usage · Une pub pour un scan';
  }

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsSavedPhotos => 'Photos enregistrées';

  @override
  String get settingsPrivateStorage => 'Stockage privé';

  @override
  String get settingsAdPrivacyChoices =>
      'Choix de confidentialité publicitaire';

  @override
  String get settingsReviewConsent => 'Consulter ou modifier le consentement';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsPrivacyPolicyBody =>
      'Traitement des photos, de l’historique local, de l’analyse IA et des recherches USDA';

  @override
  String get settingsPrivacyPolicyUnavailable =>
      'Ajoutez l’URL de confidentialité dans la configuration de publication.';

  @override
  String get settingsPrivacyPolicyOpenFailed =>
      'Impossible d’ouvrir la politique de confidentialité.';

  @override
  String get legalTitle => 'Mentions légales';

  @override
  String get legalSettingsBody =>
      'Confidentialité, conditions d’utilisation et traitement des données';

  @override
  String get legalIntroTitle => 'Des règles claires et transparentes';

  @override
  String get legalIntroBody =>
      'Comment MassLens traite vos données et les règles applicables lorsque vous utilisez l’application.';

  @override
  String get legalPrivacyPolicy => 'Confidentialité';

  @override
  String get legalTermsOfUse => 'Conditions';

  @override
  String get legalLastUpdated => '21 août 2026';

  @override
  String get legalPublishedPolicy => 'Voir la politique publiée';

  @override
  String get legalFooter => 'MassLens · Documents juridiques';

  @override
  String get legalPrivacyScopeTitle => 'Champ d’application et fournisseur';

  @override
  String get legalPrivacyScopeBody =>
      'MassLens est fourni par le développeur identifié sur sa fiche Google Play (« nous », « notre » ou « nos »). Cette politique explique comment les informations sont traitées dans l’application Android MassLens et son service de scan. MassLens ne nécessite aucun compte et ne vous demande pas directement votre nom, votre adresse e-mail, un profil ou votre position précise.';

  @override
  String get legalPrivacyPhotosTitle => 'Photos et analyse par IA';

  @override
  String get legalPrivacyPhotosBody =>
      'Une photo n’est traitée que lorsque vous choisissez Appareil photo ou Galerie et lancez un scan IA. Avant l’envoi, MassLens corrige l’orientation, redimensionne l’image, la réencode en JPEG et supprime les métadonnées EXIF et GPS intégrées. La photo, un éventuel second angle et le contexte du scan sont envoyés en HTTPS via le service Cloudflare de MassLens à OpenAI afin d’identifier les objets ou aliments visibles et d’estimer des plages de poids. OpenAI reçoit l’instruction de ne pas stocker la réponse. Les photos ne sont pas stockées dans la base de données du Worker MassLens.';

  @override
  String get legalPrivacyNutritionTitle => 'Scans alimentaires et données USDA';

  @override
  String get legalPrivacyNutritionBody =>
      'Pour les scans Aliments et macros, l’IA renvoie des noms d’aliments, des plages de poids approximatives et des termes génériques de recherche en anglais ; elle ne crée pas les valeurs nutritionnelles. Le serveur envoie uniquement du texte de recherche normalisé à USDA FoodData Central pour trouver les calories et macros. L’USDA ne reçoit jamais vos photos, l’identifiant d’installation ou l’historique local. Tous les poids, calories et macros sont des estimations et peuvent être incomplets.';

  @override
  String get legalPrivacyLocalTitle =>
      'Informations stockées sur votre appareil';

  @override
  String get legalPrivacyLocalBody =>
      'Les résultats et une copie privée de la photo sont enregistrés uniquement si vous choisissez Enregistrer. Les préférences, l’historique et le journal alimentaire restent sur votre appareil. Les entrées alimentaires sont ajoutées uniquement par importation volontaire ou saisie manuelle ; elles ne sont pas envoyées au serveur. La sauvegarde Android dépend des réglages de votre appareil.';

  @override
  String get legalPrivacyServiceTitle => 'Données du service et conservation';

  @override
  String get legalPrivacyServiceBody =>
      'MassLens transmet hors de l’appareil des identifiants d’appareil ou autres ID. Elle crée un identifiant d’installation aléatoire — pas un IMEI, un numéro de série ni une adresse MAC matérielle — et l’envoie au service MassLens pour gérer les scans de départ, les crédits obtenus par publicité, les nouvelles tentatives et la prévention des abus. Le service le hache avant toute utilisation en base de données et enregistre des identifiants de requête, l’état des crédits et récompenses, des événements techniques limités et des totaux quotidiens anonymes, comme le mode de scan terminé et le coût de l’IA. Le JSON d’un résultat terminé, jamais la photo, peut être conservé jusqu’à 24 heures pour rejouer une requête sans double facturation. Les données de crédit et de lutte contre les abus sont conservées aussi longtemps que nécessaire à ces fonctions. Les fournisseurs d’hébergement et de réseau peuvent traiter les adresses IP et des journaux de sécurité usuels.';

  @override
  String get legalPrivacyAdsTitle => 'Publicité et consentement';

  @override
  String get legalPrivacyAdsBody =>
      'MassLens utilise Google Mobile Ads (AdMob) pour les crédits de scan récompensés et d’autres emplacements publicitaires. Google et ses partenaires collectent et partagent des identifiants d’appareil ou autres ID, notamment l’identifiant publicitaire Android et l’App Set ID, ainsi que des informations sur l’appareil, une position approximative déduite de l’adresse IP, des diagnostics, vos choix de consentement et vos interactions avec les annonces, à des fins publicitaires, d’analyse et de prévention des fraudes, selon leurs propres politiques. Lorsque cela est requis, l’application demande votre consentement. Vous pouvez réinitialiser l’identifiant publicitaire dans les réglages Android. Si Google met des options de confidentialité à votre disposition, vous pouvez les consulter dans les Réglages.';

  @override
  String get legalPrivacySharingTitle => 'Prestataires, transferts et vente';

  @override
  String get legalPrivacySharingBody =>
      'Les informations sont partagées uniquement lorsque cela est nécessaire avec Cloudflare pour fournir l’API, OpenAI pour analyser les photos, USDA FoodData Central pour les recherches nutritionnelles génériques et Google pour la publicité et le consentement. Ces prestataires peuvent traiter les informations dans d’autres pays selon leurs propres conditions et garanties. MassLens ne vend pas votre historique local de scans ni votre journal nutritionnel et ne les utilise pas pour des publicités ou analyses nutritionnelles individualisées.';

  @override
  String get legalPrivacyChoicesTitle => 'Vos choix et la suppression';

  @override
  String get legalPrivacyChoicesBody =>
      'Vous pouvez refuser l’accès à la caméra, utiliser le journal manuel sans IA, annuler avant l’analyse, ne pas enregistrer les résultats, supprimer des analyses ou l’historique, vider séparément le journal alimentaire, consulter les choix publicitaires ou désinstaller l’application. La suppression des données locales dépend aussi des sauvegardes Android. Pour toute autre demande, contactez le développeur via Google Play sans joindre de photos ni d’informations de santé sensibles.';

  @override
  String get legalPrivacySecurityTitle => 'Sécurité et enfants';

  @override
  String get legalPrivacySecurityBody =>
      'MassLens utilise HTTPS, la suppression des métadonnées, des identifiants d’installation hachés et des contrôles d’accès conçus pour réduire les risques. Aucun stockage ni aucune transmission Internet ne peut être garanti comme totalement sécurisé. MassLens ne s’adresse pas aux enfants n’ayant pas atteint l’âge minimal de consentement numérique dans leur pays et nous ne demandons pas sciemment de profil personnel à des enfants.';

  @override
  String get legalPrivacyChangesTitle => 'Modifications et contact';

  @override
  String get legalPrivacyChangesBody =>
      'Cette politique peut évoluer lorsque MassLens, la loi applicable ou ses prestataires changent. La date de mise à jour sera modifiée en cas d’évolution importante. La version HTTPS publiée via le lien ci-dessus est celle destinée à la fiche Google Play. Pour toute question, utilisez le contact du développeur affiché sur cette fiche.';

  @override
  String get legalTermsAcceptanceTitle => 'Acceptation et admissibilité';

  @override
  String get legalTermsAcceptanceBody =>
      'En installant ou en utilisant MassLens, vous acceptez les présentes Conditions d’utilisation et la Politique de confidentialité. Si vous ne les acceptez pas, n’utilisez pas l’application. Vous devez avoir la capacité légale de les accepter dans votre pays ; à défaut, un parent ou représentant légal doit les lire et les accepter pour vous. Vous êtes responsable du respect des lois applicables.';

  @override
  String get legalTermsServiceTitle => 'Ce que fournit le service';

  @override
  String get legalTermsServiceBody =>
      'MassLens fournit des estimations visuelles assistées par IA pour les objets et les repas, une nutrition approximative basée sur USDA, un historique local et un journal alimentaire facultatif. L’analyse photo nécessite Internet et un accès aux analyses. Certaines fonctions dépendent des autorisations ou de la disponibilité des publicités.';

  @override
  String get legalTermsEstimatesTitle => 'Estimations, nutrition et sécurité';

  @override
  String get legalTermsEstimatesBody =>
      'Les scans IA sont des estimations visuelles et non des mesures provenant d’une balance physique. Les résultats peuvent être inexacts, incomplets ou inadaptés à un objet ou repas donné. MassLens n’est pas un dispositif médical et ne fournit aucun conseil médical, diététique, allergologique, posologique, commercial réglementé, logistique ou de sécurité. Ne l’utilisez jamais pour des médicaments, une transaction réglementée, des allergènes, des matières dangereuses ou toute décision critique. Utilisez une balance étalonnée ou un professionnel qualifié lorsque la précision est importante.';

  @override
  String get legalTermsContentTitle => 'Vos photos et l’utilisation acceptable';

  @override
  String get legalTermsContentBody =>
      'Vous conservez vos droits sur les photos et informations transmises. Vous accordez à MassLens et à ses prestataires indispensables une autorisation limitée de les traiter uniquement pour fournir le scan demandé, assurer la sécurité et permettre les nouvelles tentatives décrites dans la Politique de confidentialité. Vous devez avoir le droit d’utiliser les images envoyées. N’envoyez pas de contenu illégal, d’images intimes, de documents confidentiels, d’images portant atteinte à la vie privée ou aux droits d’autrui, de code malveillant ou de contenu sans rapport avec une analyse légitime d’objet ou d’aliment.';

  @override
  String get legalTermsCreditsTitle => 'Crédits de scan et publicité';

  @override
  String get legalTermsCreditsBody =>
      'Une nouvelle installation peut recevoir un nombre limité de scans de départ. Une publicité récompensée terminée peut accorder un crédit après confirmation par l’application et le service. Un achat unique Google Play peut débloquer des scans illimités et supprimer les publicités pour ce compte Google sur les appareils pris en charge, sous réserve de limites d’usage raisonnable et des règles de remboursement Google Play. Les crédits et l’accès à vie n’ont aucune valeur monétaire, ne sont pas transférables entre comptes et peuvent être limités pour prévenir les abus. La disponibilité des annonces n’est pas garantie. Les scans admissibles ayant échoué sont normalement remboursés, mais l’accès peut être retardé par une panne, un contrôle antifraude, une vérification d’achat ou une erreur technique. Les formats publicitaires, règles de crédit et tarifs peuvent évoluer avec un préavis raisonnable.';

  @override
  String get legalTermsThirdPartyTitle => 'Données locales et services tiers';

  @override
  String get legalTermsThirdPartyBody =>
      'Les résultats et entrées nutritionnelles enregistrés sont stockés localement et peuvent être perdus si vous les supprimez, effacez les données de l’application, désinstallez, changez d’appareil ou perdez celui-ci. Toute sauvegarde nécessaire relève de votre responsabilité. MassLens s’appuie sur Cloudflare, OpenAI, USDA FoodData Central, Google Mobile Ads, Google Play et les fabricants d’appareils. Leurs services, contenus et disponibilités sont régis par leurs propres conditions ; MassLens ne les contrôle pas.';

  @override
  String get legalTermsLicenseTitle => 'Licence et propriété intellectuelle';

  @override
  String get legalTermsLicenseBody =>
      'Vous recevez une licence limitée, personnelle, révocable, non exclusive et non transférable pour utiliser MassLens à des fins légales et non commerciales. L’application, sa conception, son code, ses marques et ses contenus originaux restent la propriété de leurs titulaires respectifs. Vous ne pouvez pas copier, vendre, sous-licencier, procéder à de l’ingénierie inverse sauf autorisation expresse de la loi, contourner la sécurité ou les crédits, surcharger ou aspirer le service, ni l’utiliser pour créer un jeu de données ou service concurrent.';

  @override
  String get legalTermsAvailabilityTitle =>
      'Disponibilité, modifications et abus';

  @override
  String get legalTermsAvailabilityBody =>
      'MassLens peut modifier, suspendre ou arrêter des fonctions pour améliorer l’application, répondre à des exigences de sécurité ou légales, maîtriser les coûts ou s’adapter à des tiers. Une disponibilité continue et sans erreur n’est pas garantie. L’accès peut être limité ou bloqué lorsque cela est raisonnablement nécessaire pour empêcher la fraude, les abus automatisés, les attaques, les usages illégaux ou les dommages au service ou à autrui.';

  @override
  String get legalTermsLiabilityTitle =>
      'Exclusions et limitation de responsabilité';

  @override
  String get legalTermsLiabilityBody =>
      'Dans toute la mesure autorisée par la loi, MassLens est fourni « en l’état » et « selon disponibilité », sans garantie d’exactitude, d’adéquation à un usage particulier, de fonctionnement ininterrompu ou de résultats sans erreur. Le développeur n’est pas responsable des pertes indirectes, accessoires, spéciales, consécutives ou exemplaires liées à la confiance accordée aux estimations, à la perte de données locales, aux services tiers, aux annonces ou à l’impossibilité d’utiliser l’application. Rien dans ces conditions n’exclut les droits ou responsabilités qui ne peuvent légalement être exclus dans votre pays.';

  @override
  String get legalTermsChangesTitle => 'Mises à jour, divisibilité et contact';

  @override
  String get legalTermsChangesBody =>
      'Ces conditions peuvent être mises à jour lorsque MassLens ou les exigences applicables évoluent. Continuer à utiliser l’application après l’entrée en vigueur d’une mise à jour vaut acceptation des conditions révisées lorsque la loi le permet. Si une disposition est inapplicable, les autres restent en vigueur. Les règles impératives de protection des consommateurs demeurent inchangées. Pour toute question ou notification juridique, utilisez les coordonnées du développeur sur la fiche Google Play de MassLens.';

  @override
  String get settingsClearHistory => 'Effacer l’historique des estimations';

  @override
  String get settingsNoSavedEstimates => 'Aucune estimation enregistrée';

  @override
  String settingsSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enregistrées',
      one: '1 enregistrée',
      zero: 'Aucune estimation',
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsClearHistoryTitle => 'Effacer tout l’historique ?';

  @override
  String settingsClearHistoryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count estimations enregistrées et leurs copies d’images privées seront supprimées de cet appareil.',
      one:
          '1 estimation enregistrée et sa copie d’image privée seront supprimées de cet appareil.',
      zero: 'Aucune estimation ni copie d’image privée ne sera supprimée.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearHistoryAction => 'Effacer l’historique';

  @override
  String get settingsHistoryCleared => 'Historique des estimations effacé.';

  @override
  String get settingsClearNutrition => 'Effacer l’historique nutritionnel';

  @override
  String get settingsNoNutritionEntries => 'Aucune entrée nutritionnelle';

  @override
  String settingsNutritionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrées nutritionnelles',
      one: '1 entrée nutritionnelle',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionTitle =>
      'Effacer l’historique nutritionnel ?';

  @override
  String settingsClearNutritionBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Les $count entrées nutritionnelles stockées sur cet appareil seront supprimées. Les scans enregistrés restent inchangés.',
      one:
          'L’entrée nutritionnelle stockée sur cet appareil sera supprimée. Les scans enregistrés restent inchangés.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionAction => 'Effacer la nutrition';

  @override
  String get settingsNutritionCleared => 'Historique nutritionnel effacé.';

  @override
  String get settingsVersion => 'Version 1.1.0';

  @override
  String get settingsSafetyBody =>
      'Les photos fournissent des estimations visuelles incertaines. Utilisez une balance physique si la précision compte. N’utilisez jamais MassLens pour un dosage médical, une transaction réglementée ou une décision de sécurité.';

  @override
  String get cameraUnavailable => 'La caméra est indisponible.';

  @override
  String get cameraAccessNeeded =>
      'L’accès à la caméra est nécessaire pour photographier l’objet.';

  @override
  String get cameraUnavailableDevice =>
      'La caméra est indisponible sur cet appareil.';

  @override
  String get cameraCaptureFailed =>
      'La photo n’a pas pu être prise. Réessayez.';

  @override
  String get cameraCloseTooltip => 'Fermer';

  @override
  String get cameraTorchOffTooltip => 'Éteindre la lampe';

  @override
  String get cameraTorchOnTooltip => 'Allumer la lampe';

  @override
  String get cameraTakePhotoSemantics => 'Prendre une photo';

  @override
  String get scanCameraOpenFailed => 'La caméra n’a pas pu être ouverte.';

  @override
  String get scanSelectedPhotoOpenFailed =>
      'La photo sélectionnée n’a pas pu être ouverte.';

  @override
  String get scanSecondPhotoOpenFailed =>
      'La deuxième photo n’a pas pu être ouverte.';

  @override
  String get scanDimensionPositive =>
      'Saisissez une dimension supérieure à zéro.';

  @override
  String get scanAccessUnverified =>
      'L’accès aux scans n’a pas pu être vérifié. Vérifiez la connexion et réessayez ; aucun scan n’a été utilisé.';

  @override
  String get scanLimitReached =>
      'Vous avez utilisé tous vos scans disponibles.';

  @override
  String get scanAnalysisStopped =>
      'L’analyse s’est arrêtée. Vérifiez la connexion et réessayez.';

  @override
  String get scanCoachTitle => 'Conseils de prise de vue';

  @override
  String get scanCoachNoCredit =>
      'Aucun scan n’est utilisé avant le lancement de l’analyse.';

  @override
  String get scanCoachRetake => 'Reprendre';

  @override
  String get scanCoachUseAnyway => 'Utiliser quand même';

  @override
  String get scanSavedPrivateHistory =>
      'Enregistré dans votre historique privé.';

  @override
  String get scanOptionalDetails => 'Détails facultatifs';

  @override
  String get scanMaterial => 'Matériau';

  @override
  String get scanFill => 'Remplissage';

  @override
  String get scanKnownSize => 'Dimension connue (facultatif)';

  @override
  String get scanVisibleReference => 'Référence visible';

  @override
  String get scanEstimate => 'Estimer';

  @override
  String get scanAnalyzing => 'Analyse';

  @override
  String get scanNewEstimate => 'Nouvelle estimation';

  @override
  String get scanReview => 'Vérification';

  @override
  String get scanPhotographObject => 'Photographiez un objet';

  @override
  String get scanTakePhoto => 'Prendre une photo';

  @override
  String get scanChooseGallery => 'Choisir dans la galerie';

  @override
  String get scanConfirmObject => 'Confirmez l’objet';

  @override
  String get scanDetails => 'Détails';

  @override
  String get scanAddSideView => 'Ajouter une vue latérale';

  @override
  String get scanSideViewAdded => 'Vue latérale ajoutée';

  @override
  String get scanSideViewOptional =>
      'Facultatif · déplacez-vous de 45 à 90° autour du même objet';

  @override
  String get scanSideViewBenefit =>
      'Un autre angle aide l’IA à déduire la forme et le volume';

  @override
  String get scanAdd => 'Ajouter';

  @override
  String get scanReplace => 'Remplacer';

  @override
  String get scanRemoveSideView => 'Supprimer la vue latérale';

  @override
  String get scanProgressShape => 'Analyse de la forme';

  @override
  String get scanProgressMaterial => 'Estimation du matériau';

  @override
  String get scanProgressRange => 'Calcul de la plage';

  @override
  String get scanLikelyRange => 'PLAGE PROBABLE';

  @override
  String get scanAiVisualSize => 'Dimensions visuelles IA · L × l × H';

  @override
  String get scanConfidence => 'Confiance';

  @override
  String get scanHowEstimated => 'Méthode d’estimation';

  @override
  String get scanTryAnother => 'Autre objet';

  @override
  String get scanSecondViewTitle => 'Ajouter une vue latérale';

  @override
  String get scanSecondViewBody =>
      'Déplacez-vous de 45 à 90° autour du même objet et gardez-le entièrement visible. Cette vue utilise le même crédit de scan.';

  @override
  String get scanChoosePhoto => 'Choisir une photo';

  @override
  String get scanPhotoDarkWarning =>
      'La photo est sombre. Une lumière plus uniforme améliorera la reconnaissance du matériau.';

  @override
  String get scanPhotoBlurryWarning =>
      'La photo semble floue. Stabilisez le téléphone et gardez l’objet net.';

  @override
  String get scanPhotoMissing => 'La photo est introuvable.';

  @override
  String get scanPhotoCorrupt =>
      'Cette photo est endommagée ou non prise en charge. Reprenez-la au format JPEG.';

  @override
  String get scanPhotoTooSmall =>
      'Cette photo est trop petite. Utilisez une image d’au moins 320 × 320 pixels.';

  @override
  String get scanCloudFailure =>
      'L’analyse par IA n’a pas pu aboutir. Vérifiez la connexion et réessayez ; aucun résultat fictif n’a été créé.';

  @override
  String get scanNoFoodDetected =>
      'Aucun aliment visible n’a été trouvé. Cadrez une assiette entière et réessayez ; le scan a été recrédité.';

  @override
  String get scanNutritionUnavailable =>
      'Les données nutritionnelles USDA sont temporairement indisponibles. Réessayez plus tard ; le scan a été recrédité.';

  @override
  String get scanNutritionNoMatch =>
      'Aucune donnée nutritionnelle USDA complète ne correspond à ce repas. Essayez une photo plus nette ; le scan a été recrédité.';

  @override
  String get scanFoodScale => 'Estimations alimentaires';

  @override
  String get scanPhotographMeal => 'Photographiez une assiette entière';

  @override
  String get scanConfirmMeal => 'Vérifiez que tout le repas est visible';

  @override
  String get scanAnalyzeMeal => 'Analyser aliments et macros';

  @override
  String get scanFoodOptionalDetails => 'Détails facultatifs de l’assiette';

  @override
  String get scanContainer => 'Type de contenant';

  @override
  String get scanContainerUnknown => 'Inconnu';

  @override
  String get scanContainerPlate => 'Assiette';

  @override
  String get scanContainerBowl => 'Bol';

  @override
  String get scanContainerCup => 'Tasse';

  @override
  String get scanContainerTray => 'Plateau';

  @override
  String get scanContainerNone => 'Sans contenant';

  @override
  String get scanPlateDiameter =>
      'Diamètre de l’assiette ou du bol (facultatif)';

  @override
  String get scanFoodReferenceTip =>
      'Une pièce, une carte, une règle ou un diamètre connu peut réduire la plage de poids.';

  @override
  String get scanProgressIdentifyFood =>
      'Identification des aliments visibles…';

  @override
  String get scanProgressMatchUsda =>
      'Recherche des données nutritionnelles USDA…';

  @override
  String get scanProgressNutrition => 'Calcul des calories et des macros…';

  @override
  String get scanFoodTotalWeight => 'Poids net estimé des aliments';

  @override
  String get scanFoodComponents => 'Composants alimentaires';

  @override
  String get scanNutrition => 'Nutrition';

  @override
  String get scanCalories => 'Calories';

  @override
  String get scanProtein => 'Protéines';

  @override
  String get scanCarbs => 'Glucides';

  @override
  String get scanFat => 'Lipides';

  @override
  String get scanEditAmount => 'Corriger la quantité';

  @override
  String get scanRemoveItem => 'Supprimer la fausse détection';

  @override
  String get scanAmountGrams => 'Quantité en grammes';

  @override
  String get scanOriginalAiRange => 'Plage IA d’origine';

  @override
  String get scanUsdaSource => 'Source USDA';

  @override
  String get scanNutritionMissing =>
      'Poids uniquement — aucune donnée USDA complète';

  @override
  String get scanPartialTotal => 'Total partiel';

  @override
  String get scanCompleteTotal => 'Total complet';

  @override
  String get scanFoodDisclaimer =>
      'Estimation approximative à partir d’une photo. Ni dispositif médical ni conseil diététique.';

  @override
  String get scanFoodEditTitle => 'Corriger la quantité';

  @override
  String get scanFoodEditBody =>
      'Les totaux utiliseront votre quantité ; la plage IA d’origine restera visible.';

  @override
  String get scanFoodAmountPositive =>
      'Saisissez une quantité supérieure à zéro.';

  @override
  String get scanFoodAtLeastOne =>
      'Conservez au moins un composant alimentaire.';

  @override
  String get scanRemove => 'Supprimer';

  @override
  String get rewardAdsFundAnalysis =>
      'Les publicités financent la véritable analyse par IA';

  @override
  String get rewardHeadline => 'Obtenir plus de scans IA';

  @override
  String get rewardBody =>
      'Regardez une publicité récompensée pour un scan, ou débloquez des scans illimités et supprimez les publicités avec un achat unique.';

  @override
  String rewardMaxBalance(int count) {
    return 'Max. $count';
  }

  @override
  String get rewardSyncPending => 'Synchronisation du crédit en attente';

  @override
  String get rewardSafeToClose =>
      'Vous pouvez fermer cet écran. Nous continuerons les vérifications pendant 24 heures.';

  @override
  String get rewardChecking => 'Vérification';

  @override
  String get rewardCheck => 'Vérifier';

  @override
  String get rewardAdding => 'Ajout du scan…';

  @override
  String rewardAnotherAdMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return 'Nouvelle publicité dans $_temp0';
  }

  @override
  String rewardAnotherAdSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count s',
      one: '1 s',
    );
    return 'Nouvelle publicité dans $_temp0';
  }

  @override
  String get rewardUnavailable => 'Publicités récompensées indisponibles';

  @override
  String get rewardWatchForOne => 'Voir une publicité · +1 scan';

  @override
  String get rewardLoading => 'Chargement de la publicité récompensée';

  @override
  String get rewardUseLegacyFirst =>
      'Utilisez votre crédit sans publicité avant d’obtenir d’autres scans.';

  @override
  String get rewardAccessStateUnavailable =>
      'Les publicités récompensées ne sont pas disponibles avec cet état d’accès.';

  @override
  String get rewardConsentUnavailable =>
      'Les publicités sont indisponibles en raison du consentement ou de la configuration. Vos scans actuels et les fonctions sans IA restent disponibles.';

  @override
  String get rewardPrivacyChoices => 'Choix de confidentialité';

  @override
  String get rewardTryLoadingAgain => 'Relancer le chargement';

  @override
  String get rewardUnlockUnlimited => 'Débloquer l’illimité';

  @override
  String get drawerUpgradeUnlimited => 'Passer à Illimité';

  @override
  String get rewardCreditStillSyncing =>
      'Le crédit de scan est toujours en cours de synchronisation.';

  @override
  String get rewardNoCreditAdded =>
      'Aucun crédit de scan en attente n’a été ajouté.';

  @override
  String get accessLoadingBalance => 'Chargement…';

  @override
  String get accessPreview => 'Aperçu de l’accès';

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
    return 'Départ : $starter · Pub : $rewarded · Anciens : $legacy';
  }

  @override
  String get accessStarterThenAd => '2 scans gratuits, puis 1 scan par pub';

  @override
  String get accessGetOne => '+1';

  @override
  String get accessUnlimitedScans => 'Scans illimités';

  @override
  String get accessLifetimeActive => 'Accès à vie actif';

  @override
  String accessBuyLifetime(String price) {
    return 'Débloquer illimité · $price';
  }

  @override
  String get accessRestorePurchases => 'Restaurer les achats';

  @override
  String get accessLifetimeUnlocked =>
      'L’accès à vie est actif sur cet appareil.';

  @override
  String get accessLifetimeLoadingPrice => 'Chargement du prix…';

  @override
  String get paywallEyebrow => 'Analyse photo IA réelle';

  @override
  String get paywallHeadline => 'Estimations photo.';

  @override
  String get paywallHeadlineAccent => 'Débloquez';

  @override
  String get paywallHeadlineRest => 'Explorez avec l’IA.';

  @override
  String get paywallHeroSubtitle =>
      'Explorez objets et aliments à partir de photos.\nDes estimations, pas des mesures de poids.';

  @override
  String get paywallSocialProof => 'Payez une fois · gardez-le';

  @override
  String get paywallSocialSubline => 'Scans IA illimités. Zéro pub.';

  @override
  String get paywallUnlockLifetime => 'Débloquer l’accès à vie';

  @override
  String paywallTrustPriced(String price) {
    return 'Achat unique · $price';
  }

  @override
  String get paywallOneTimeCaption => 'Paiement unique';

  @override
  String get paywallLuggageLabel => 'Scan bagage';

  @override
  String get paywallLuggageTitle => 'Valise cabine';

  @override
  String get paywallLuggageWeight => '2–4 kg';

  @override
  String get paywallLuggageConfidence => 'Exemple d’estimation';

  @override
  String get paywallFeatureHeading => 'PETITS OBJETS. GRANDES POSSIBILITÉS.';

  @override
  String get paywallFeatureUnlimited => 'Scans illimités';

  @override
  String get paywallFeatureNoAds => 'Sans pub';

  @override
  String get paywallFeatureNutrition => 'Découvrez votre assiette';

  @override
  String get paywallFeatureNutritionSub =>
      'Estimation des calories, protéines et macros';

  @override
  String get paywallFeatureLuggage => 'Estimations d’objets';

  @override
  String get paywallFeatureLuggageSub => 'Éléments visibles ; contenu inconnu';

  @override
  String get paywallFeatureObjects => 'Visez. Capturez. Estimez.';

  @override
  String get paywallFeatureObjectsSub =>
      'Fourchettes approximatives selon les éléments visibles';

  @override
  String get paywallPhotoScanLabel => 'SCAN PHOTO IA';

  @override
  String get paywallEstimateExample => 'Estimation IA · exemple';

  @override
  String get paywallIllustrativeReadings =>
      'Illustrations uniquement. Une photo ne mesure pas le poids réel.';

  @override
  String get paywallLifetimeOffer => 'Accès à vie · Sans pub';

  @override
  String get paywallPurchaseTrust =>
      'Un seul paiement. Sans abonnement. Google Play.';

  @override
  String get paywallTerms => 'Conditions';

  @override
  String get paywallPrivacy => 'Confidentialité';

  @override
  String get paywallFeatureLifetime => 'Illimité + sans pub';

  @override
  String get paywallFeatureLifetimeSub => 'Un achat. À vous.';

  @override
  String get paywallOneTimeBadge => 'Achat unique';

  @override
  String get paywallLifetimePlan => 'Accès à vie';

  @override
  String get paywallContinueFree => 'Continuer avec les scans gratuits';

  @override
  String get paywallPurchaseUnavailable => 'Achat indisponible';

  @override
  String get nativeSponsored => 'Contenu sponsorisé';

  @override
  String get nativeTestLoading =>
      'Sponsorisé · chargement de la publicité test…';

  @override
  String get nativeTestRetrying => 'Nouvel essai de la publicité test…';

  @override
  String get accessGetFreeScan => 'Scan gratuit';

  @override
  String get settingsReminders => 'Rappels';

  @override
  String get mealReminderTitle => 'Rappel repas quotidien';

  @override
  String mealReminderOnBody(String time) {
    return 'Chaque jour à $time, sauf si vous venez d\'enregistrer un repas';
  }

  @override
  String get mealReminderOffBody =>
      'Un rappel par jour pour enregistrer vos repas';

  @override
  String get mealReminderTime => 'Heure du rappel';

  @override
  String get mealReminderPermissionDenied =>
      'Les notifications sont bloquées. Autorisez-les pour MassLens dans les réglages du téléphone.';

  @override
  String mealReminderEnabled(String time) {
    return 'Rappel programmé chaque jour à $time.';
  }

  @override
  String get mealReminderPromptTitle => 'Gardez votre série';

  @override
  String get mealReminderPromptBody =>
      'Recevez un rappel quotidien pour enregistrer vos repas. Vous pouvez changer l\'heure dans les Réglages.';

  @override
  String get mealReminderPromptAction => 'Activer le rappel';

  @override
  String get mealReminderPromptDismiss => 'Plus tard';

  @override
  String get mealReminderNotificationTitle =>
      'C\'est l\'heure d\'enregistrer votre repas';

  @override
  String get mealReminderNotificationBody =>
      'Photographiez votre assiette dans MassLens pour suivre vos calories et garder votre série.';

  @override
  String get mealReminderChannelName => 'Rappels repas';

  @override
  String get barcodeScanAction => 'Scanner un code-barres';

  @override
  String get barcodeScanActionBody =>
      'Produits emballés · gratuit, sans crédit de scan';

  @override
  String get barcodeFreeBadge => 'GRATUIT';

  @override
  String get barcodeScannerHint => 'Centrez le code-barres dans le cadre';

  @override
  String get barcodeTypeNumber => 'Saisir le numéro';

  @override
  String get barcodeTorch => 'Lampe torche';

  @override
  String get barcodeEnterTitle => 'Saisir le numéro du code-barres';

  @override
  String get barcodeInvalid =>
      'Saisissez un code-barres valide à 8, 12 ou 13 chiffres.';

  @override
  String get barcodeLookingUp => 'Recherche du produit…';

  @override
  String get barcodeNotFoundTitle => 'Produit introuvable';

  @override
  String barcodeNotFoundBody(String code) {
    return 'Le code-barres $code n’est pas encore dans Open Food Facts ni dans USDA FoodData Central. Vous pouvez saisir les valeurs de l’étiquette.';
  }

  @override
  String get barcodeUnavailableTitle => 'Impossible de rechercher ce produit';

  @override
  String get barcodeUnavailableBody => 'Vérifiez votre connexion et réessayez.';

  @override
  String get barcodeRetry => 'Réessayer';

  @override
  String get barcodeEnterManually => 'Saisir manuellement';

  @override
  String get barcodeScanAgain => 'Scanner à nouveau';

  @override
  String barcodePer100(String unit) {
    return 'Pour 100 $unit';
  }

  @override
  String barcodeServing(String amount) {
    return '1 portion · $amount';
  }

  @override
  String barcodeWholePack(String amount) {
    return 'Paquet entier · $amount';
  }

  @override
  String get barcodeYourPortion => 'Votre portion';

  @override
  String get barcodeAmountEaten => 'Quantité consommée';

  @override
  String get barcodePartialNutrition =>
      'Certains macros manquent dans les données de ce produit et comptent pour 0.';

  @override
  String get barcodeAddToDiary => 'Ajouter au journal';

  @override
  String get barcodeSourceOpenFoodFacts =>
      'Données d’étiquette issues d’Open Food Facts (ODbL). Vérifiez l’emballage : les valeurs peuvent être incomplètes ou obsolètes.';

  @override
  String get barcodeSourceUsda =>
      'Données d’étiquette issues de USDA FoodData Central. Vérifiez l’emballage : les valeurs peuvent être incomplètes ou obsolètes.';

  @override
  String get barcodeRecentTitle => 'Produits récents';

  @override
  String get barcodeRecentBody => 'Ajouter un produit déjà scanné';

  @override
  String barcodeKcalPer100(String value, String unit) {
    return '$value kcal / 100 $unit';
  }
}
