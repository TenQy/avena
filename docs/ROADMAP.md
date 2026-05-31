# Roadmap

## Objetivo del roadmap

Construir la aplicación por fases pequeñas, probables y testeables.

Cada fase debe dejar una base funcional antes de avanzar a la siguiente.

---

# Fase 0: Preparación del proyecto

## Objetivo

Crear una base limpia del proyecto Flutter.

## Tareas

- Crear proyecto Flutter nuevo.
- Configurar Git.
- Agregar estructura de carpetas base.
- Agregar documentación inicial.
- Configurar tema global.
- Agregar componentes compartidos principales.

## Entregables

- Proyecto Flutter limpio.
- `README.md` inicial.
- `AGENTS.md`.
- `docs/`.
- Tema visual base.
- Estructura `core/`, `shared/`, `features/`.

## Estado esperado

La app compila y muestra una pantalla inicial simple.

---

# Fase 1: Tema, navegación y estructura base

## Objetivo

Dejar lista la navegación principal y la base visual.

## Tareas

- Implementar `AppTheme`.
- Implementar `AppColors`.
- Crear `AppHeader`.
- Crear `AppNavBar`.
- Crear `AppFab`.
- Crear pantallas placeholder de módulos principales:
  - Dashboard
  - Ventas
  - Inventario
  - Caja
  - Usuarios
  - Pagos pendientes
  - Calculadora
- Configurar navegación.
- Definir rutas protegidas según rol.

## Entregables

- Navegación funcional.
- Pantallas placeholder.
- Componentes compartidos base.
- Diseño visual consistente.

## Estado esperado

El usuario puede navegar entre módulos principales según rol.

---

# Fase 2: Base de datos local

## Objetivo

Crear la base de datos local y entidades principales.

## Tareas

- Configurar Drift.
- Crear tablas base:
  - Users
  - Categories
  - Subcategories
  - Products
  - CashSessions
  - CashMovements
  - Sales
  - SaleItems
  - SalePayments
  - PendingPayments
  - PendingPaymentEntries
  - ActivityLogs
  - SyncQueue
- Crear DAOs principales.
- Crear utilitario para UUID.
- Crear datos iniciales mínimos.
- Crear cuenta base de administrador.

## Entregables

- Base de datos local funcional.
- Tablas principales.
- DAOs iniciales.
- Cuenta admin base.

## Estado esperado

La app puede guardar y leer datos localmente.

---

# Fase 3: Authentication y usuarios

## Objetivo

Permitir login, sesión persistente y control de acceso por roles.

## Tareas

- Crear pantalla de login.
- Validar usuario y contraseña.
- Crear flujo de actualización del admin base.
- Implementar persistencia de sesión.
- Crear `authProvider`.
- Crear `currentUserProvider`.
- Implementar roles:
  - superadmin
  - admin
  - employee
- Bloquear acceso si el usuario está inhabilitado.
- Crear módulo de usuarios para admin/superadmin.
- Permitir crear, editar, habilitar e inhabilitar usuarios.
- Generar logs de acciones importantes.

## Entregables

- Login funcional.
- Sesión persistente.
- Roles funcionales.
- Módulo de usuarios funcional.

## Estado esperado

Cada usuario ve sólo las interfaces permitidas.

---

# Fase 4: Inventario

## Objetivo

Implementar el control visual y funcional de productos.

## Tareas

- Crear pantalla de inventario.
- Implementar categorías.
- Implementar subcategorías.
- Implementar búsqueda global.
- Implementar búsqueda por categoría.
- Crear productos.
- Editar productos.
- Ver detalles de productos.
- Implementar productos por unidad.
- Implementar productos a granel.
- Implementar precios por kilogramo.
- Implementar cálculo de porciones:
  - 1kg
  - 1/2kg
  - 100g
  - 50g
  - cantidad personalizada
- Implementar control opcional de stock.
- Usar `stockQuantity = null` si no se controla stock.
- Implementar orden visual de productos.
- Generar logs de creación y edición.

