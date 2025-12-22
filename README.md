# App de control de gastos (concepto Flutter)

Este repositorio contiene la especificación inicial para una app móvil de control de gastos inspirada en la idea "App de control de gastos simple". La app se enfocará en registro rápido, dashboard mensual y monetización mediante ads, suscripción y exportación premium.

## Contenido
- `docs/expense_app_spec.md`: documento de especificación con objetivos, MVP, estructura en Flutter, monetización e integraciones futuras.

## Próximos pasos sugeridos
1. Inicializar proyecto Flutter 3.x (`flutter create .`) y configurar arquitectura por features.
2. Implementar flujo de registro rápido con almacenamiento local (sqflite) y pruebas básicas.
3. Añadir dashboard mensual con top de categorías y gráfico simple.
4. Integrar paywall, ads (AdMob) y exportación a CSV/Excel para usuarios premium.
5. Explorar automatizaciones (Shortcuts/Intents) y endpoint REST para n8n/otras apps.
