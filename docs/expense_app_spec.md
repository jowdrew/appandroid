# App de control de gastos simple

## Objetivo
Crear una aplicación móvil en Flutter enfocada en registrar gastos diarios de forma ágil, mostrar totales mensuales y resaltar las categorías donde más se gasta. Se prioriza una experiencia ligera, sin fricción y con capacidad de monetización mediante anuncios, suscripción mensual y exportación premium.

## Público objetivo
- Personas que desean un control básico y rápido de sus gastos diarios.
- Usuarios que prefieren registrar compras desde el móvil sin procesos complejos.
- Quienes quieren ver tendencias y top de categorías sin un ERP completo.

## Propuesta de valor
- Flujo de registro en 2-3 toques con autocompletado de categorías recientes.
- Resumen mensual claro con gráfico simple (barras o dona) y top de categorías.
- Exportación a Excel/CSV y copia en la nube para usuarios premium.
- Integración futura con automatizaciones (Shortcuts iOS, Intents/Atajos Android, n8n, APIs REST).

## MVP funcional
- Registro manual de gasto (monto, categoría, nota opcional, fecha, método de pago opcional).
- Lista cronológica por día con totales diarios y botón de añadir rápido.
- Dashboard mensual: total del mes, comparativa con mes anterior, top 3 categorías, gráfico simple.
- Filtro por mes y búsqueda por texto.
- Idiomas: ES inicial con soporte i18n listo para otras regiones.

## Flujo de usuario
1. **Home (Dashboard):** muestra total del mes, variación vs. mes anterior, top categorías y botón “Registrar gasto”.
2. **Registro rápido:** bottom sheet/modal con campo numérico, selector de categoría (chips recientes + lista completa), fecha por defecto hoy, nota opcional.
3. **Historial:** lista de gastos con agrupación por día, totales diarios y filtros por mes/categoría.
4. **Premium:** sección para activar suscripción o compra puntual de exportación; muestra ventajas (sin ads, exportación, backups).

## Monetización
- **Ads:** banner en historial y/o intersticial al abrir detalles (no en flujo de registro para evitar fricción).
- **Suscripción mensual:** rango S/ 4.90 – 9.90; elimina ads, habilita exportación y respaldo en nube.
- **Exportar a Excel/CSV:** función premium; botón en dashboard e historial.

## Integraciones y extensibilidad
- **Automatización:**
  - iOS: soportar `Siri Shortcuts/Intents` para registrar gasto con voz.
  - Android: `App Shortcuts` y `intent-filters` para apertura rápida con datos prellenados.
  - **n8n/Make/Zapier:** endpoint REST para crear gastos y recuperar reportes.
- **Almacenamiento:** SQLite local con `sqflite` en MVP; opción de sincronizar con backend (Supabase/Firebase) en premium.
- **Exportación:** generar CSV/Excel con `excel` o `csv` package y compartir con `share_plus`.

## Data model (local)
- `Expense`: id, amount (double), currency (string), category (string), note (string?), date (DateTime), paymentMethod (string?), createdAt/updatedAt.
- `Category`: id, name, color, icon, isDefault.
- `BudgetSnapshot` (futuro): month, totalSpent, topCategories (map category->amount).

## Estructura propuesta en Flutter
```
lib/
  main.dart
  app.dart                 # MaterialApp + temas + rutas
  core/
    theme/
    localization/
    analytics/
  features/
    expenses/
      data/
        datasources/       # SQLite + REST client futuro
        models/
        repositories/
      domain/
        entities/
        usecases/
      presentation/
        pages/
        widgets/
        cubit/             # state management con flutter_bloc
    subscriptions/
    onboarding/
  services/
    export/
    notifications/
    shortcuts/
```

## Pantallas clave
- **Splash/Onboarding:** explica valor y muestra CTA para registrar primer gasto.
- **Dashboard:** cards con total mes, variación vs. anterior, gráfico de dona, top categorías, botón “Registrar gasto”.
- **Registrar gasto:** bottom sheet con teclado numérico y chips de categorías recientes; permite nota y fecha.
- **Historial:** lista agrupada por día; totales diarios y filtros.
- **Premium/Paywall:** beneficios, precios locales, prueba gratuita opcional y botón para activar.
- **Exportar:** selector de rango de fechas y formato (CSV/Excel) disponible solo en premium.

## MVP técnico
- Flutter 3.x, `flutter_bloc` para estado, `freezed` para modelos, `sqflite` para persistencia local.
- Internacionalización con `flutter_localizations` y archivos ARB.
- Inyección de dependencias con `get_it` o `riverpod` si se prefiere providerless.
- Analytics: Firebase Analytics opcional, logging local en MVP.
- Testing: unit tests para casos de uso y widgets principales.

## Roadmap
- **Semana 1:** setup Flutter, arquitectura, entidades, registro básico y almacenamiento local.
- **Semana 2:** dashboard mensual con gráfico, historial y filtros; tema claro/oscuro.
- **Semana 3:** paywall, ads (AdMob), exportación a CSV (premium), pruebas básicas.
- **Semana 4:** integraciones iniciales (Shortcuts/Intents) y endpoint REST mínimo para n8n.

## Métricas a seguir
- Retención D1/D7, frecuencia de registro, categorías más usadas, tasa de conversión a premium, descargas y ARPU.

## Riesgos y mitigación
- **Fricción en registro:** optimizar teclado numérico y categorías recientes.
- **Privacidad:** no obligar a crear cuenta en MVP; cifrar base local si se manejan datos sensibles.
- **Monetización invasiva:** limitar ads a pantallas pasivas y ofrecer versión sin anuncios.

## Notas de implementación
- Evitar try/catch alrededor de importaciones.
- Mantener diseño accesible (alto contraste, soporte screen readers).
- Preparar constantes de moneda con formato local para PEN y expansión regional.
