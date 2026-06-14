# CHANGELOG

## v0.1.0+1 - 2026-06-13

Primera version APK de validacion interna para Avena POS.

Esta version concentra el flujo operativo base para probar la aplicacion en uso real antes de una entrega formal.

### Incluye

- Inicio de sesion con roles de superadmin, admin y empleado.
- Navegacion principal mobile-first para dashboard, ventas, inventario y secciones operativas.
- Inventario local con categorias, subcategorias, productos por unidad y productos a granel.
- Edicion de nombre para categorias y subcategorias desde inventario.
- Gestion de stock con validaciones para cantidades enteras en productos por unidad, cantidades en kg/gr para granel y limites razonables.
- Flujo de ventas con busqueda de productos, carrito, productos por unidad, productos a granel, pagos en efectivo y pagos mixtos.
- Chips rapidos para venta a granel de 100g, 500g, 1kg y 2kg.
- Validaciones de venta para evitar productos sin stock y mostrar importes pendientes o cambio de forma clara.
- Caja operativa con apertura, depositos, retiros, edicion confirmada del dinero inicial y registro de movimientos.
- Historial de ventas con edicion y controles visibles para volver o cerrar el editor.
- Gestion de usuarios con validaciones de telefono y confirmacion de contrasena.
- Logs de auditoria para acciones importantes de login, caja, inventario, ventas, usuarios y pagos pendientes.
- Dashboard inicial para revision rapida del estado operativo.
- Respaldo local y opcion de compartir respaldo desde mantenimiento.

### Correcciones incluidas desde testing

- Evita logs innecesarios al volver a marcar una categoria principal como principal.
- Corrige stock decimal en productos por unidad.
- Mejora la gestion visual de kg/gr para productos a granel.
- Evita mostrar subcategorias vacias al buscar dentro de una categoria.
- Limita cantidades enormes de stock.
- Oculta productos sin stock en el buscador de ventas.
- Mantiene el valor de efectivo recibido al cambiar de pantalla.
- Muestra restante dinamico en pago mixto.
- Corrige validaciones de depositos, retiros y retiro mayor al dinero disponible en caja.
- Agrega confirmacion y log al editar dinero inicial de caja.
- Corrige errores del editor de ventas relacionados con productos sin stock.
- Agrega control visible para cerrar el editor de ventas.
- Limita telefono y agrega confirmacion de contrasena en usuarios.
- Muestra hora de logs en formato consistente con la app.

### Pendientes conocidos

- Validar en dispositivo Android fisico con usuarios reales.
- Revisar diferenciacion visual de ventas canceladas.
- Evaluar acciones rapidas para vender varias unidades.
- Mejorar vistas para pantallas grandes o uso tactil de escritorio.
- Definir comportamiento final para empleados editando ventas.
- Validar calculadora con los duenos.