## Entregables

- Inventario funcional.
- Productos por unidad y granel.
- Categorías y subcategorías.
- Búsqueda.
- Detalles de producto.

## Estado esperado

El admin puede administrar productos y el empleado puede consultarlos.

---

# Fase 5: Caja

## Objetivo

Controlar apertura, movimientos y cierre de caja.

## Tareas

- Crear pantalla de caja.
- Abrir caja con dinero inicial.
- Validar que sólo exista una caja abierta.
- Registrar retiros.
- Registrar depósitos o ajustes si aplica.
- Mostrar caja física.
- Mostrar ingresos por método:
  - efectivo
  - transferencia
  - terminal
  - bonos
- Mostrar diferencia esperada.
- Cerrar caja.
- Impedir abrir caja nueva si hay una anterior abierta.
- Generar logs de apertura, cierre y movimientos.

## Entregables

- Caja funcional.
- Movimientos de caja.
- Separación de ingresos físicos y digitales.

## Estado esperado

No se pueden registrar ventas sin caja abierta.

---

# Fase 6: Ventas

## Objetivo

Permitir registrar ventas de forma rápida y confiable.

## Tareas

- Crear pantalla de ventas.
- Crear flujo de nueva venta.
- Buscar productos.
- Agregar productos a venta.
- Manejar productos por unidad.
- Manejar productos a granel.
- Permitir cantidad personalizada.
- Permitir ingresar monto y calcular cantidad.
- Calcular subtotal.
- Calcular comisiones.
- Calcular total final.
- Implementar métodos de pago:
  - efectivo
  - transferencia
  - tarjeta
  - bonos
  - mixto
- Registrar `SalePayments`.
- Actualizar caja física sólo con efectivo.
- Registrar ingresos digitales por separado.
- Guardar snapshots de productos y usuario.
- Validar caja abierta.
- Validar stock si el producto controla stock.
- Permitir ventas offline.
- Generar logs de venta.

## Entregables

- Registro de ventas funcional.
- Pagos mixtos.
- Comisiones.
- Snapshots.
- Integración con caja.

## Estado esperado

El empleado puede registrar ventas correctamente y el admin puede revisarlas.

---

# Fase 7: Historial y cancelación de ventas

## Objetivo

Permitir consultar ventas y cancelar ventas con control.

## Tareas

- Crear historial de ventas.
- Mostrar ventas por caja actual.
- Mostrar detalle de venta.
- Mostrar productos, cantidades, métodos de pago y usuario.
- Implementar estado:
  - completada
  - cancelada
- Permitir cancelación sólo a admin/superadmin.
- Solicitar motivo de cancelación.
- Revertir caja e ingresos correspondientes.
- Revertir stock si aplica.
- Guardar log de cancelación.
- Evitar eliminar ventas físicamente.

## Entregables

- Historial funcional.
- Detalle de venta.
- Cancelación segura.

## Estado esperado

Las ventas históricas permanecen auditables.

---

# Fase 8: Pagos pendientes

## Objetivo

Gestionar deudas o pagos incompletos.

## Tareas

- Crear pantalla de pagos pendientes.
- Crear pago pendiente manual.
- Crear pago pendiente desde una venta.
- Guardar datos del cliente:
  - nombre
  - teléfono opcional
  - descripción
- Registrar abonos.
- Actualizar monto pagado.
- Actualizar monto restante.
- Marcar como completado cuando se cubra el total.
- Mostrar historial de abonos.
- Permitir acceso a admin, superadmin y empleado.
- Generar logs.

## Entregables

- Pagos pendientes funcionales.
- Abonos.
- Historial.
- Integración con ventas.

## Estado esperado

Una venta puede quedar parcial o totalmente pendiente.

---

# Fase 9: Calculadora

## Objetivo

Ayudar al administrador a calcular precios de venta.

## Tareas

