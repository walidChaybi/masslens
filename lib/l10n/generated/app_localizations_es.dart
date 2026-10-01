// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MassLens: Estimaciones foto';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonNo => 'No';

  @override
  String get commonOk => 'OK';

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
  String get commonShare => 'Compartir';

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
  String get referenceCoin => 'Moneda';

  @override
  String get scanReferenceTip =>
      'Consejo: para mayor precisión, coloca una moneda (o una tarjeta) junto al objeto.';

  @override
  String get funUnitAaBattery => 'pila AA';

  @override
  String get funUnitSmartphone => 'teléfono';

  @override
  String get funUnitBaguette => 'baguette';

  @override
  String get funUnitSodaCan => 'lata de refresco';

  @override
  String get funUnitSoccerBall => 'balón de fútbol';

  @override
  String get funUnitCat => 'gato';

  @override
  String get funUnitWatermelon => 'sandía';

  @override
  String get funUnitCarTire => 'neumático de coche';

  @override
  String get funUnitWashingMachine => 'lavadora';

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
  String get onboardingAccessTitle => 'Se incluyen dos escaneos de IA reales.';

  @override
  String get onboardingAccessBody =>
      'MassLens comprueba tu saldo seguro antes del análisis. Capturar o revisar una foto nunca consume un escaneo.';

  @override
  String get onboardingAdsEyebrow => 'Opciones de acceso';

  @override
  String get onboardingAdsTitle => '2 escaneos gratis, luego 1 por anuncio';

  @override
  String get onboardingAdsBody =>
      'Obtén dos escaneos de IA gratis. Después, mira un anuncio recompensado para conseguir un escaneo, o desbloquea escaneos ilimitados sin anuncios con una compra única de por vida.';

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
      'Estima el peso probable de un objeto a partir de lo visible. Las fotos no miden el peso real ni revelan el contenido oculto.';

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
      'Preparando tus dos escaneos gratis y el acceso con anuncios recompensados.';

  @override
  String get onboardingPreparingCta => 'Comprobando…';

  @override
  String get onboardingReadyTitle => 'Ya puedes escanear';

  @override
  String get onboardingReadyBody => 'Tus 2 primeros escaneos de IA son gratis.';

  @override
  String get onboardingReadyCta => 'Empezar';

  @override
  String get onboardingReviewTitle => 'Ayuda a crecer a MassLens';

  @override
  String get onboardingReviewBody =>
      '¿Te gustaría dejar una reseña sincera en Google Play? Solo lleva un momento y nos ayuda a mejorar.';

  @override
  String get onboardingReviewLater => 'Ahora no';

  @override
  String get onboardingReviewAction => 'Escribir reseña';

  @override
  String get onboardingScanAccessLabel => 'Acceso a escaneos';

  @override
  String get onboardingAdSupportLabel => 'Financiado con anuncios';

  @override
  String get onboardingThreeStarterScans => '2 escaneos gratis';

  @override
  String get onboardingPreparingStatus => 'Preparando…';

  @override
  String get onboardingReadyStatus => 'Listo';

  @override
  String get onboardingRetryStatus => 'Reintentar';

  @override
  String get homeAiWeight => 'Estimación fotográfica';

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
  String get homeLatestEstimate => 'Última estimación';

  @override
  String get homeHistory => 'Historial';

  @override
  String get homeScanObject => 'Escanear objeto';

  @override
  String get homePhoto => 'Foto';

  @override
  String get homeModeObject => 'Objeto';

  @override
  String get homeModeFoodMacros => 'Comida y macros';

  @override
  String get homeFoodModeHint =>
      'Fotografía un plato completo para estimar el peso, las calorías y los macros de cada alimento.';

  @override
  String get homeScanFood => 'Escanear plato';

  @override
  String get nutritionHomeTitle => 'Nutrición y tendencias';

  @override
  String get nutritionHomeBody =>
      'Registra calorías y macros en este dispositivo';

  @override
  String nutritionHomeTodayCalories(int count) {
    return '$count kcal registradas hoy';
  }

  @override
  String get shellAiWeightScan => 'Estimaciones de fotos';

  @override
  String get shellNutrition => 'Nutrición';

  @override
  String get shellHistory => 'Historial';

  @override
  String get shellCaptureGuide => 'Guía de captura';

  @override
  String get shellSettings => 'Ajustes';

  @override
  String get shellOpenNavigationMenu => 'Abrir el menú de navegación';

  @override
  String get shellChooseMode => 'Estimaciones de fotos y diario de nutrición.';

  @override
  String get shellMeasurementNotice =>
      'Los resultados son estimaciones inciertas. El teléfono no mide el peso. Usa una báscula física para medir.';

  @override
  String get shellExitTitle => '¿Salir de MassLens?';

  @override
  String get shellExitBody => '¿Seguro que quieres salir de la aplicación?';

  @override
  String get navScanShort => 'Escaneo IA';

  @override
  String get navGuideShort => 'Guía';

  @override
  String get homeHeroTitle => 'Explora un objeto con una foto';

  @override
  String get homeHeroBody =>
      'Obtén un intervalo de peso aproximado a partir de lo visible. Una foto no mide el peso ni revela el contenido oculto.';

  @override
  String get homeTipWhole => 'Objeto completo';

  @override
  String get homeTipLight => 'Buena luz';

  @override
  String get homeTipReference => 'Referencia de tamaño';

  @override
  String get nutritionEyebrow => 'Registro diario privado';

  @override
  String get nutritionTitle => 'Nutrición y tendencias';

  @override
  String get nutritionLocalBadge => 'En el dispositivo';

  @override
  String get nutritionDayTab => 'Día';

  @override
  String get nutritionTrendsTab => 'Tendencias';

  @override
  String get nutritionPreviousDay => 'Día anterior';

  @override
  String get nutritionNextDay => 'Día siguiente';

  @override
  String get nutritionToday => 'Hoy';

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
  String get nutritionProtein => 'Proteína';

  @override
  String get nutritionCarbs => 'Carbohidratos';

  @override
  String get nutritionFat => 'Grasa';

  @override
  String get nutritionProteinShort => 'P';

  @override
  String get nutritionCarbsShort => 'C';

  @override
  String get nutritionFatShort => 'G';

  @override
  String nutritionMacroCompact(int protein, int carbs, int fat) {
    return 'P $protein g · C $carbs g · G $fat g';
  }

  @override
  String nutritionMacroRingSemantics(
    int calories,
    int protein,
    int carbs,
    int fat,
  ) {
    return '$calories calorías, $protein gramos de proteína, $carbs gramos de carbohidratos y $fat gramos de grasa';
  }

  @override
  String get nutritionPartialNotice =>
      'Total parcial: al menos un alimento no tenía una coincidencia nutricional completa de USDA.';

  @override
  String get nutritionTrendPartialNotice =>
      'Este periodo incluye totales parciales de alimentos sin coincidencia completa.';

  @override
  String get nutritionPartialShort => 'Parcial';

  @override
  String get nutritionMealsTitle => 'Comidas';

  @override
  String get nutritionAddFood => 'Añadir';

  @override
  String get nutritionNoEntriesTitle => 'Nada registrado este día';

  @override
  String get nutritionNoEntriesBody =>
      'Añade una estimación de alimentos guardada o introduce calorías y macros manualmente.';

  @override
  String get nutritionFromScans => 'Desde escaneos de comida';

  @override
  String get nutritionFromScansBody =>
      'Copiar la nutrición corregida de un plato guardado';

  @override
  String get nutritionManual => 'Entrada manual';

  @override
  String get nutritionManualBody =>
      'Introduce las calorías y macros de una comida';

  @override
  String get nutritionNoScansTitle => 'No hay escaneos disponibles';

  @override
  String get nutritionNoScansBody =>
      'Guarda un escaneo de Comida y macros con nutrición USDA y vuelve aquí.';

  @override
  String get nutritionChooseScan => 'Elige un escaneo guardado';

  @override
  String get nutritionAddFromScanTitle => 'Añadir comida escaneada';

  @override
  String get nutritionAddManualTitle => 'Añadir nutrición manualmente';

  @override
  String get nutritionEditEntryTitle => 'Editar entrada nutricional';

  @override
  String get nutritionBreakfast => 'Desayuno';

  @override
  String get nutritionLunch => 'Almuerzo';

  @override
  String get nutritionDinner => 'Cena';

  @override
  String get nutritionSnack => 'Tentempié';

  @override
  String get nutritionMeal => 'Comida';

  @override
  String get nutritionLabel => 'Nombre del alimento o comida';

  @override
  String get nutritionWeightOptional => 'Peso (opcional)';

  @override
  String get nutritionCaloriesInput => 'Calorías';

  @override
  String get nutritionRequiredLabel =>
      'Introduce un nombre de alimento o comida.';

  @override
  String get nutritionInvalidNumber => 'Introduce un número positivo válido.';

  @override
  String get nutritionAtLeastOneValue =>
      'Introduce calorías o al menos un macro.';

  @override
  String get nutritionFutureDate =>
      'No se puede registrar nutrición en el futuro.';

  @override
  String get nutritionEdit => 'Editar';

  @override
  String get nutritionEntryActions => 'Acciones de la entrada nutricional';

  @override
  String get nutritionDeleteTitle => '¿Eliminar la entrada?';

  @override
  String nutritionDeleteBody(String label) {
    return '¿Quitar «$label» del registro nutricional local?';
  }

  @override
  String get nutritionTrendsTitle => 'Resumen nutricional';

  @override
  String get nutritionSevenDays => '7 días';

  @override
  String get nutritionThirtyDays => '30 días';

  @override
  String get nutritionAverageLoggedDays =>
      'Promedio de kcal en días registrados';

  @override
  String get nutritionLoggedDays => 'Días registrados';

  @override
  String get nutritionCaloriesTrend => 'Calorías diarias';

  @override
  String get nutritionMacroTrend => 'Tendencia de macros (gramos)';

  @override
  String nutritionCaloriesChartSemantics(int days, int calories) {
    return 'Gráfico de calorías de $days días con $calories calorías totales';
  }

  @override
  String nutritionMacrosChartSemantics(int days) {
    return 'Gráfico de proteína, carbohidratos y grasa de $days días';
  }

  @override
  String get nutritionDisclaimer =>
      'Guardado solo en este dispositivo. Los valores nutricionales son aproximados y no constituyen consejo médico ni dietético.';

  @override
  String get nutritionScanAMeal => 'Escanear una comida';

  @override
  String get nutritionOpenGallery => 'Elegir de la galería';

  @override
  String get nutritionRemainingLabel => 'restantes';

  @override
  String nutritionEatenKcal(String value) {
    return '$value consumidas';
  }

  @override
  String nutritionOverGoal(String value) {
    return '$value por encima del objetivo';
  }

  @override
  String get nutritionStreakZero => 'Empieza una racha';

  @override
  String nutritionStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Racha de $count días',
      one: 'Racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get nutritionDailyGoals => 'Objetivos diarios';

  @override
  String get nutritionCalorieGoal => 'Calorías diarias';

  @override
  String get nutritionEmptyTitle => 'Registra tu primera comida';

  @override
  String get nutritionEmptyBody =>
      'Fotografía un plato para estimar calorías y macros. Los valores son coincidencias USDA aproximadas, no consejo médico.';

  @override
  String get nutritionSaveToToday => 'Guardar en hoy';

  @override
  String get nutritionSaveHistoryOnly => 'Guardar solo en el historial';

  @override
  String get nutritionScanLoggedMessage => 'Añadido a las comidas de hoy';

  @override
  String get nutritionScanReviewTitle => 'Encuadra todo el plato';

  @override
  String get nutritionScanReviewBody => 'Confirma que se ve toda la comida';

  @override
  String get nutritionScanWholePlate => 'Plato completo';

  @override
  String get nutritionHomeHint => 'El registro de comidas está en Nutrición';

  @override
  String get nutritionMoreActions => 'Más';

  @override
  String get nutritionGoalsSave => 'Guardar objetivos';

  @override
  String nutritionOfGoalGrams(String consumed, String goal) {
    return '$consumed / $goal g';
  }

  @override
  String get nutritionEditGoals => 'Editar objetivos diarios';

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
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeBody =>
      'Sigue tu dispositivo o fija el modo claro u oscuro.';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsHelp => 'Ayuda';

  @override
  String get settingsReplayWalkthrough => 'Ver de nuevo la guía inicial';

  @override
  String get settingsReplayWalkthroughBody =>
      'Vuelve a ver los consejos de captura del primer inicio.';

  @override
  String get settingsRateApp => 'Valorar esta aplicación';

  @override
  String get settingsRateAppBody => 'Deja una valoración en Google Play.';

  @override
  String get settingsRateAppUnavailable =>
      'Google Play no está disponible ahora mismo.';

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
    return '$usage · Un anuncio por un escaneo';
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
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsPrivacyPolicyBody =>
      'Cómo se tratan las fotos, el historial local, el análisis de IA y las búsquedas de USDA';

  @override
  String get settingsPrivacyPolicyUnavailable =>
      'Añade la URL de privacidad en la configuración de publicación.';

  @override
  String get settingsPrivacyPolicyOpenFailed =>
      'No se pudo abrir la política de privacidad.';

  @override
  String get legalTitle => 'Información legal';

  @override
  String get legalSettingsBody =>
      'Privacidad, condiciones de uso y tratamiento de datos';

  @override
  String get legalIntroTitle => 'Políticas claras y transparentes';

  @override
  String get legalIntroBody =>
      'Cómo trata MassLens tus datos y las reglas aplicables cuando usas la aplicación.';

  @override
  String get legalPrivacyPolicy => 'Privacidad';

  @override
  String get legalTermsOfUse => 'Condiciones';

  @override
  String get legalLastUpdated => '21 ago 2026';

  @override
  String get legalPublishedPolicy => 'Ver la política publicada';

  @override
  String get legalFooter => 'MassLens · Documentos legales';

  @override
  String get legalPrivacyScopeTitle => 'Ámbito y proveedor de MassLens';

  @override
  String get legalPrivacyScopeBody =>
      'MassLens es ofrecida por el desarrollador identificado en su ficha de Google Play («nosotros» o «nuestro»). Esta política explica cómo se trata la información en la aplicación Android MassLens y su servicio de escaneo. MassLens no exige una cuenta ni solicita directamente tu nombre, correo electrónico, perfil o ubicación precisa.';

  @override
  String get legalPrivacyPhotosTitle => 'Fotos y análisis con IA';

  @override
  String get legalPrivacyPhotosBody =>
      'Una foto solo se procesa cuando eliges Cámara o Galería e inicias un escaneo de IA. Antes de enviarla, MassLens corrige la orientación, cambia el tamaño, vuelve a codificarla como JPEG y elimina los metadatos EXIF y GPS integrados. La foto, un segundo ángulo opcional y el contexto del escaneo se envían por HTTPS mediante el servicio Cloudflare de MassLens a OpenAI para identificar objetos o alimentos visibles y estimar intervalos de peso. OpenAI recibe la instrucción de no almacenar la respuesta. Las fotos no se guardan en la base de datos del Worker de MassLens.';

  @override
  String get legalPrivacyNutritionTitle =>
      'Escaneos de alimentos y datos del USDA';

  @override
  String get legalPrivacyNutritionBody =>
      'En los escaneos de Alimentos y macros, la IA devuelve nombres de alimentos, intervalos de peso aproximados y términos genéricos de búsqueda en inglés; no crea valores nutricionales. El servidor solo envía texto de búsqueda normalizado a USDA FoodData Central para obtener calorías y macros. El USDA nunca recibe tus fotos, el identificador de instalación ni el historial local. Todos los pesos, calorías y macros son estimaciones y pueden estar incompletos.';

  @override
  String get legalPrivacyLocalTitle => 'Información guardada en tu dispositivo';

  @override
  String get legalPrivacyLocalBody =>
      'Los resultados y una copia privada de la foto se guardan solo cuando eliges Guardar. Las preferencias, el historial y el diario de nutrición permanecen en tu dispositivo. Las entradas se añaden al importar voluntariamente una foto guardada o introducir datos manualmente; no se suben al servidor. La copia de seguridad de Android depende de la configuración del dispositivo.';

  @override
  String get legalPrivacyServiceTitle => 'Datos del servicio y conservación';

  @override
  String get legalPrivacyServiceBody =>
      'MassLens transmite fuera del dispositivo identificadores de dispositivo u otros ID. Crea un identificador de instalación aleatorio —no un IMEI, número de serie ni dirección MAC de hardware— y lo envía al servicio MassLens para gestionar los escaneos iniciales, créditos obtenidos con anuncios, verificación de compras de por vida, reintentos y prevención de abusos. El servicio lo convierte en hash antes de usarlo en la base de datos y registra identificadores de solicitud, estado de créditos y recompensas, tokens de compra para acceso de por vida, eventos técnicos limitados y totales diarios anónimos, como el modo de escaneo completado y el coste de IA. El JSON de un resultado completado, nunca la foto, puede conservarse hasta 24 horas para repetir una solicitud sin doble cobro. Los registros de créditos, compras y prevención de abusos se conservan mientras sean necesarios para esas funciones. Los proveedores de alojamiento y red pueden tratar direcciones IP y registros de seguridad rutinarios.';

  @override
  String get legalPrivacyAdsTitle => 'Publicidad y consentimiento';

  @override
  String get legalPrivacyAdsBody =>
      'MassLens usa Google Mobile Ads (AdMob) para conceder créditos de escaneo con recompensa y mostrar otros anuncios. Google y sus socios publicitarios recopilan y comparten identificadores de dispositivo u otros ID, incluido el identificador publicitario de Android y el App Set ID, además de información del dispositivo, ubicación aproximada deducida de la dirección IP, diagnósticos, opciones de consentimiento e interacciones con anuncios, con fines publicitarios, de analítica y de prevención de fraude, según sus propias políticas. Cuando sea obligatorio, la aplicación solicitará tu consentimiento. Puedes restablecer el identificador publicitario en los ajustes de Android. Si Google ofrece opciones de privacidad para ti, podrás revisarlas en Ajustes.';

  @override
  String get legalPrivacySharingTitle => 'Proveedores, transferencias y venta';

  @override
  String get legalPrivacySharingBody =>
      'La información solo se comparte cuando es necesario con Cloudflare para ofrecer la API, OpenAI para analizar fotos, USDA FoodData Central para búsquedas nutricionales genéricas y Google para publicidad y consentimiento. Estos proveedores pueden tratar información en países distintos al tuyo conforme a sus propias condiciones y garantías. MassLens no vende tu historial local de escaneos ni tu diario nutricional y no los usa para publicidad o análisis nutricional a nivel de usuario.';

  @override
  String get legalPrivacyChoicesTitle => 'Tus opciones y la eliminación';

  @override
  String get legalPrivacyChoicesBody =>
      'Puedes denegar el permiso de cámara, usar el diario manual sin IA, cancelar antes del análisis, no guardar resultados, eliminar escaneos o el historial, vaciar el diario por separado, revisar las opciones publicitarias o desinstalar la app. La eliminación de datos locales también depende de las copias de seguridad de Android. Para otras solicitudes, contacta al desarrollador en Google Play sin enviar fotos ni datos de salud sensibles.';

  @override
  String get legalPrivacySecurityTitle => 'Seguridad y menores';

  @override
  String get legalPrivacySecurityBody =>
      'MassLens usa HTTPS, eliminación de metadatos, identificadores de instalación convertidos en hash y controles de acceso diseñados para reducir riesgos. Ningún almacenamiento o transmisión por Internet puede garantizarse como totalmente seguro. MassLens no está dirigida a menores que no hayan alcanzado la edad mínima de consentimiento digital de su país y no solicitamos conscientemente perfiles personales a menores.';

  @override
  String get legalPrivacyChangesTitle => 'Cambios y contacto';

  @override
  String get legalPrivacyChangesBody =>
      'Esta política puede cambiar cuando cambien MassLens, la ley aplicable o sus proveedores. La fecha de actualización se modificará cuando haya cambios importantes. La versión HTTPS publicada en el enlace anterior es la destinada a la ficha de Google Play. Para cualquier pregunta, utiliza el contacto del desarrollador que aparece en dicha ficha.';

  @override
  String get legalTermsAcceptanceTitle => 'Aceptación y requisitos';

  @override
  String get legalTermsAcceptanceBody =>
      'Al instalar o usar MassLens, aceptas estas Condiciones de uso y la Política de privacidad. Si no las aceptas, no uses la aplicación. Debes tener capacidad legal para aceptar estas condiciones donde vivas; de lo contrario, un progenitor o tutor legal deberá revisarlas y aceptarlas por ti. Eres responsable de cumplir las leyes aplicables.';

  @override
  String get legalTermsServiceTitle => 'Qué ofrece el servicio';

  @override
  String get legalTermsServiceBody =>
      'MassLens ofrece estimaciones visuales con IA de objetos y platos, nutrición aproximada basada en USDA, historial local y un diario de nutrición opcional. El análisis de fotos requiere Internet y acceso a escaneos. Algunas funciones dependen de permisos o de la disponibilidad de anuncios.';

  @override
  String get legalTermsEstimatesTitle => 'Estimaciones, nutrición y seguridad';

  @override
  String get legalTermsEstimatesBody =>
      'Los escaneos de IA son estimaciones visuales, no lecturas de una báscula física. Los resultados pueden ser inexactos, incompletos o inadecuados para un objeto o comida concretos. MassLens no es un dispositivo médico ni ofrece asesoramiento médico, dietético, sobre alergias, dosificación, comercio regulado, envíos o seguridad. Nunca confíes en ella para medicamentos, comercio regulado, alérgenos, materiales peligrosos u otras decisiones críticas. Usa una báscula calibrada o un profesional cualificado cuando la precisión sea importante.';

  @override
  String get legalTermsContentTitle => 'Tus fotos y uso aceptable';

  @override
  String get legalTermsContentBody =>
      'Conservas tus derechos sobre las fotos y la información que envías. Concedes a MassLens y a sus proveedores necesarios un permiso limitado para tratarlas únicamente con el fin de ofrecer el escaneo solicitado, mantener la seguridad y permitir los reintentos descritos en la Política de privacidad. Debes tener derecho a usar las imágenes enviadas. No envíes contenido ilegal, imágenes íntimas, documentos confidenciales, imágenes que vulneren la privacidad o derechos de otras personas, código malicioso ni contenido ajeno al análisis legítimo de objetos o alimentos.';

  @override
  String get legalTermsCreditsTitle => 'Créditos de escaneo y publicidad';

  @override
  String get legalTermsCreditsBody =>
      'Una instalación nueva puede recibir un número limitado de escaneos iniciales. Un anuncio con recompensa completado puede conceder un crédito tras la confirmación de la aplicación y el servicio. Una compra única en Google Play puede desbloquear escaneos ilimitados y eliminar anuncios para esa cuenta de Google en dispositivos compatibles, sujeta a límites de uso razonable y reglas de reembolso de Google Play. Los créditos y el acceso de por vida no tienen valor monetario, no pueden transferirse entre cuentas y pueden limitarse para evitar abusos. La disponibilidad de anuncios no está garantizada. Los escaneos válidos que fallen suelen reembolsarse, pero el acceso puede retrasarse por interrupciones, controles antifraude, verificación de compras o errores técnicos. Los formatos de anuncios, reglas de créditos y precios pueden cambiar con un aviso razonable.';

  @override
  String get legalTermsThirdPartyTitle =>
      'Datos locales y servicios de terceros';

  @override
  String get legalTermsThirdPartyBody =>
      'Los resultados y entradas nutricionales guardados se almacenan localmente y pueden perderse si los eliminas, borras los datos de la aplicación, desinstalas, cambias de dispositivo o pierdes el dispositivo. Eres responsable de cualquier copia de seguridad que necesites. MassLens depende de Cloudflare, OpenAI, USDA FoodData Central, Google Mobile Ads, Google Play y fabricantes de dispositivos. Sus servicios, contenidos y disponibilidad se rigen por sus propias condiciones; MassLens no los controla.';

  @override
  String get legalTermsLicenseTitle => 'Licencia y propiedad intelectual';

  @override
  String get legalTermsLicenseBody =>
      'Recibes una licencia limitada, personal, revocable, no exclusiva e intransferible para usar MassLens con fines lícitos y no comerciales. La aplicación, su diseño, código, marca y materiales originales siguen siendo propiedad de sus respectivos titulares. No puedes copiar, vender, sublicenciar, realizar ingeniería inversa salvo que la ley lo permita expresamente, eludir controles de seguridad o créditos, sobrecargar o extraer datos del servicio ni usarlo para crear un conjunto de datos o servicio competidor.';

  @override
  String get legalTermsAvailabilityTitle =>
      'Disponibilidad, cambios y uso indebido';

  @override
  String get legalTermsAvailabilityBody =>
      'MassLens puede cambiar, suspender o retirar funciones para mejorar la aplicación, cumplir requisitos legales o de seguridad, gestionar costes o responder a cambios de terceros. No se promete disponibilidad continua y sin errores. El acceso puede limitarse o bloquearse cuando sea razonablemente necesario para impedir fraude, abuso automatizado, ataques, uso ilícito o daños al servicio o a otras personas.';

  @override
  String get legalTermsLiabilityTitle =>
      'Exclusiones y limitación de responsabilidad';

  @override
  String get legalTermsLiabilityBody =>
      'En la máxima medida permitida por la ley, MassLens se ofrece «tal cual» y «según disponibilidad», sin garantías de exactitud, idoneidad para un fin concreto, funcionamiento ininterrumpido o resultados sin errores. El desarrollador no responde de pérdidas indirectas, incidentales, especiales, consecuentes o ejemplares derivadas de confiar en estimaciones, perder datos locales, servicios de terceros, anuncios o no poder usar la aplicación. Nada de estas condiciones excluye derechos o responsabilidades que no puedan excluirse legalmente en tu país.';

  @override
  String get legalTermsChangesTitle =>
      'Actualizaciones, separabilidad y contacto';

  @override
  String get legalTermsChangesBody =>
      'Estas condiciones pueden actualizarse cuando cambien MassLens o los requisitos aplicables. Seguir usando la aplicación después de que una actualización entre en vigor supone aceptar las condiciones revisadas cuando la ley lo permita. Si una disposición no es exigible, las demás seguirán vigentes. La legislación obligatoria de protección al consumidor no se ve afectada. Para preguntas o avisos legales, utiliza el contacto del desarrollador en la ficha de Google Play de MassLens.';

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
  String get settingsClearNutrition => 'Borrar historial nutricional';

  @override
  String get settingsNoNutritionEntries => 'No hay entradas nutricionales';

  @override
  String settingsNutritionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entradas nutricionales',
      one: '1 entrada nutricional',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionTitle => '¿Borrar el historial nutricional?';

  @override
  String settingsClearNutritionBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se eliminarán las $count entradas nutricionales guardadas en este dispositivo. Los escaneos no cambiarán.',
      one:
          'Se eliminará la entrada nutricional guardada en este dispositivo. Los escaneos no cambiarán.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearNutritionAction => 'Borrar nutrición';

  @override
  String get settingsNutritionCleared =>
      'Se ha borrado el historial nutricional.';

  @override
  String get settingsVersion => 'Versión 1.1.0';

  @override
  String get settingsSafetyBody =>
      'Las fotos ofrecen estimaciones visuales inciertas. Usa una báscula física cuando importe la precisión. Nunca uses MassLens para dosis médicas, comercio regulado o decisiones de seguridad.';

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
  String get scanTryAnother => 'Otro objeto';

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
  String get scanNoFoodDetected =>
      'No se encontró comida visible. Encuadra un plato completo e inténtalo de nuevo; el escaneo fue reembolsado.';

  @override
  String get scanNutritionUnavailable =>
      'Los datos nutricionales de USDA no están disponibles temporalmente. Inténtalo más tarde; el escaneo fue reembolsado.';

  @override
  String get scanNutritionNoMatch =>
      'No se encontró una coincidencia nutricional completa de USDA. Prueba con una foto más clara; el escaneo fue reembolsado.';

  @override
  String get scanFoodScale => 'Estimaciones de alimentos';

  @override
  String get scanPhotographMeal => 'Fotografía un plato completo';

  @override
  String get scanConfirmMeal => 'Confirma que se vea toda la comida';

  @override
  String get scanAnalyzeMeal => 'Analizar comida y macros';

  @override
  String get scanFoodOptionalDetails => 'Detalles opcionales del plato';

  @override
  String get scanContainer => 'Tipo de recipiente';

  @override
  String get scanContainerUnknown => 'Desconocido';

  @override
  String get scanContainerPlate => 'Plato';

  @override
  String get scanContainerBowl => 'Bol';

  @override
  String get scanContainerCup => 'Taza';

  @override
  String get scanContainerTray => 'Bandeja';

  @override
  String get scanContainerNone => 'Sin recipiente';

  @override
  String get scanPlateDiameter => 'Diámetro del plato o bol (opcional)';

  @override
  String get scanFoodReferenceTip =>
      'Una moneda, tarjeta, regla o diámetro conocido puede reducir el rango de peso.';

  @override
  String get scanProgressIdentifyFood => 'Identificando alimentos visibles…';

  @override
  String get scanProgressMatchUsda => 'Buscando datos nutricionales de USDA…';

  @override
  String get scanProgressNutrition => 'Calculando calorías y macros…';

  @override
  String get scanFoodTotalWeight => 'Peso neto estimado de la comida';

  @override
  String get scanFoodComponents => 'Componentes de la comida';

  @override
  String get scanNutrition => 'Nutrición';

  @override
  String get scanCalories => 'Calorías';

  @override
  String get scanProtein => 'Proteínas';

  @override
  String get scanCarbs => 'Carbohidratos';

  @override
  String get scanFat => 'Grasas';

  @override
  String get scanEditAmount => 'Corregir cantidad';

  @override
  String get scanRemoveItem => 'Eliminar detección falsa';

  @override
  String get scanAmountGrams => 'Cantidad en gramos';

  @override
  String get scanOriginalAiRange => 'Rango original de IA';

  @override
  String get scanUsdaSource => 'Fuente USDA';

  @override
  String get scanNutritionMissing =>
      'Solo peso — sin datos nutricionales completos de USDA';

  @override
  String get scanPartialTotal => 'Total parcial';

  @override
  String get scanCompleteTotal => 'Total completo';

  @override
  String get scanFoodDisclaimer =>
      'Estimación aproximada a partir de una foto. No es un dispositivo médico ni consejo dietético.';

  @override
  String get scanFoodEditTitle => 'Corregir cantidad';

  @override
  String get scanFoodEditBody =>
      'Los totales usarán tu cantidad; el rango original de IA seguirá visible.';

  @override
  String get scanFoodAmountPositive => 'Introduce una cantidad mayor que cero.';

  @override
  String get scanFoodAtLeastOne => 'Mantén al menos un componente de comida.';

  @override
  String get scanRemove => 'Eliminar';

  @override
  String get rewardAdsFundAnalysis =>
      'Los anuncios financian el análisis de IA real';

  @override
  String get rewardHeadline => 'Consigue más escaneos de IA';

  @override
  String get rewardBody =>
      'Mira un anuncio recompensado por un escaneo o desbloquea escaneos ilimitados y elimina los anuncios con una compra única.';

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
  String get rewardUnlockUnlimited => 'Desbloquear ilimitado';

  @override
  String get drawerUpgradeUnlimited => 'Mejora a Ilimitado';

  @override
  String get rewardCreditStillSyncing =>
      'El crédito de escaneo aún se está sincronizando.';

  @override
  String get rewardNoCreditAdded =>
      'No se añadió ningún crédito de escaneo pendiente.';

  @override
  String get accessLoadingBalance => 'Cargando…';

  @override
  String get accessPreview => 'Vista previa del acceso';

  @override
  String accessScansLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escaneos',
      one: '1 escaneo',
    );
    return '$_temp0';
  }

  @override
  String accessScansAvailable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count escaneos',
      one: '1 escaneo',
    );
    return '$_temp0';
  }

  @override
  String accessBreakdown(int starter, int rewarded, int legacy) {
    return '$starter iniciales · $rewarded recompensados · $legacy anteriores';
  }

  @override
  String get accessStarterThenAd => '2 escaneos gratis, luego 1 por anuncio';

  @override
  String get accessGetOne => '+1';

  @override
  String get accessUnlimitedScans => 'Escaneos ilimitados';

  @override
  String get accessLifetimeActive => 'Acceso de por vida activo';

  @override
  String accessBuyLifetime(String price) {
    return 'Desbloquear ilimitado · $price';
  }

  @override
  String get accessRestorePurchases => 'Restaurar compras';

  @override
  String get accessLifetimeUnlocked =>
      'El acceso de por vida está activo en este dispositivo.';

  @override
  String get accessLifetimeLoadingPrice => 'Cargando precio…';

  @override
  String get paywallEyebrow => 'Análisis de fotos con IA real';

  @override
  String get paywallHeadline => 'Estimaciones de fotos.';

  @override
  String get paywallHeadlineAccent => 'Desbloquea';

  @override
  String get paywallHeadlineRest => 'Explora con IA.';

  @override
  String get paywallHeroSubtitle =>
      'Explora objetos y alimentos mediante fotos.\nEstimaciones aproximadas, no mediciones de peso.';

  @override
  String get paywallSocialProof => 'Paga una vez · tuyo siempre';

  @override
  String get paywallSocialSubline => 'Escaneos IA ilimitados. Cero anuncios.';

  @override
  String get paywallUnlockLifetime => 'Desbloquear acceso de por vida';

  @override
  String paywallTrustPriced(String price) {
    return 'Compra única · $price';
  }

  @override
  String get paywallOneTimeCaption => 'Pago único';

  @override
  String get paywallLuggageLabel => 'Escaneo de equipaje';

  @override
  String get paywallLuggageTitle => 'Maleta de cabina';

  @override
  String get paywallLuggageWeight => '2–4 kg';

  @override
  String get paywallLuggageConfidence => 'Ejemplo de estimación';

  @override
  String get paywallFeatureHeading =>
      'PEQUEÑOS OBJETOS. GRANDES POSIBILIDADES.';

  @override
  String get paywallFeatureUnlimited => 'Escaneos ilimitados';

  @override
  String get paywallFeatureNoAds => 'Sin anuncios';

  @override
  String get paywallFeatureNutrition => 'Conoce mejor tu plato';

  @override
  String get paywallFeatureNutritionSub =>
      'Calorías, proteínas y macros estimados';

  @override
  String get paywallFeatureLuggage => 'Estimaciones de objetos';

  @override
  String get paywallFeatureLuggageSub =>
      'Solo lo visible; el contenido es desconocido';

  @override
  String get paywallFeatureObjects => 'Apunta. Captura. Estima.';

  @override
  String get paywallFeatureObjectsSub =>
      'Intervalos aproximados según lo visible';

  @override
  String get paywallPhotoScanLabel => 'ESCANEO DE FOTOS CON IA';

  @override
  String get paywallEstimateExample => 'Estimación IA · ejemplo';

  @override
  String get paywallIllustrativeReadings =>
      'Solo ilustraciones. Una foto no mide el peso real.';

  @override
  String get paywallLifetimeOffer => 'Acceso de por vida · Sin anuncios';

  @override
  String get paywallPurchaseTrust => 'Un pago. Sin suscripción. Google Play.';

  @override
  String get paywallTerms => 'Condiciones';

  @override
  String get paywallPrivacy => 'Privacidad';

  @override
  String get paywallFeatureLifetime => 'Ilimitado + sin anuncios';

  @override
  String get paywallFeatureLifetimeSub => 'Un pago. Tuyo.';

  @override
  String get paywallOneTimeBadge => 'Pago único';

  @override
  String get paywallLifetimePlan => 'Acceso de por vida';

  @override
  String get paywallContinueFree => 'Continuar con escaneos gratis';

  @override
  String get paywallPurchaseUnavailable => 'Compra no disponible';

  @override
  String get nativeSponsored => 'Contenido patrocinado';

  @override
  String get nativeTestLoading => 'Patrocinado · cargando anuncio de prueba…';

  @override
  String get nativeTestRetrying => 'Reintentando el anuncio de prueba…';

  @override
  String get accessGetFreeScan => 'Escaneo gratis';

  @override
  String get settingsReminders => 'Recordatorios';

  @override
  String get mealReminderTitle => 'Recordatorio diario de comidas';

  @override
  String mealReminderOnBody(String time) {
    return 'Cada día a las $time, salvo si acabas de registrar una comida';
  }

  @override
  String get mealReminderOffBody =>
      'Recibe un aviso al día para registrar tus comidas';

  @override
  String get mealReminderTime => 'Hora del recordatorio';

  @override
  String get mealReminderPermissionDenied =>
      'Las notificaciones están bloqueadas. Actívalas para MassLens en los ajustes del teléfono.';

  @override
  String mealReminderEnabled(String time) {
    return 'Recordatorio programado a las $time cada día.';
  }

  @override
  String get mealReminderPromptTitle => 'Mantén tu racha';

  @override
  String get mealReminderPromptBody =>
      'Recibe un recordatorio diario para registrar tus comidas. Puedes cambiar la hora en Ajustes.';

  @override
  String get mealReminderPromptAction => 'Activar recordatorio';

  @override
  String get mealReminderPromptDismiss => 'Ahora no';

  @override
  String get mealReminderNotificationTitle => 'Hora de registrar tu comida';

  @override
  String get mealReminderNotificationBody =>
      'Fotografía tu plato en MassLens para contar calorías y mantener tu racha.';

  @override
  String get mealReminderChannelName => 'Recordatorios de comidas';

  @override
  String get barcodeScanAction => 'Escanear código de barras';

  @override
  String get barcodeScanActionBody =>
      'Productos envasados · gratis, sin gastar escaneos';

  @override
  String get barcodeFreeBadge => 'GRATIS';

  @override
  String get barcodeScannerHint => 'Centra el código de barras en el marco';

  @override
  String get barcodeTypeNumber => 'Escribir el número';

  @override
  String get barcodeTorch => 'Linterna';

  @override
  String get barcodeEnterTitle => 'Introduce el número del código de barras';

  @override
  String get barcodeInvalid =>
      'Introduce un código de barras válido de 8, 12 o 13 dígitos.';

  @override
  String get barcodeLookingUp => 'Buscando el producto…';

  @override
  String get barcodeNotFoundTitle => 'Producto no encontrado';

  @override
  String barcodeNotFoundBody(String code) {
    return 'El código $code aún no está en Open Food Facts ni en USDA FoodData Central. Puedes introducir los valores de la etiqueta.';
  }

  @override
  String get barcodeUnavailableTitle => 'No se pudo buscar este producto';

  @override
  String get barcodeUnavailableBody =>
      'Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get barcodeRetry => 'Reintentar';

  @override
  String get barcodeEnterManually => 'Introducir manualmente';

  @override
  String get barcodeScanAgain => 'Escanear de nuevo';

  @override
  String barcodePer100(String unit) {
    return 'Por 100 $unit';
  }

  @override
  String barcodeServing(String amount) {
    return '1 porción · $amount';
  }

  @override
  String barcodeWholePack(String amount) {
    return 'Envase entero · $amount';
  }

  @override
  String get barcodeYourPortion => 'Tu porción';

  @override
  String get barcodeAmountEaten => 'Cantidad consumida';

  @override
  String get barcodePartialNutrition =>
      'Faltan algunos macros en los datos de este producto y cuentan como 0.';

  @override
  String get barcodeAddToDiary => 'Añadir al diario';

  @override
  String get barcodeSourceOpenFoodFacts =>
      'Datos de etiqueta de Open Food Facts (ODbL). Revisa el envase: los valores pueden estar incompletos o desactualizados.';

  @override
  String get barcodeSourceUsda =>
      'Datos de etiqueta de USDA FoodData Central. Revisa el envase: los valores pueden estar incompletos o desactualizados.';

  @override
  String get barcodeRecentTitle => 'Productos recientes';

  @override
  String get barcodeRecentBody => 'Registra un producto que ya escaneaste';

  @override
  String barcodeKcalPer100(String value, String unit) {
    return '$value kcal / 100 $unit';
  }
}
