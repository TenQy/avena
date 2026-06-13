# Estado del proyecto

## Estado actual

La app esta en etapa de testing funcional. La base local offline-first ya esta implementada y los modulos principales operan con persistencia local, roles, logs y flujos moviles.

El foco actual es estabilizar bugs de testing, pulir flujos operativos reales y preparar una primera APK interna para pruebas con usuarios.

## Modulos implementados

- Autenticacion y sesion:
  - Login local.
  - Sesion persistente.
  - Roles: superadmin, admin y employee.
  - Menu lateral filtrado por permisos.

- Usuarios:
  - Superadmin administra admins y empleados.
  - Admin administra empleados.
  - Crear y editar usuarios.
  - Habilitar/inhabilitar usuarios.
  - Soft delete segun permisos.
  - Validacion de telefono limitado y confirmacion de contrasena.

- Inventario:
  - Categorias, subcategorias y productos.
  - Productos por unidad y a granel.
  - Control opcional de stock.
  - Busqueda global y por categoria.
  - Detalle de producto.
  - Soft delete de productos y categorias.
  - Employee en modo lectura.
  - Ajustes de testing aplicados en stock, busqueda, granel y categoria principal.

- Ventas:
  - Venta con productos por unidad y a granel.
  - Pagos en efectivo, transferencia, terminal, bonos y mixto.
  - Comisiones configuradas para tarjeta y bonos.
  - Caja e inventario se actualizan al registrar venta.
  - Pago pendiente desde venta.
  - Faltante/cambio visible en efectivo.
  - Chips rapidos para granel, incluido 2 kg.
  - Buscador filtra productos sin stock.

- Historial de ventas:
  - Consulta de ventas por fecha.
  - Detalle de ventas.
  - Cancelacion con motivo y reversa de caja/inventario.
  - Edicion de ventas pagadas.
  - Editor con boton visible para cerrar.

- Caja:
  - Apertura y cierre de caja.
  - Retiros y depositos con motivo.
  - Validacion de montos y limite maximo.
  - Retiro limitado por efectivo esperado disponible.
  - Edicion de dinero inicial con confirmacion y log.
  - Ingresos separados por efectivo, transferencia, terminal y bonos.

- Pagos pendientes:
  - Creacion desde venta.
  - Registro de abonos.
  - Persistencia local y logs.

- Dashboard:
  - Resumen operativo basado en caja/ventas actuales.
  - Metricas principales y productos destacados.

- Logs:
  - Auditoria local de acciones importantes.
  - Filtros por usuario, fecha y accion.
  - Detalle de eventos.
  - Hora visible en formato AM/PM.

- Configuracion y mantenimiento:
  - Ajustes administrativos basicos.
  - Acciones de mantenimiento local.
  - Base preparada para sync queue, sin sincronizacion cloud completa todavia.

## Base tecnica

- Flutter con arquitectura feature-first.
- Riverpod para estado.
- Drift + SQLite como fuente local principal.
- UUIDs para entidades.
- Repositories encapsulan reglas y acceso a datos.
- Logs de actividad para acciones relevantes.
- UI mobile-first con componentes compartidos.

## Pendiente antes de APK interna

- Completar bugs restantes de testing documentados.
- Revisar flujos criticos en dispositivo real:
  - abrir caja
  - vender
  - venta a granel
  - pago mixto
  - pago pendiente
  - cancelar venta
  - editar venta
  - cerrar caja
- Validar permisos por rol en todos los modulos.
- Revisar textos visibles, acentos y consistencia de AM/PM.
- Probar datos reales con inventario pequeno y ventas repetidas.
- Generar APK de prueba interna.

## Bugs y mejoras en cola

- Ventas:
  - Evaluar input directo o botones +5/+10 para varias unidades.
  - Notificaciones internas para stock bajo o agotado.
  - Mejorar placeholders de inputs.

- Historial de ventas:
  - Diferenciar visualmente mejor ventas canceladas.
  - Agregar vista simplificada.
  - Agregar boton para volver al inicio de la lista.
  - Redisenar cards para ocupar menos espacio.

- Usuarios:
  - Ocultar superadmin en vista del admin.
  - Formatear telefono como `00 0000 0000`.
  - Permitir que admin cambie su contrasena.
  - Permitir eliminar empleados.

- Logs:
  - Cambiar filtro de accion por filtro de modulo.

- Dashboard:
  - Estadisticas por dia especifico.
  - Historial semanal y mensual.
  - Comparativas historicas.

- UI escritorio/tablet:
  - Adaptar inventario y ventas a laptop/PC.
  - Botones visibles en lugar de depender de long press.
  - Mejor distribucion para pantallas grandes.

## Proximos pasos sugeridos

1. Terminar correccion de bugs de testing restantes.
2. Hacer una pasada completa de QA en Android fisico.
3. Ajustar textos y detalles visuales detectados durante QA.
4. Generar APK interna para prueba con usuarios.
5. Recopilar feedback real de operacion en tienda.
6. Priorizar mejoras post-APK: rapidez en ventas, notificaciones, dashboard historico y adaptacion a pantallas grandes.

## Fuera de alcance por ahora

- Sincronizacion cloud completa.
- Refactors grandes de arquitectura.
- Nuevos modulos fuera del roadmap actual.
- Optimizaciones para escritorio como prioridad principal antes de estabilizar la APK movil.
