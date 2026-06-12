# Testing Inventario

## Bugs 
- Categoría principal permite volver a marcarse como principal, muestra mensaje y genera log innecesario.
- Productos por unidad permiten stock decimal.
- Productos a granel no muestran/gestionan claramente kg/gr.
- Al buscar dentro de una categoría, se muestran subcategorías vacías sin productos encontrados.

## Mejoras seguras 

- Agregar edición de nombre para categoría.
- Agregar edición de nombre para subcategoría.
- Cambiar "Sin subcategoría" por "Otros".
- Mejorar mensaje al intentar eliminar categoría con productos asociados.
- Evaluar opción futura para mover productos antes de eliminar una categoría.

## Mejoras futuras / UI

- Rediseñar pantalla de detalles del producto.
- Adaptar inventario a laptop/PC con botones visibles en lugar de long press.
- Mejorar distribución visual para pantallas grandes.
- Adaptar ventas para pantalla táctil grande o escritorio.

---

# Testing Ventas

## Bugs 

- Se puede pagar aunque el efectivo recibido sea menor al total.
- Pagado en efectivo no muestra faltante, solo cambio.
- El buscador muestra productos sin stock.
- No poder decrementar si hay 1 producto genera duda: debería quitar el producto o deshabilitarse claramente.
- Al cambiar de pantalla, el campo "pagado en efectivo" no persiste.

## Mejoras seguras 

- En pago mixto, mostrar el restante dinámico junto al input, no solo como placeholder.
- Agregar chip rápido de 2kg para productos a granel.
- Evaluar chips rápidos para granel: 100g, 500g, 1kg, 2kg.
- Agregar forma rápida para vender varias unidades: +5, +10 o input directo.
- Evaluar si + y - en producto a granel deben aumentar/disminuir 1kg, aunque por ahora modificar cantidad y chips rápidos puede ser suficiente.

## Mejoras futuras / UI

- Agregar notificaciones internas junto al menú/drawer.
- Notificar productos agotados o con stock bajo.
- Rediseñar placeholders de inputs para que no usen el color base.
- Adaptar ventas a pantallas grandes o táctiles.

---

# Testing Caja

## Bugs

- Retiro o depósito sin motivo cierra el formulario; debe mostrar error y conservar datos.
- No hay límite razonable en depósito o retiro.
- El retiro permite sacar más dinero del disponible en caja.

## Mejoras seguras

- Permitir editar dinero inicial de caja con confirmación y log.

---

# Testing Historial de ventas

## Bugs

- Al editar venta aparecen errores del módulo ventas, como productos sin stock en buscador.
- No hay botón visible para cerrar el editor de ventas, solo back del celular.

## Mejoras seguras

- Diferenciar mejor ventas canceladas.
- Agregar vista simplificada de ventas.
- Agregar botón para volver al inicio de la lista.

## Futuro UI

- Rediseñar cards para ocupar menos espacio.

---

# Testing Usuarios

## Bugs

- Input de teléfono no tiene límite.
- Falta campo de confirmar contraseña.

## Mejoras seguras

- Ocultar superadmin en vista del admin.
- Formatear teléfono como 00 0000 0000.
- Permitir que admin cambie su contraseña.
- Permitir eliminar empleados.

## Futuro negocio

- Agregar horario de empleados.
- Evaluar si admin puede agregar otros administradores.
- Evaluar si se pueden eliminar administradores o solo desactivar.

---

# Testing Logs

## Bugs

- Hora en formato 24h aunque la app usa AM/PM.

## Mejoras seguras

- Cambiar filtro de acción por filtro de módulo: Caja, Ventas, Inventario, Usuarios, etc.

---

# Dudas

- No permitir que empleado edite ventas por defecto.
- Calculadora queda pendiente de validación con dueños.

---

# Testing Dashboard

## Mejoras futuras

- Ver estadísticas de un día específico.
- Ver estadísticas de semanas anteriores.
- Ver estadísticas de meses anteriores.
- Mejorar vista diaria, actualmente solo muestra caja actual.
- Mantener comparativas contra ayer, semana anterior y mes anterior, pero agregar navegación histórica.