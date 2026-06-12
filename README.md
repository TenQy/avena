# Avena POS

Aplicación móvil offline-first desarrollada para una tienda real de alimentos para mascotas.

El proyecto nace para resolver necesidades operativas del negocio, permitiendo administrar inventario, ventas, caja, empleados y estadísticas desde dispositivos móviles, incluso sin conexión a internet.

---

# Objetivo

Crear una aplicación rápida, simple y fácil de usar para pequeñas tiendas, eliminando la dependencia de una computadora y permitiendo operar incluso cuando no existe conexión a internet.

La aplicación busca adaptarse a la operación real del negocio y evolucionar mediante pruebas con usuarios reales antes de implementar sincronización cloud.

---

# Características principales

## Inventario

* Categorías y subcategorías
* Productos por unidad
* Productos a granel
* Control opcional de stock
* Búsqueda optimizada
* Costos y márgenes de ganancia
* Soft delete

## Ventas

* Registro de ventas
* Productos por unidad y a granel
* Pagos mixtos
* Snapshots históricos
* Validaciones de negocio
* Funcionamiento offline

## Caja

* Apertura y cierre de caja
* Retiros y depósitos
* Caja física esperada
* Historial de movimientos

## Usuarios

* Roles:

  * Superadmin
  * Admin
  * Employee
* Gestión de permisos
* Habilitación e inhabilitación de usuarios

## Dashboard

* Estadísticas diarias
* Estadísticas semanales
* Estadísticas mensuales
* Comparativas históricas
* Gráficas y métricas operativas

## Respaldos

* Exportación de respaldos
* Restauración de respaldos
* Herramientas de mantenimiento

## Auditoría

* Logs de acciones importantes
* Historial de ventas
* Historial de movimientos de caja

---

# Tecnologías

* Flutter
* Riverpod
* Drift
* SQLite
* UUID
* GoRouter

Sincronización futura:

* Supabase

---

# Arquitectura

La aplicación utiliza arquitectura feature-first.

```text
lib/
├── core/
├── shared/
└── features/
```

La base de datos local es la fuente principal de información.

Toda funcionalidad debe funcionar correctamente sin depender de internet.

---

# Estado actual

Actualmente implementado:

* Autenticación local
* Roles y permisos
* Ventas
* Inventario
* Usuarios
* Caja
* Dashboard
* Configuración
* Logs
* Respaldos locales
* Base de datos local con Drift

En desarrollo:

* Sincronización cloud

---

# Diseño

La interfaz utiliza una estética cálida y minimalista inspirada en tonos avena y café claro.

Principios principales:

* Mobile-first
* Simplicidad
* Rapidez de uso
* Componentes reutilizables
* Baja carga visual
* Acciones frecuentes accesibles en pocos pasos

---

# Documentación

Toda la documentación del proyecto se encuentra en:

```text
docs/
```

Documentos principales:

* FEATURES.md
* DATABASE.md
* ARCHITECTURE.md
* DESIGN_SYSTEM.md
* ROADMAP.md
* AGENT.md

---

# Reglas principales

* Offline-first
* Una sola caja abierta simultáneamente
* Snapshots históricos para ventas
* Soft delete para entidades principales
* Roles y permisos por usuario
* Sincronización incremental futura
* Respaldo completo mediante archivos `.tiendabak`

---

# Objetivo técnico

El proyecto prioriza:

* Simplicidad
* Claridad
* Escalabilidad gradual
* Mantenibilidad
* Rendimiento móvil
* Seguridad de datos
* Sincronización confiable

---

# Roadmap futuro

* Sincronización con Supabase
* Multi-dispositivo
* Reportes Excel/CSV
* Métricas avanzadas
* Configuración de tickets e impresión
* Mejoras de UX basadas en uso real
