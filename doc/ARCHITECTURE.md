# Architecture

## Enfoque general

La aplicación usará una arquitectura feature-first, organizada por módulos funcionales.

El objetivo es mantener el proyecto:

- fácil de entender
- fácil de escalar
- compatible con offline-first
- claro para trabajar con Codex
- sin sobreingeniería innecesaria

La app debe priorizar funcionalidad móvil rápida, persistencia local y sincronización posterior con la nube.

---

# Principios principales

- Organizar el código por features.
- Mantener lógica de negocio fuera de widgets.
- Usar Riverpod para estado e inyección de dependencias.
- Usar una base de datos local como fuente principal de datos.
- Sincronizar con la nube cuando exista conexión.
- Evitar dependencias innecesarias.
- Mantener widgets pequeños y reutilizables.
- Guardar snapshots en ventas, logs y movimientos importantes.
- Separar UI, providers, repositories y services.

---

# Estructura de carpetas

```text
lib/
  main.dart
  app.dart

  core/
    database/
      app_database.dart
      tables/
      daos/

    sync/
      sync_service.dart
      sync_queue_service.dart
      conflict_resolver.dart

    router/
      app_router.dart
      route_names.dart

    constants/
      app_constants.dart
      app_roles.dart
      payment_methods.dart

    utils/
      date_utils.dart
      money_utils.dart
      id_generator.dart

    errors/
      app_exception.dart
      failure.dart

  shared/
    theme/
      app_theme.dart
      app_colors.dart

    widgets/
      app_header.dart
      app_navbar.dart
      app_fab.dart
      confirm_dialog.dart
      empty_state.dart
      loading_view.dart
      error_view.dart

    models/
      app_user.dart
      sync_status.dart

  features/
    authentication/
      data/
        auth_repository.dart
        auth_local_source.dart
      providers/
        auth_provider.dart
        session_provider.dart
      presentation/
        screens/
          login_screen.dart
        widgets/

    dashboard/
      data/
        dashboard_repository.dart
      providers/
        dashboard_provider.dart
      presentation/
        screens/
          dashboard_screen.dart
        widgets/

    inventory/
      data/
        inventory_repository.dart
      providers/
        inventory_provider.dart
      presentation/
        screens/
          inventory_screen.dart
          category_screen.dart
          add_product_screen.dart
        widgets/
          categories_grid.dart
          category_card.dart
          product_card.dart
          search_results.dart
          add_category_sheet.dart

    sales/
      data/
        sales_repository.dart
      providers/
        sales_provider.dart
        current_sale_provider.dart
      presentation/
        screens/
          sales_screen.dart
          create_sale_screen.dart
          sale_detail_screen.dart
        widgets/
          sale_item_card.dart
          payment_method_selector.dart
          bulk_quantity_selector.dart

    cash/
      data/
        cash_repository.dart
      providers/
        cash_provider.dart
      presentation/
        screens/
          cash_screen.dart
          open_cash_screen.dart
          close_cash_screen.dart
        widgets/
          cash_summary_card.dart
          cash_movement_card.dart

    users/
      data/
        users_repository.dart
      providers/
        users_provider.dart
      presentation/
        screens/
          users_screen.dart
          user_form_screen.dart
        widgets/
          user_card.dart

    pending_payments/
      data/
        pending_payments_repository.dart
      providers/
        pending_payments_provider.dart
      presentation/
        screens/
          pending_payments_screen.dart
          pending_payment_detail_screen.dart
        widgets/
          pending_payment_card.dart
          payment_entry_sheet.dart

    calculator/
      providers/
        calculator_provider.dart
      presentation/
        screens/
          calculator_screen.dart
        widgets/

    logs/
      data/
        logs_repository.dart
      providers/
        logs_provider.dart
      presentation/
        screens/
          logs_screen.dart
        widgets/
          log_card.dart
```

---

# Capas por feature

Cada feature puede dividirse en:

```text
data/
providers/
presentation/
```

## data

Contiene:

- repositories
- fuentes locales
- llamadas a DAOs
- llamadas futuras a servicios remotos

Ejemplo:

```text
inventory_repository.dart
```

## providers

Contiene:

- providers de Riverpod
- estado de pantalla
- controladores simples
- providers derivados

Ejemplo:

```text
inventory_provider.dart
```

## presentation

Contiene:

- pantallas
- widgets propios del módulo

Ejemplo:

```text
presentation/screens/inventory_screen.dart
presentation/widgets/product_card.dart
```

---

# Flujo de datos

El flujo general será:

```text
UI
 ↓
Riverpod Provider
 ↓
Repository
 ↓
Local Database
 ↓
Sync Queue
 ↓
Cloud Database
```

La UI nunca debe acceder directamente a la base de datos.

La UI debe comunicarse con providers.

Los providers deben usar repositories.

Los repositories deben acceder a DAOs, servicios locales o servicios de sincronización.

---

# Base de datos local