- Crear pantalla de calculadora.
- Calcular precio por kg.
- Calcular precio por gramos.
- Calcular precio por unidad.
- Calcular precio desde caja o paquete.
- Permitir porcentaje de ganancia.
- Mostrar resultado claro.
- No guardar resultados permanentemente.

## Entregables

- Calculadora funcional.

## Estado esperado

El admin puede calcular precios de productos nuevos sin afectar inventario.

---

# Fase 10: Dashboard

## Objetivo

Mostrar estadísticas útiles y fáciles de interpretar para ayudar en la toma de decisiones del negocio.

## Tareas

### Dashboard diario

- Mostrar ventas realizadas.
- Mostrar ingresos totales del día.
- Mostrar ticket promedio.
- Mostrar caja física actual.
- Mostrar producto que generó más ingresos.
- Mostrar producto más vendido.
- Mostrar comparación de ingresos contra el día anterior.
- Mostrar comparación de ventas contra el día anterior.
- Mostrar comparación de ticket promedio contra el día anterior.

### Dashboard semanal

- Mostrar ingresos totales de la semana.
- Mostrar cantidad total de ventas.
- Mostrar ticket promedio semanal.
- Mostrar ingresos por día de la semana.
- Mostrar producto que generó más ingresos.
- Mostrar producto más vendido por cantidad.
- Mostrar producto más vendido por número de ventas.
- Mostrar mejor día de la semana.
- Mostrar peor día de la semana.
- Mostrar comparación con la semana anterior.
- Mostrar productos sin ventas durante la semana.

### Dashboard mensual

- Mostrar ingresos totales del mes.
- Mostrar cantidad total de ventas.
- Mostrar ticket promedio mensual.
- Mostrar producto que generó más ingresos.
- Mostrar producto más vendido.
- Mostrar mejor semana del mes.
- Mostrar peor semana del mes.
- Mostrar comparación con el mes anterior.
- Mostrar productos sin movimiento durante el mes.

### Visualización

- Implementar selector de vista:
  - Día
  - Semana
  - Mes
- Agregar gráfica de barras para ingresos semanales.
- Agregar gráfica de dona para distribución de métodos de pago.
- Agregar gráfica de líneas para evolución mensual de ingresos.
- Mostrar indicadores visuales de crecimiento o disminución.

### Cálculos

- Recalcular métricas desde datos locales.
- Excluir ventas canceladas.
- Calcular estadísticas utilizando información histórica.
- Calcular métricas por método de pago.

## Entregables

- Dashboard diario funcional.
- Dashboard semanal funcional.
- Dashboard mensual funcional.
- Gráficas básicas.
- Métricas calculadas localmente.

## Estado esperado

El administrador puede conocer rápidamente:

- cuánto vendió
- cómo va el negocio respecto a periodos anteriores
- qué productos generan más ingresos
- qué productos tienen poco movimiento
- cuáles son las tendencias de venta

---

# Fase 11: Logs

## Objetivo

Permitir auditoría de acciones importantes.

## Tareas

- Crear pantalla de logs.
- Mostrar acciones importantes.
- Filtrar por usuario.
- Filtrar por fecha.
- Filtrar por tipo de acción.
- Consultar detalles.
- Garantizar que logs no se eliminen.

## Entregables

- Historial de actividad.
- Filtros básicos.
- Auditoría interna.

## Estado esperado

Admin y superadmin pueden saber quién hizo cada acción importante.

---

# Fase 12: Sincronización

## Objetivo

Sincronizar datos locales con la nube.

## Tareas

- Elegir Firebase o Supabase.
- Implementar `SyncQueue`.
- Implementar `SyncService`.
- Detectar conexión.
- Enviar cambios pendientes.
- Descargar cambios remotos.
- Aplicar reglas de conflicto.
- Sincronizar ventas.
- Sincronizar productos.
- Sincronizar usuarios.
- Sincronizar caja.
- Sincronizar pagos pendientes.
- Sincronizar logs.
- Mostrar estado de sincronización en UI.

## Entregables

