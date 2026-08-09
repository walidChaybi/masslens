// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MassLens';

  @override
  String get commonCancel => 'Annuler';

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
  String get onboardingAccessTitle => 'Trois véritables scans IA sont inclus.';

  @override
  String get onboardingAccessBody =>
      'MassLens vérifie votre solde sécurisé avant l’analyse. Prendre ou vérifier une photo n’utilise jamais de scan.';

  @override
  String get onboardingAdsEyebrow => 'Les publicités financent les scans';

  @override
  String get onboardingAdsTitle => 'Sans abonnement. Sans packs de scans.';

  @override
  String get onboardingAdsBody =>
      'Après les scans inclus, regardez une publicité récompensée jusqu’au bout pour ajouter un véritable scan IA.';

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
      'Photographiez un objet pour obtenir une plage de poids honnête, des dimensions visuelles et les indices ayant guidé l’estimation.';

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
      'Nous préparons vos trois scans de départ et l’accès financé par la publicité.';

  @override
  String get onboardingPreparingCta => 'Vérification…';

  @override
  String get onboardingReadyTitle => 'Vous êtes prêt à scanner';

  @override
  String get onboardingReadyBody => 'Vos 3 premiers scans IA sont inclus.';

  @override
  String get onboardingReadyCta => 'C’est parti';

  @override
  String get onboardingScanAccessLabel => 'Accès aux scans';

  @override
  String get onboardingAdSupportLabel => 'Financé par la publicité';

  @override
  String get onboardingThreeStarterScans => '3 scans de départ';

  @override
  String get onboardingPreparingStatus => 'Préparation…';

  @override
  String get onboardingReadyStatus => 'Prêt';

  @override
  String get onboardingRetryStatus => 'Réessayer';

  @override
  String get homeAiWeight => 'Poids par IA';

  @override
  String homeScansLeftGetOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restants · +1',
      one: '1 restant · +1',
      zero: '0 restant · +1',
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
  String get shellDigitalScale => 'Balance numérique';

  @override
  String get shellAiWeightScan => 'Scan de poids par IA';

  @override
  String get shellHistory => 'Historique';

  @override
  String get shellCaptureGuide => 'Guide de prise de vue';

  @override
  String get shellSettings => 'Réglages';

  @override
  String get shellOpenNavigationMenu => 'Ouvrir le menu de navigation';

  @override
  String get shellChooseMode =>
      'Choisissez une balance physique ou une estimation par photo avec l’IA.';

  @override
  String get shellMeasurementNotice =>
      'Les données Bluetooth sont des mesures. Le mode tactile est un simulateur ; les scans IA sont de véritables estimations visuelles.';

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
  String get settingsBluetoothSupport =>
      'Prise en charge des balances Bluetooth';

  @override
  String get settingsStandardBle => 'BLE WSS standard';

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
    return '$usage · une publicité pour un scan';
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
  String get settingsVersion => 'MVP 1.0.0';

  @override
  String get settingsSafetyBody =>
      'Une balance Bluetooth compatible fournit des mesures physiques. Le mode tactile est un simulateur interactif et les scans IA sont de véritables estimations visuelles. N’utilisez jamais MassLens pour un dosage médical, une transaction commerciale réglementée ou toute autre décision critique pour la sécurité.';

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
  String get scanTryAnother => 'Essayer un autre objet';

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
  String get scaleWatchAdGetScan => 'Voir une pub · +1 scan';

  @override
  String get scaleSimulatorStatus => 'SIMULATEUR · PAS UNE MESURE';

  @override
  String get scaleLiveStatus => 'DIRECT · BALANCE BLUETOOTH';

  @override
  String get scaleDisconnectedStatus => 'BLUETOOTH · NON CONNECTÉ';

  @override
  String get scaleSimulatorSemantics =>
      'Simulateur de balance tactile, pas une mesure physique';

  @override
  String get scaleLiveSemantics => 'Mesure en direct de la balance Bluetooth';

  @override
  String get scaleDisconnectedSemantics => 'Balance Bluetooth déconnectée';

  @override
  String get scaleOpenNavigation => 'Ouvrir le menu de navigation';

  @override
  String get scaleOpenAiScan => 'Scan de poids par IA';

  @override
  String get scaleBluetooth => 'Balance Bluetooth';

  @override
  String get scaleGenericDevice => 'Balance de poids Bluetooth';

  @override
  String get scaleUnit => 'UNITÉ';

  @override
  String get scaleTare => 'TARE';

  @override
  String get scaleCloseBluetooth => 'Fermer le panneau Bluetooth';

  @override
  String get scaleReceivingMeasurements =>
      'Réception des mesures standard de la balance';

  @override
  String get scaleBleSupport =>
      'Compatible avec le service BLE Weight Scale (0x181D)';

  @override
  String get scaleDisconnect => 'Déconnecter la balance';

  @override
  String get scaleSearching => 'Recherche…';

  @override
  String get scaleFindCompatible => 'Rechercher des balances compatibles';

  @override
  String get scaleAvailableScales => 'BALANCES DISPONIBLES';

  @override
  String get scaleCompatible => 'Balance compatible';

  @override
  String scaleSignal(int rssi) {
    return 'Signal $rssi dBm';
  }

  @override
  String get scaleNoneFound =>
      'Aucune balance standard trouvée. Vérifiez qu’elle est active et non connectée à une autre application, puis réessayez.';

  @override
  String get scalePrivateProtocolNotice =>
      'De nombreuses balances de cuisine utilisent des protocoles privés du fabricant. Elles nécessitent une intégration propre au modèle, même si elles apparaissent dans les réglages Bluetooth du téléphone.';

  @override
  String get scalePermissionNeeded =>
      'L’autorisation Appareils à proximité est requise pour rechercher une balance.';

  @override
  String get scalePowerOnBluetooth =>
      'Activez le Bluetooth, puis relancez la recherche.';

  @override
  String get scaleCommunicationFailed =>
      'Impossible de communiquer avec cette balance.';

  @override
  String get scalePhaseIdle => 'Aucune balance connectée';

  @override
  String get scalePhasePermission => 'Demande d’autorisation';

  @override
  String get scalePhaseScanning => 'Recherche à proximité';

  @override
  String get scalePhaseConnecting => 'Connexion';

  @override
  String get scalePhaseDiscovering => 'Vérification de la compatibilité';

  @override
  String get scalePhaseSubscribing => 'Démarrage des mesures en direct';

  @override
  String get scalePhaseConnected => 'Balance connectée';

  @override
  String get scalePhaseDisconnecting => 'Déconnexion';

  @override
  String get scalePhaseUnavailable => 'Bluetooth indisponible';

  @override
  String get scalePhaseError => 'La connexion nécessite votre attention';

  @override
  String get scalePhaseClosed => 'Lecteur fermé';

  @override
  String get rewardAdsFundAnalysis =>
      'Les publicités financent la véritable analyse par IA';

  @override
  String get rewardHeadline => 'Une publicité. Un scan.';

  @override
  String get rewardBody =>
      'Regardez la publicité jusqu’au bout et MassLens ajoute un scan. Sans abonnement, achat ni résultat fictif.';

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
  String get rewardCreditStillSyncing =>
      'Le crédit de scan est toujours en cours de synchronisation.';

  @override
  String get rewardNoCreditAdded =>
      'Aucun crédit de scan en attente n’a été ajouté.';

  @override
  String get accessLoadingBalance => 'Chargement du solde de scans…';

  @override
  String get accessPreview => 'Aperçu de l’accès';

  @override
  String accessScansLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans restants',
      one: '1 scan restant',
      zero: 'Aucun scan disponible',
    );
    return '$_temp0';
  }

  @override
  String accessScansAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scans disponibles',
      one: '1 scan disponible',
      zero: 'Aucun scan disponible',
    );
    return '$_temp0';
  }

  @override
  String accessBreakdown(int starter, int rewarded, int legacy) {
    return 'Départ : $starter · Pub : $rewarded · Anciens : $legacy';
  }

  @override
  String get accessStarterThenAd => '3 scans de départ, puis une publicité';

  @override
  String get accessGetOne => '+1';

  @override
  String get nativeSponsored => 'Contenu sponsorisé';

  @override
  String get nativeTestLoading =>
      'Sponsorisé · chargement de la publicité test…';

  @override
  String get nativeTestRetrying => 'Nouvel essai de la publicité test…';
}