La app debe usar una base de datos local como fuente principal.

Opciones recomendadas:

- Drift
- Isar

Por el diseño actual, Drift es una buena opción porque:

- permite relaciones claras
- funciona bien con SQLite
- permite consultas estructuradas
- es compatible con arquitectura offline-first
- facilita reportes y estadísticas

## Regla principal

La app siempre lee primero desde la base de datos local.

La nube no debe ser la fuente directa para pintar UI.

---

# Sincronización

La sincronización se implementará como una capa separada.

Componentes sugeridos:

```text
core/sync/
  sync_service.dart
  sync_queue_service.dart
  conflict_resolver.dart
```

## SyncService

Responsable de:

- detectar conexión
- iniciar sincronización
- enviar cambios pendientes
- descargar cambios remotos
- actualizar estados locales

## SyncQueueService

Responsable de:

- registrar operaciones pendientes
- marcar operaciones sincronizadas
- reintentar operaciones fallidas
- guardar errores de sincronización

## ConflictResolver

Responsable de:

- aplicar reglas de conflicto
- resolver cambios de productos
- resolver cambios de usuarios
- conservar ventas y movimientos sin sobrescribir

---

# Reglas de sincronización

## Ventas

- Nunca se sobrescriben.
- Cada venta se conserva como evento histórico.
- Cada venta usa UUID.
- Cada venta pertenece a una caja.
- Si dos dispositivos crean ventas offline, ambas ventas se sincronizan.

## Movimientos de caja

- Nunca se sobrescriben.
- Se agregan como eventos nuevos.
- No deben editarse directamente.

## Productos

- Usan última modificación válida.
- Si hay conflicto, gana el registro con `updatedAt` más reciente.
- Las ventas antiguas no cambian porque usan snapshots.

## Usuarios

- Usan última modificación válida.
- Si un usuario se inhabilita, el cambio se aplica cuando el dispositivo sincronice.
- El superadmin no debe poder eliminarse desde la app.

## Pagos pendientes

- Los abonos nunca se sobrescriben.
- Cada abono se agrega como evento nuevo.
- El estado del pago pendiente se recalcula con base en sus abonos.

---

# Manejo offline

La app debe permitir operar sin internet.

## Permitido offline

- registrar ventas
- consultar inventario local
- consultar caja abierta
- registrar pagos pendientes
- registrar abonos
- registrar movimientos de caja
- consultar historial local

## Limitado offline

- iniciar turno de empleado
- validar inhabilitación remota
- sincronizar cambios entre dispositivos
- crear usuarios visibles para otros dispositivos

## Regla para empleados

- El empleado debe iniciar turno con conexión cuando sea posible.
- Si ya tiene sesión activa y acceso habilitado, puede vender offline.
- Si el admin lo inhabilita mientras está offline, el cambio se aplicará cuando sincronice.

---

# Estado global

Riverpod manejará el estado de la aplicación.

## Providers principales

```text
authProvider
currentUserProvider
currentCashSessionProvider
syncStatusProvider
inventoryProvider
salesProvider
dashboardProvider
```

## Reglas

- No usar estado global innecesario.
- El estado temporal de formularios debe mantenerse local si no se comparte.
- El estado persistente debe venir de la base de datos.
- Los providers deben ser pequeños y específicos.
- Evitar providers gigantes que controlen demasiadas cosas.

---

# Repositories

Los repositories encapsulan el acceso a datos.

Ejemplo:

```dart
class SalesRepository {
  Future<void> createSale(CreateSaleInput input);
  Future<void> cancelSale(String saleId, String reason);
  Stream<List<Sale>> watchSalesByCashSession(String cashSessionId);
}
```

## Reglas

- La UI no debe llamar DAOs directamente.
- Los providers deben usar repositories.
- Los repositories pueden llamar DAOs y sync services.
- Los repositories deben generar logs cuando aplique.
- Los repositories deben agregar operaciones a `SyncQueue`.

---

# DAOs

Los DAOs contienen consultas directas a la base local.

Ejemplo:

```text
inventory_dao.dart
sales_dao.dart
cash_dao.dart
users_dao.dart
```

## Reglas

- Los DAOs no deben contener reglas complejas de negocio.
- Las reglas de negocio viven en repositories o services.
- Los DAOs deben enfocarse en consultas, inserts, updates y streams.

---

# Navegación

La navegación debe centralizarse.

Archivo recomendado:

```text
core/router/app_router.dart
```

Puede usarse:

- GoRouter
- Navigator clásico

Para este proyecto, GoRouter es recomendable si se quiere manejar:

- rutas protegidas
- redirección según sesión
- redirección según rol
- navegación más mantenible

## Rutas principales

```text
/login
/dashboard
/inventory
/inventory/category/:id
/inventory/product/new
/sales
/sales/new
/sales/:id
/cash
/users
/pending-payments
/calculator
/logs
```

---

# Control de permisos

Los permisos se basan en roles.

