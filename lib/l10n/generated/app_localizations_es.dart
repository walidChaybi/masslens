// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MassLens';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonDone => 'Listo';

  @override
  String get commonRetry => 'Intentar de nuevo';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaved => 'Guardado';

  @override
  String get commonStartOver => 'Empezar de nuevo';

  @override
  String get commonUnknown => 'Desconocido';

  @override
  String get confidenceLow => 'Baja';

  @override
  String get confidenceMedium => 'Media';

  @override
  String get confidenceHigh => 'Alta';

  @override
  String get confidenceLowLabel => 'Confianza baja';

  @override
  String get confidenceMediumLabel => 'Confianza media';

  @override
  String get confidenceHighLabel => 'Confianza alta';

  @override
  String get measurementToday => 'Hoy';

  @override
  String measurementTodayAt(String time) {
    return 'Hoy, $time';
  }

  @override
  String get measurementYesterday => 'Ayer';

  @override
  String get categoryFood => 'Alimentos';

  @override
  String get categoryParcel => 'Paquete';

  @override
  String get categoryFurniture => 'Mueble';

  @override
  String get categoryElectronics => 'Electrónica';

  @override
  String get categoryLuggage => 'Equipaje';

  @override
  String get categoryTool => 'Herramienta';

  @override
  String get categoryClothing => 'Ropa';

  @override
  String get categoryHousehold => 'Objeto doméstico';

  @override
  String get categoryOther => 'Otro';

  @override
  String get materialUnknown => 'Desconocido';

  @override
  String get materialPlastic => 'Plástico';

  @override
  String get materialMetal => 'Metal';

  @override
  String get materialGlassCeramic => 'Vidrio/Cerámica';

  @override
  String get materialWood => 'Madera';

  @override
  String get materialCardboardPaper => 'Cartón/Papel';

  @override
  String get materialFabric => 'Tela';

  @override
  String get materialFoodLiquid => 'Alimento/Líquido';

  @override
  String get materialMixed => 'Mixto';

  @override
  String get fillUnknown => 'Desconocido';

  @override
  String get fillSolid => 'Sólido';

  @override
  String get fillEmpty => 'Vacío';

  @override
  String get fillPartlyFilled => 'Parcialmente lleno';

  @override
  String get fillFull => 'Lleno';

  @override
  String get referenceNone => 'Ninguna';

  @override
  String get referenceRuler => 'Regla';

  @override
  String get referenceStandardCard => 'Tarjeta estándar';

  @override
  String get axisLength => 'Longitud';

  @override
  String get axisWidth => 'Anchura';

  @override
  String get axisHeight => 'Altura';

  @override
  String get axisDepth => 'Profundidad';

  @override
  String get onboardingSkip => 'Omitir';

  @override
  String get onboardingStartScanning => 'Empezar a escanear';

  @override
  String get onboardingNoAccountNeeded => 'No necesitas una cuenta';

  @override
  String get onboardingSavedHistoryControl =>
      'Tú controlas el historial guardado';

  @override
  String get onboardingResponsibleEstimates =>
      'Diseñado para estimaciones responsables';

  @override
  String get onboardingPrivateBadge => 'Privado';

  @override
  String get onboardingInstantBadge => 'Instantáneo';

  @override
  String onboardingStepOfTotal(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get onboardingVisualEyebrow => 'Estimación visual';

  @override
  String get onboardingVisualTitle => 'Estima lo que no puedes pesar.';

  @override
  String get onboardingVisualBody =>
      'Captura un objeto para obtener un intervalo de peso útil, dimensiones supuestas por la IA y las hipótesis de la estimación.';

  @override
  String get onboardingHonestEyebrow => 'Honesto por diseño';

  @override
  String get onboardingHonestTitle =>
      'Un intervalo, no una cifra exacta inventada.';

  @override
  String get onboardingHonestBody =>
      'MassLens muestra la confianza y la incertidumbre porque una fotografía ofrece una estimación, no la medición de una báscula.';

  @override
  String get onboardingPrivateEyebrow => 'La privacidad primero';

  @override
  String get onboardingPrivateTitle => 'Tus objetos siguen siendo tuyos.';

  @override
  String get onboardingPrivateBody =>
      'Se eliminan los metadatos de las fotos antes de enviarlas de forma segura para un análisis de IA real. El historial guardado permanece privado en tu dispositivo.';

  @override
  String get onboardingAccessEyebrow => 'Acceso a escaneos';

  @override
  String get onboardingAccessTitle => 'Se incluyen tres escaneos de IA reales.';

  @override
  String get onboardingAccessBody =>
      'MassLens comprueba tu saldo seguro antes del análisis. Capturar o revisar una foto nunca consume un escaneo.';

  @override
  String get onboardingAdsEyebrow => 'Los anuncios financian los escaneos';

  @override
  String get onboardingAdsTitle => 'Sin suscripción. Sin paquetes de escaneos.';

  @override
  String get onboardingAdsBody =>
      'Después de los escaneos incluidos, termina un anuncio recompensado para añadir un escaneo de IA real.';

  @override
  String get onboardingAccessPreparing => 'Preparando el acceso a escaneos…';

  @override
  String get onboardingAccessReady => 'Acceso a escaneos listo';

  @override
  String get onboardingAccessRetry => 'Reintentar el acceso a escaneos';

  @override
  String get onboardingAccessUnavailable =>
      'El acceso a escaneos no está disponible. Comprueba tu conexión e inténtalo de nuevo.';

  @override
  String get onboardingHeroTitle => 'Más información de un vistazo';

  @override
  String get onboardingHeroBody =>
      'Fotografía un objeto para obtener un intervalo de peso honesto, dimensiones visuales y la evidencia en la que se basa la estimación.';

  @override
  String get onboardingHeroCta => 'Empezar';

  @override
  String get onboardingFramingTitle => 'Mantén visible todo el objeto';

  @override
  String get onboardingFramingBody =>
      'Deja espacio alrededor de todos los bordes y evita que manos u otros elementos tapen el objeto.';

  @override
  String get onboardingFramingCta => 'Siguiente';

  @override
  String get onboardingLightTitle => 'Buena luz, fondo sencillo';

  @override
  String get onboardingLightBody =>
      'Una buena iluminación y una foto estable ayudan a la IA a reconocer la forma y el material con más precisión.';

  @override
  String get onboardingLightCta => 'Continuar';

  @override
  String get onboardingPreparingTitle => 'Casi listo';

  @override
  String get onboardingPreparingBody =>
      'Estamos preparando tus tres escaneos iniciales y el acceso financiado con anuncios.';

  @override
  String get onboardingPreparingCta => 'Comprobando…';

  @override
  String get onboardingReadyTitle => 'Ya puedes escanear';

  @override
  String get onboardingReadyBody =>
      'Tus 3 primeros escaneos de IA están incluidos.';

  @override
  String get onboardingReadyCta => 'Empezar';

  @override
  String get onboardingScanAccessLabel => 'Acceso a escaneos';

  @override
  String get onboardingAdSupportLabel => 'Financiado con anuncios';

  @override
  String get onboardingThreeStarterScans => '3 escaneos iniciales';

  @override
  String get onboardingPreparingStatus => 'Preparando…';

  @override
  String get onboardingReadyStatus => 'Listo';

  @override
  String get onboardingRetryStatus => 'Reintentar';

  @override
  String get homeAiWeight => 'Peso por IA';

  @override
  String homeScansLeftGetOne(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count · +1',
      one: 'Queda 1 · +1',
      zero: '0 disponibles · +1',
    );
    return '$_temp0';
  }

  @override
  String get homeLatestEstimate => 'Última estimación';

  @override
  String get homeHistory => 'Historial';

  @override
  String get homeScanObject => 'Escanear objeto';

  @override
  String get homePhoto => 'Foto';

  @override
  String get shellDigitalScale => 'Báscula digital';

  @override
  String get shellAiWeightScan => 'Escaneo de peso por IA';

  @override
  String get shellHistory => 'Historial';

  @override
  String get shellCaptureGuide => 'Guía de captura';

  @override
  String get shellSettings => 'Ajustes';

  @override
  String get shellOpenNavigationMenu => 'Abrir el menú de navegación';

  @override
  String get shellChooseMode =>
      'Elige una báscula física o una estimación fotográfica con IA.';

  @override
  String get shellMeasurementNotice =>
      'Las lecturas por Bluetooth son mediciones. El modo táctil es un simulador; los escaneos de IA son estimaciones visuales reales.';

  @override
  String get guideEyebrow => 'Mejor entrada, mejor intervalo';

  @override
  String get guideTitle => 'Guía de captura';

  @override
  String get guideIntro =>
      'Cuatro decisiones sencillas hacen más útil una estimación visual.';

  @override
  String get guideWholeObjectTitle => 'Muestra el objeto completo';

  @override
  String get guideWholeObjectBody =>
      'Deja espacio alrededor de todos los bordes. Evita que manos, etiquetas u otros objetos se superpongan al objetivo.';

  @override
  String get guideLightingTitle => 'Usa una luz suave y uniforme';

  @override
  String get guideLightingBody =>
      'Las sombras fuertes ocultan la forma. La luz del día o una habitación bien iluminada suelen ofrecer la evidencia visual más clara.';

  @override
  String get guideStructureTitle => 'Indica si es sólido o hueco';

  @override
  String get guideStructureBody =>
      'Una maleta y un bloque pueden ocupar el mismo volumen y pesar de forma muy distinta. La estructura acota la hipótesis de densidad.';

  @override
  String get guideSideViewTitle => 'Añade una vista lateral';

  @override
  String get guideSideViewBody =>
      'Muévete entre 45 y 90° alrededor del mismo objeto. Una segunda vista ayuda a la IA a inferir la forma, la construcción y el volumen.';

  @override
  String get guideUnderstandingConfidence => 'Entender la confianza';

  @override
  String get guideTryCapture => 'Probar una captura guiada';

  @override
  String get guideClearSubject => 'Objeto despejado';

  @override
  String get guideAllEdgesVisible =>
      'TODOS LOS BORDES VISIBLES  •  UN SOLO OBJETO';

  @override
  String get guideLowDetail => 'Una foto, escala o categoría inferida';

  @override
  String get guideMediumDetail => 'Categoría y estructura confirmadas';

  @override
  String get guideHighDetail => 'Dos ángulos nítidos y detalles útiles';

  @override
  String get historyEyebrow => 'Registro privado en el dispositivo';

  @override
  String get historyTitle => 'Historial de estimaciones';

  @override
  String get historyNewEstimate => 'Nueva estimación';

  @override
  String get historyAll => 'Todo';

  @override
  String get historyNothingSaved => 'Aún no hay nada guardado';

  @override
  String historyNoCategoryEstimates(String category) {
    return 'No hay estimaciones de $category';
  }

  @override
  String get historyEmptyBody =>
      'Guarda el resultado de tu primera estimación fotográfica y aparecerá aquí.';

  @override
  String get historyFilteredEmptyBody =>
      'Elige otro filtro o crea una nueva estimación.';

  @override
  String get historyStartEstimate => 'Iniciar estimación';

  @override
  String get historySavedStat => 'Guardadas';

  @override
  String get historyCategoriesStat => 'Categorías';

  @override
  String get historyLocalBadge => 'Local';

  @override
  String get detailDeleteTitle => '¿Eliminar esta estimación?';

  @override
  String get detailDeleteBody =>
      'Se eliminarán el resultado guardado y su copia privada de la imagen.';

  @override
  String get detailSavedEstimate => 'Estimación guardada';

  @override
  String get detailDeleteTooltip => 'Eliminar estimación';

  @override
  String get detailAiEstimate => 'Estimación por IA';

  @override
  String get detailEstimatedWeight => 'PESO ESTIMADO';

  @override
  String get detailLikelyRange => 'Intervalo probable';

  @override
  String get detailAiVisualSize => 'Tamaño visual por IA';

  @override
  String get detailDimensionOrder =>
      'Longitud × anchura × altura · hipótesis visual';

  @override
  String get detailAssumptions => 'Hipótesis';

  @override
  String get detailSafetyNotice =>
      'Esta es una estimación visual fundamentada, no una lectura de sensor. No la uses para decisiones críticas de seguridad.';

  @override
  String get settingsEyebrow => 'Preferencias y privacidad';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsMeasurement => 'Medición';

  @override
  String get settingsUnits => 'Unidades';

  @override
  String get settingsUnitsBody =>
      'Todos los valores se almacenan canónicamente en el sistema métrico.';

  @override
  String get settingsMetric => 'Métrico';

  @override
  String get settingsImperial => 'Imperial';

  @override
  String get settingsBluetoothSupport =>
      'Compatibilidad con básculas Bluetooth';

  @override
  String get settingsStandardBle => 'BLE WSS estándar';

  @override
  String get settingsEngine => 'Motor';

  @override
  String get settingsAnalysisMode => 'Modo de análisis';

  @override
  String get settingsAnalysisSecureCloudAi => 'IA segura en la nube';

  @override
  String get settingsCloudUploads => 'Cargas en la nube';

  @override
  String get settingsCloudViaSecureApi => 'Mediante API segura';

  @override
  String get settingsProductionModel => 'Modelo de producción';

  @override
  String get settingsScanCredits => 'Créditos de escaneo';

  @override
  String get settingsEarnAiScans => 'Conseguir escaneos de IA';

  @override
  String settingsEarnAiScansBody(String usage) {
    return '$usage · un anuncio por un escaneo';
  }

  @override
  String get settingsPrivacy => 'Privacidad';

  @override
  String get settingsSavedPhotos => 'Fotos guardadas';

  @override
  String get settingsPrivateStorage => 'Almacenamiento privado';

  @override
  String get settingsAdPrivacyChoices => 'Opciones de privacidad de anuncios';

  @override
  String get settingsReviewConsent => 'Revisar o cambiar el consentimiento';

  @override
  String get settingsClearHistory => 'Borrar el historial de estimaciones';

  @override
  String get settingsNoSavedEstimates => 'No hay estimaciones guardadas';

  @override
  String settingsSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count guardadas',
      one: '1 guardada',
      zero: 'Ninguna estimación guardada',
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsClearHistoryTitle => '¿Borrar todo el historial?';

  @override
  String settingsClearHistoryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán de este dispositivo $count estimaciones guardadas y sus copias privadas de las imágenes.',
      one:
          'Se eliminarán de este dispositivo 1 estimación guardada y su copia privada de la imagen.',
      zero: 'No se eliminarán estimaciones ni copias privadas de imágenes.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearHistoryAction => 'Borrar historial';

  @override
  String get settingsHistoryCleared =>
      'Se ha borrado el historial de estimaciones.';

  @override
  String get settingsVersion => 'MVP 1.0.0';

  @override
  String get settingsSafetyBody =>
      'Una báscula Bluetooth compatible proporciona mediciones físicas. El modo táctil es un simulador interactivo y los escaneos de IA son estimaciones visuales reales. Nunca uses MassLens para dosis médicas, comercio regulado u otras decisiones críticas de seguridad.';

  @override
  String get cameraUnavailable => 'La cámara no está disponible.';

  @override
  String get cameraAccessNeeded =>
      'Se necesita acceso a la cámara para fotografiar el objeto.';

  @override
  String get cameraUnavailableDevice =>
      'La cámara no está disponible en este dispositivo.';

  @override
  String get cameraCaptureFailed =>
      'No se pudo tomar la foto. Inténtalo de nuevo.';

  @override
  String get cameraCloseTooltip => 'Cerrar';

  @override
  String get cameraTorchOffTooltip => 'Apagar la linterna';

  @override
  String get cameraTorchOnTooltip => 'Encender la linterna';

  @override
  String get cameraTakePhotoSemantics => 'Tomar foto';

  @override
  String get scanCameraOpenFailed => 'No se pudo abrir la cámara.';

  @override
  String get scanSelectedPhotoOpenFailed =>
      'No se pudo abrir la foto seleccionada.';

  @override
  String get scanSecondPhotoOpenFailed => 'No se pudo abrir la segunda foto.';

  @override
  String get scanDimensionPositive => 'Introduce una dimensión mayor que cero.';

  @override
  String get scanAccessUnverified =>
      'No se pudo verificar el acceso a escaneos. Comprueba la conexión e inténtalo de nuevo; no se usó ningún escaneo.';

  @override
  String get scanLimitReached => 'Has usado todos tus escaneos disponibles.';

  @override
  String get scanAnalysisStopped =>
      'El análisis se detuvo. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get scanCoachTitle => 'Asistente de captura';

  @override
  String get scanCoachNoCredit =>
      'No se usa ningún escaneo hasta que continúes con el análisis.';

  @override
  String get scanCoachRetake => 'Repetir';

  @override
  String get scanCoachUseAnyway => 'Usar de todos modos';

  @override
  String get scanSavedPrivateHistory => 'Guardado en tu historial privado.';

  @override
  String get scanOptionalDetails => 'Detalles opcionales';

  @override
  String get scanMaterial => 'Material';

  @override
  String get scanFill => 'Relleno';

  @override
  String get scanKnownSize => 'Tamaño conocido (opcional)';

  @override
  String get scanVisibleReference => 'Referencia visible';

  @override
  String get scanEstimate => 'Estimar';

  @override
  String get scanAnalyzing => 'Analizando';

  @override
  String get scanNewEstimate => 'Nueva estimación';

  @override
  String get scanReview => 'Revisar';

  @override
  String get scanPhotographObject => 'Fotografía un objeto';

  @override
  String get scanTakePhoto => 'Tomar foto';

  @override
  String get scanChooseGallery => 'Elegir de la galería';

  @override
  String get scanConfirmObject => 'Confirma el objeto';

  @override
  String get scanDetails => 'Detalles';

  @override
  String get scanAddSideView => 'Añadir vista lateral';

  @override
  String get scanSideViewAdded => 'Vista lateral añadida';

  @override
  String get scanSideViewOptional =>
      'Opcional · muévete entre 45 y 90° alrededor del mismo objeto';

  @override
  String get scanSideViewBenefit =>
      'Otro ángulo ayuda a la IA a inferir la forma y el volumen';

  @override
  String get scanAdd => 'Añadir';

  @override
  String get scanReplace => 'Reemplazar';

  @override
  String get scanRemoveSideView => 'Eliminar vista lateral';

  @override
  String get scanProgressShape => 'Analizando la forma';

  @override
  String get scanProgressMaterial => 'Estimando el material';

  @override
  String get scanProgressRange => 'Calculando el intervalo';

  @override
  String get scanLikelyRange => 'INTERVALO PROBABLE';

  @override
  String get scanAiVisualSize => 'Tamaño visual por IA · L × An × Al';

  @override
  String get scanConfidence => 'Confianza';

  @override
  String get scanHowEstimated => 'Cómo se hizo la estimación';

  @override
  String get scanTryAnother => 'Probar otro';

  @override
  String get scanSecondViewTitle => 'Añadir una vista lateral';

  @override
  String get scanSecondViewBody =>
      'Muévete entre 45 y 90° alrededor del mismo objeto y mantenlo completamente visible. Esta vista usa el mismo crédito de escaneo.';

  @override
  String get scanChoosePhoto => 'Elegir foto';

  @override
  String get scanPhotoDarkWarning =>
      'La foto está oscura. Una luz más uniforme mejorará el reconocimiento del material.';

  @override
  String get scanPhotoBlurryWarning =>
      'La foto parece borrosa. Mantén el teléfono estable y el objeto enfocado.';

  @override
  String get scanPhotoMissing => 'No se encontró la foto.';

  @override
  String get scanPhotoCorrupt =>
      'Esta foto está dañada o no es compatible. Vuelve a tomarla como imagen JPEG.';

  @override
  String get scanPhotoTooSmall =>
      'Esta foto es demasiado pequeña. Usa una imagen de al menos 320 × 320 píxeles.';

  @override
  String get scanCloudFailure =>
      'No se pudo completar el análisis de IA. Comprueba la conexión e inténtalo de nuevo; no se creó ningún resultado ficticio.';

  @override
  String get scaleWatchAdGetScan => 'Ver anuncio · +1 escaneo';

  @override
  String get scaleSimulatorStatus => 'SIMULADOR · NO ES UNA MEDICIÓN';

  @override
  String get scaleLiveStatus => 'EN VIVO · BÁSCULA BLUETOOTH';

  @override
  String get scaleDisconnectedStatus => 'BLUETOOTH · SIN CONEXIÓN';

  @override
  String get scaleSimulatorSemantics =>
      'Simulador de báscula táctil, no una medición física';

  @override
  String get scaleLiveSemantics => 'Lectura en vivo de una báscula Bluetooth';

  @override
  String get scaleDisconnectedSemantics => 'Báscula Bluetooth desconectada';

  @override
  String get scaleOpenNavigation => 'Abrir el menú de navegación';

  @override
  String get scaleOpenAiScan => 'Escaneo de peso por IA';

  @override
  String get scaleBluetooth => 'Báscula Bluetooth';

  @override
  String get scaleGenericDevice => 'Báscula de peso Bluetooth';

  @override
  String get scaleUnit => 'UNIDAD';

  @override
  String get scaleTare => 'TARA';

  @override
  String get scaleCloseBluetooth => 'Cerrar el panel de Bluetooth';

  @override
  String get scaleReceivingMeasurements =>
      'Recibiendo mediciones estándar de la báscula';

  @override
  String get scaleBleSupport =>
      'Compatible con el servicio BLE Weight Scale (0x181D)';

  @override
  String get scaleDisconnect => 'Desconectar báscula';

  @override
  String get scaleSearching => 'Buscando…';

  @override
  String get scaleFindCompatible => 'Buscar básculas compatibles';

  @override
  String get scaleAvailableScales => 'BÁSCULAS DISPONIBLES';

  @override
  String get scaleCompatible => 'Báscula compatible';

  @override
  String scaleSignal(int rssi) {
    return 'Señal $rssi dBm';
  }

  @override
  String get scaleNoneFound =>
      'No se encontró ninguna báscula estándar. Asegúrate de que esté activa y no conectada a otra aplicación e inténtalo de nuevo.';

  @override
  String get scalePrivateProtocolNotice =>
      'Muchas básculas de cocina usan protocolos privados del fabricante. Requieren una integración específica para cada modelo, aunque aparezcan en los ajustes de Bluetooth del teléfono.';

  @override
  String get scalePermissionNeeded =>
      'Se necesita permiso para dispositivos cercanos a fin de encontrar una báscula.';

  @override
  String get scalePowerOnBluetooth => 'Activa el Bluetooth y vuelve a buscar.';

  @override
  String get scaleCommunicationFailed =>
      'No se pudo comunicar con esta báscula.';

  @override
  String get scalePhaseIdle => 'No hay ninguna báscula conectada';

  @override
  String get scalePhasePermission => 'Solicitando permiso';

  @override
  String get scalePhaseScanning => 'Buscando cerca';

  @override
  String get scalePhaseConnecting => 'Conectando';

  @override
  String get scalePhaseDiscovering => 'Comprobando compatibilidad';

  @override
  String get scalePhaseSubscribing => 'Iniciando lecturas en vivo';

  @override
  String get scalePhaseConnected => 'Báscula conectada';

  @override
  String get scalePhaseDisconnecting => 'Desconectando';

  @override
  String get scalePhaseUnavailable => 'Bluetooth no disponible';

  @override
  String get scalePhaseError => 'La conexión requiere atención';

  @override
  String get scalePhaseClosed => 'Lector cerrado';

  @override
  String get rewardAdsFundAnalysis =>
      'Los anuncios financian el análisis de IA real';

  @override
  String get rewardHeadline => 'Un anuncio. Un escaneo.';

  @override
  String get rewardBody =>
      'Termina el anuncio y MassLens añadirá un escaneo. Sin suscripción, compra ni resultado ficticio.';

  @override
  String rewardMaxBalance(int count) {
    return 'Máx. $count';
  }

  @override
  String get rewardSyncPending => 'Sincronización del crédito pendiente';

  @override
  String get rewardSafeToClose =>
      'Puedes cerrar esta pantalla. Seguiremos comprobando durante 24 horas.';

  @override
  String get rewardChecking => 'Comprobando';

  @override
  String get rewardCheck => 'Comprobar';

  @override
  String get rewardAdding => 'Añadiendo el escaneo…';

  @override
  String rewardAnotherAdMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return 'Otro anuncio en $_temp0';
  }

  @override
  String rewardAnotherAdSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count s',
      one: '1 s',
    );
    return 'Otro anuncio en $_temp0';
  }

  @override
  String get rewardUnavailable => 'Anuncios recompensados no disponibles';

  @override
  String get rewardWatchForOne => 'Ver un anuncio · +1 escaneo';

  @override
  String get rewardLoading => 'Cargando el anuncio recompensado';

  @override
  String get rewardUseLegacyFirst =>
      'Usa tu crédito sin anuncios antes de conseguir más escaneos.';

  @override
  String get rewardAccessStateUnavailable =>
      'Los anuncios recompensados no están disponibles para este estado de acceso.';

  @override
  String get rewardConsentUnavailable =>
      'Los anuncios no están disponibles debido al consentimiento o la configuración. Tus escaneos actuales y las funciones sin IA siguen disponibles.';

  @override
  String get rewardPrivacyChoices => 'Opciones de privacidad';

  @override
  String get rewardTryLoadingAgain => 'Intentar cargar de nuevo';

  @override
  String get rewardCreditStillSyncing =>
      'El crédito de escaneo aún se está sincronizando.';

  @override
  String get rewardNoCreditAdded =>
      'No se añadió ningún crédito de escaneo pendiente.';

  @override
  String get accessLoadingBalance => 'Cargando saldo de escaneos…';

  @override
  String get accessPreview => 'Vista previa del acceso';

  @override
  String accessScansLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Quedan $count escaneos',
      one: 'Queda 1 escaneo',
      zero: 'No hay escaneos disponibles',
    );
    return '$_temp0';
  }

  @override
  String accessScansAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escaneos disponibles',
      one: '1 escaneo disponible',
      zero: 'No hay escaneos disponibles',
    );
    return '$_temp0';
  }

  @override
  String accessBreakdown(int starter, int rewarded, int legacy) {
    return '$starter iniciales · $rewarded recompensados · $legacy anteriores';
  }

  @override
  String get accessStarterThenAd => '3 escaneos iniciales y después un anuncio';

  @override
  String get accessGetOne => '+1';

  @override
  String get nativeSponsored => 'Contenido patrocinado';

  @override
  String get nativeTestLoading => 'Patrocinado · cargando anuncio de prueba…';

  @override
  String get nativeTestRetrying => 'Reintentando el anuncio de prueba…';
}