- Sync básica funcional.
- Operaciones offline pendientes.
- Indicador de estado.
- Resolución inicial de conflictos.

## Estado esperado

La app puede trabajar offline y sincronizar al recuperar conexión.

---

# Fase 13: Configuración

## Objetivo

Implementar una pantalla de configuración para agrupar información administrativa, estado del sistema y herramientas de mantenimiento.

## Tareas

- Crear pantalla de configuración.
- Mostrar datos del usuario actual.
- Mostrar información del negocio.
- Mostrar información de la app.
- Mostrar versión de app.
- Mostrar estado de sincronización.
- Mostrar información de caja actual.
- Implementar tema claro/oscuro.
- Implementar exportación de respaldo.
- Implementar restauración de base local.
- Preparar configuración de impresión para tickets futuros.
- Restringir acciones según rol.

## Entregables

- Pantalla de configuración funcional.
- Información de sistema visible.
- Acciones administrativas protegidas.
- Herramientas básicas de respaldo y restauración.

## Estado esperado

El admin puede consultar y administrar configuraciones básicas sin mezclar estos flujos con los módulos operativos.

---

# Fase 14: Seguridad y permisos

## Objetivo

Endurecer reglas de acceso y prevenir errores humanos.

## Tareas

- Validar permisos también en repositories/services.
- Proteger acciones destructivas.
- Impedir eliminar superadmin.
- Impedir acciones críticas sin sesión válida.
- Reforzar inhabilitación de empleados.
- Validar sesión activa de empleados.
- Revisar logs de acciones críticas.
- Revisar flujo de contraseña.

## Entregables

- Permisos más sólidos.
- Acciones protegidas.
- Mayor seguridad interna.

## Estado esperado

La UI no es la única barrera de seguridad.

---

# Fase 15: Testing manual

## Objetivo

Probar casos reales antes de pulir la app.

## Tareas

- Probar login.
- Probar roles.
- Probar creación de productos.
- Probar venta por unidad.
- Probar venta a granel.
- Probar pago mixto.
- Probar comisiones.
- Probar venta offline.
- Probar caja abierta.
- Probar cierre de caja.
- Probar cancelación de venta.
- Probar pago pendiente.
- Probar abonos.
- Probar empleado inhabilitado.
- Probar sincronización.
- Probar conflictos básicos.

## Entregables

- Lista de bugs.
- Ajustes prioritarios.
- Validación funcional.

## Estado esperado

La app ya puede probarse en entorno real pequeño.

---

# Fase 16: Pulido visual y UX

## Objetivo

Mejorar experiencia final sin cambiar arquitectura base.

## Tareas

- Revisar pantallas saturadas.
- Mejorar textos.
- Mejorar estados vacíos.
- Mejorar carga y errores.
- Mejorar navegación.
- Revisar accesibilidad visual.
- Revisar tamaños táctiles.
- Optimizar formularios.
- Mejorar feedback al guardar.

## Entregables

- UI más clara.
- Mejor experiencia de uso.
- Menos fricción en ventas.

## Estado esperado

La app se siente cómoda para uso diario.

---

# Fase 17: Preparación de README final

## Objetivo

Documentar el proyecto para presentación, portafolio o mantenimiento.

## Tareas

- Agregar descripción final.
- Agregar capturas.
- Agregar tecnologías usadas.
- Agregar instrucciones de instalación.
- Agregar arquitectura resumida.
- Agregar features principales.
- Agregar estado del proyecto.

## Entregables

- `README.md` completo.

## Estado esperado

El proyecto puede mostrarse de forma profesional.

---

# Reglas de avance

- No avanzar a una fase si la anterior no compila.
- Hacer commits por fase o por feature importante.
- Ejecutar `flutter analyze` después de cambios relevantes.
- No implementar sincronización antes de tener datos locales estables.
- No pulir diseño antes de tener flujo funcional.
- No agregar dependencias sin justificación.
- Mantener documentación actualizada cuando cambien reglas importantes.