## Superadmin

Acceso total.

## Admin

Acceso operativo total, excepto acciones reservadas al superadmin.

## Employee

Acceso limitado:

- ventas
- inventario sólo lectura
- pagos pendientes

## Regla

La UI puede ocultar acciones, pero las reglas reales deben validarse también en repositories/services.

No confiar únicamente en la interfaz.

---

# Tema y diseño

El tema global vive en:

```text
shared/theme/
  app_theme.dart
  app_colors.dart
```

Reglas:

- No definir colores directamente en pantallas.
- Usar `AppColors`.
- Usar componentes compartidos.
- Respetar `DESIGN_SYSTEM.md`.
- No modificar el tema global sin revisar impacto en toda la app.

---

# Componentes compartidos

Los componentes reutilizables viven en:

```text
shared/widgets/
```

Ejemplos:

- `AppHeader`
- `AppNavBar`
- `AppFab`
- `ConfirmDialog`
- `EmptyState`
- `LoadingView`
- `ErrorView`

## Regla

Si un widget se usa en más de una feature, debe moverse a `shared/widgets`.

Si sólo pertenece a una feature, debe quedarse dentro de esa feature.

---

# Manejo de dinero

El manejo de dinero debe ser consistente.

Reglas:

- Evitar cálculos desordenados dentro de widgets.
- Usar funciones utilitarias para formato.
- Centralizar comisiones.
- Separar subtotal, comisión y total final.

Archivo recomendado:

```text
core/utils/money_utils.dart
```

Ejemplo:

```text
subtotal = 100
commission = 5
total = 105
```

---

# Métodos de pago

Los métodos de pago deben centralizarse.

Archivo recomendado:

```text
core/constants/payment_methods.dart
```

Métodos:

- cash
- transfer
- card
- bonus

Reglas:

- cash afecta caja física
- transfer no afecta caja física
- card no afecta caja física y agrega 5%
- bonus no afecta caja física y agrega 6.5%

---

# Productos a granel

La lógica de productos a granel debe centralizarse.

Archivo recomendado:

```text
core/utils/bulk_utils.dart
```

Reglas:

- Los productos a granel guardan precio por kilogramo.
- Las porciones se calculan con base en factor del kilogramo.
- Las porciones estándar son:
  - 1kg
  - 1/2kg
  - 100g
  - 50g
- También debe permitirse cantidad personalizada.

---

# Logs

Los logs se generan desde repositories o services.

No deben generarse directamente desde widgets.

Reglas:

- Toda acción crítica genera log.
- Los logs guardan snapshot de usuario.
- Los logs no deben eliminarse.
- Los logs deben poder consultarse por admin y superadmin.

---

# Manejo de errores

Los errores deben mostrarse de forma clara.

Tipos:

- error de validación
- error de base de datos
- error de sincronización
- error de permisos
- error de conexión

Reglas:

- No mostrar errores técnicos crudos al usuario final.
- Registrar errores importantes.
- Mostrar mensajes simples.

Ejemplo:

```text
No se pudo guardar la venta. Intenta nuevamente.
```

---

# Testing manual

Aunque el testing detallado se documentará en `TESTING.md`, la arquitectura debe facilitar pruebas de:

- login
- venta offline
- venta con pago mixto
- caja abierta
- cancelación de venta
- pagos pendientes
- abonos
- sync pendiente
- empleado inhabilitado
- productos sin stock

---

# Convenciones de código

## Nombres

- Archivos en `snake_case`.
- Clases en `PascalCase`.
- Variables y funciones en `camelCase`.
- Constantes globales en archivos dedicados.

## Idioma

- Código, variables, clases y archivos en inglés.
- Comentarios y documentación pueden estar en español.
- Textos visibles al usuario en español.

## Tamaño

- Evitar archivos demasiado grandes.
- Separar widgets cuando una pantalla crezca demasiado.
- Separar lógica compleja en services o utils.

---

# Dependencias recomendadas

Dependencias posibles:

- `flutter_riverpod`
- `drift`
- `sqlite3_flutter_libs`
- `path_provider`
- `path`
- `uuid`
- `go_router`
- `connectivity_plus`
- `intl`

Dependencias futuras según decisión de nube:

- Firebase
- Supabase

Regla:

- No agregar dependencias sin justificar.
- Preferir código propio simple antes que librerías innecesarias.

---

# Decisiones arquitectónicas

- Se usará arquitectura feature-first.
- Se evitará Clean Architecture excesiva.
- Se usará Riverpod para estado e inyección.
- Se usará base de datos local como fuente principal.
- La nube será capa de sincronización, no fuente directa de UI.
- Se usarán repositories para encapsular acceso a datos.
- Se usarán DAOs para consultas locales.
- Se usará `SyncQueue` para cambios offline.
- Se respetará `DESIGN_SYSTEM.md` para UI.
- Se respetará `DATABASE.md` para entidades y relaciones.