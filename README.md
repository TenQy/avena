# Tienda App

Aplicación móvil offline-first para gestión de tiendas pequeñas.

La app está diseñada para ayudar a pequeños negocios a administrar:

- inventario
- ventas
- caja
- pagos pendientes
- empleados
- estadísticas básicas

Todo desde dispositivos móviles y con soporte para funcionamiento sin internet.

---

# Objetivo

Crear una aplicación rápida, simple y fácil de usar para tiendas pequeñas, evitando depender de una computadora y permitiendo operar incluso sin conexión.

---

# Características principales

- Inventario por categorías y subcategorías
- Productos por unidad y a granel
- Ventas con pagos mixtos
- Control de caja
- Dashboard diario y semanal
- Pagos pendientes y abonos
- Roles de usuario
- Funcionamiento offline-first
- Sincronización entre dispositivos
- Logs de acciones importantes

---

# Tecnologías planeadas

- Flutter
- Riverpod
- Drift (SQLite)
- UUID
- GoRouter
- Firebase o Supabase (sincronización futura)

---

# Arquitectura

La aplicación utiliza arquitectura feature-first.

```text
core/
shared/
features/
```

La base de datos local es la fuente principal de datos.

---

# Estado del proyecto

Actualmente en desarrollo.

Fases iniciales:
- documentación
- arquitectura
- diseño del sistema
- estructura base

---

# Diseño

La interfaz utiliza una estética cálida y minimalista basada en tonos avena/café claro.

Principios principales:
- mobile-first
- rápida de usar
- visual limpia
- componentes reutilizables
- mínima saturación visual

---

# Documentación

La documentación principal se encuentra en:

```text
docs/
```

Archivos importantes:

- `FEATURES.md`
- `DATABASE.md`
- `ARCHITECTURE.md`
- `DESIGN_SYSTEM.md`
- `ROADMAP.md`
- `AGENTS.md`

---

# Reglas principales

- Offline-first
- Una sola caja abierta
- Ventas con snapshots históricos
- Sin sobrescribir ventas ni movimientos
- Sincronización incremental
- Roles y permisos por usuario

---

# Objetivo técnico

La app prioriza:
- simplicidad
- claridad
- mantenibilidad
- rendimiento móvil
- sincronización segura
- facilidad de escalado futuro

---

# Estado futuro

Se planea agregar:
- sincronización cloud
- mejor manejo multi-dispositivo
- dashboards avanzados
- métricas más detalladas
- optimizaciones de UX