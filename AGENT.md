# AGENTS

## Proyecto

Aplicación móvil Flutter offline-first para gestión de tiendas pequeñas.

La app permite:
- inventario
- ventas
- caja
- pagos pendientes
- usuarios
- dashboard
- sincronización entre dispositivos

La app está optimizada para móvil y funcionamiento offline.

---

# Reglas generales

- Respetar `FEATURES.md`.
- Respetar `DATABASE.md`.
- Respetar `ARCHITECTURE.md`.
- Respetar `DESIGN_SYSTEM.md`.
- No inventar features no documentadas.
- No modificar arquitectura sin necesidad.
- No modificar tema global sin autorización.
- No agregar dependencias innecesarias.
- No eliminar código existente sin justificarlo.
- Mantener cambios pequeños y claros.
- Mantener compatibilidad offline-first.

---

# Arquitectura

## Organización

Usar arquitectura feature-first.

Estructura principal:

```text
core/
shared/
features/
```

Cada feature usa:

```text
data/
providers/
presentation/
```

---

## Flujo de datos

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
Cloud
```

La UI nunca debe acceder directamente a la base de datos.

---

# Estado global

Usar Riverpod.

Reglas:
- evitar providers gigantes
- separar estado por feature
- mantener estado temporal local cuando sea posible
- usar providers derivados si ayuda claridad

---

# Base de datos

La base local es la fuente principal de datos.

Reglas:
- usar UUIDs
- usar snapshots para ventas y logs
- no sobrescribir ventas
- no sobrescribir movimientos de caja
- usar soft delete cuando aplique

---

# Sincronización

La app funciona offline-first.

Reglas:
- guardar cambios localmente primero
- usar `SyncQueue`
- sincronizar cuando exista conexión
- ventas y movimientos son eventos históricos
- productos y usuarios usan última modificación válida

---

# UI y diseño

Respetar `DESIGN_SYSTEM.md`.

Reglas:
- usar `AppColors`
- no usar colores hardcodeados
- usar componentes compartidos
- evitar pantallas saturadas
- evitar sombras fuertes
- mantener estética cálida y minimalista
- mantener diseño mobile-first

---

# Componentes compartidos

Los widgets reutilizables deben vivir en:

```text
shared/widgets/
```

Ejemplos:
- AppHeader
- AppNavBar
- AppFab
- ConfirmDialog
- EmptyState

Si un widget sólo pertenece a una feature, mantenerlo dentro de esa feature.

---

# Código

## Idioma

- Código en inglés.
- Variables en inglés.
- Clases en inglés.
- Archivos en inglés.
- Comentarios pueden estar en español.
- Textos visibles al usuario en español.

---

## Convenciones

- archivos: `snake_case`
- clases: `PascalCase`
- variables: `camelCase`

---

## Tamaño

- evitar archivos enormes
- separar widgets grandes
- separar lógica compleja en services o utils
- evitar lógica pesada dentro de widgets

---

# Repositories

Los repositories:
- encapsulan acceso a datos
- generan logs cuando aplica
- agregan operaciones a SyncQueue
- manejan reglas principales

La UI nunca debe llamar DAOs directamente.

---

# DAOs

Los DAOs:
- manejan consultas locales
- no contienen lógica de negocio compleja
- no manejan UI
- no generan logs

---

# Navegación

La navegación está centralizada.

Preferencia:
- GoRouter

No crear navegación desordenada dentro de widgets.

---

# Logs

Las acciones importantes generan logs.

Ejemplos:
- login
- ventas
- cancelaciones
- movimientos de caja
- creación de productos
- cambios de precio
- usuarios

Los logs no deben eliminarse.

---

# Caja

Reglas:
- sólo puede existir una caja abierta
- no puede existir venta sin caja abierta
- efectivo afecta caja física
- transferencias, tarjeta y bonos se registran aparte

---

# Ventas

Reglas:
- guardar snapshots
- soportar productos a granel
- soportar pagos mixtos
- permitir ventas offline
- cancelaciones sólo admin/superadmin
- no eliminar ventas físicamente

---

# Inventario

Reglas:
- productos pueden controlar stock o no
- si no controlan stock:
  - `stockQuantity = null`
- productos a granel usan precio por kilogramo
- precios derivados se calculan automáticamente

---

# Roles

## Superadmin

- acceso total
- puede administrar admins

## Admin

- control operativo completo

## Employee

Puede:
- ventas
- inventario lectura
- pagos pendientes

No puede:
- cancelar ventas
- editar productos
- modificar configuración

---

# Dependencias preferidas

- flutter_riverpod
- drift
- sqlite
- uuid
- go_router
- connectivity_plus
- intl

No agregar librerías sin justificar.

---

# Antes de terminar cambios

Siempre:
- ejecutar `flutter analyze`
- revisar imports no usados
- revisar warnings
- evitar código muerto
- resumir archivos modificados

---

# Restricciones importantes

- No implementar sincronización cloud completa antes de estabilizar base local.
- No agregar features fuera del roadmap actual.
- No cambiar arquitectura por preferencia personal.
- No usar Clean Architecture excesiva.
- No crear carpetas innecesarias.
- No romper consistencia visual.
- No duplicar lógica.

---

# Estrategia de trabajo

Implementar cambios por fases pequeñas.

Preferir:
- una feature a la vez
- cambios pequeños
- código claro
- código mantenible

Evitar:
- refactors masivos innecesarios
- cambios globales sin motivo
- complejidad prematura

---

# Referencias importantes

Leer según tarea:

- `FEATURES.md`
- `DATABASE.md`
- `ARCHITECTURE.md`
- `DESIGN_SYSTEM.md`
- `ROADMAP.md`

No cargar documentos innecesarios para tareas pequeñas.

---

# Objetivo general

Construir una app:
- rápida
- clara
- mantenible
- offline-first
- usable en tiendas pequeñas reales
- optimizada para móvil
- simple de operar
- fácil de escalar posteriormente

---

## Estado actual

- Fase 0 completada
- Fase 1 completada
- Fase 2 completada
- Fase 3 completada 
- Fase 4 completada
- Fase 5 completada:
  - caja funcional local
  - apertura/cierre
  - movimientos
  - ingresos separados