# Features

# Reglas generales del sistema

- La aplicación funcionará bajo un enfoque offline-first.
- Las operaciones principales deben funcionar sin internet.
- Los datos se guardarán localmente y se sincronizarán con la nube cuando exista conexión.
- Las ventas siempre guardarán snapshots de productos, precios y usuario.
- Las ventas y movimientos de caja nunca se sobrescriben.
- Los cambios de productos y usuarios utilizarán última modificación válida.
- No se pueden registrar ventas si no existe una caja abierta.
- Cada venta pertenece a una sesión de caja activa.
- Los productos pueden controlar stock o no.
- Si un producto no controla stock, su stock será `null`.
- Los empleados pueden registrar ventas offline si ya tenían sesión activa y acceso habilitado.
- La inhabilitación remota de empleados se aplicará cuando el dispositivo vuelva a sincronizar.
- Las acciones importantes deben generar logs.
- Las ventas canceladas sólo pueden realizarlas administradores o superadministradores.

---

# Authentication

## Login

### Comportamiento general

- Si no existe una sesión activa, se mostrará la pantalla de login.
- Si es la primera ejecución de la aplicación, se creará una cuenta base de administrador.
- El administrador deberá actualizar sus datos y contraseña al iniciar por primera vez.

### Acceso

El login requiere:
- usuario
- contraseña

Aunque las credenciales sean correctas, si el usuario está inhabilitado no podrá acceder.

### Persistencia de sesión

#### Administrador

- La sesión permanece iniciada hasta cerrar sesión manualmente.

#### Empleado

- La sesión permanece activa durante su turno.
- Si el administrador inhabilita al empleado:
  - si el dispositivo tiene conexión, el cambio se aplica al sincronizar
  - si el empleado está realizando una operación crítica, podrá terminarla antes de cerrar sesión
  - después de sincronizar, el empleado perderá acceso

### Roles

#### Superadmin

Puede:
- crear administradores
- desactivar administradores
- consultar logs completos

#### Administrador

Puede:
- gestionar productos
- gestionar ventas
- gestionar caja
- gestionar pagos pendientes
- gestionar empleados

#### Empleado

Puede:
- registrar ventas
- consultar inventario
- consultar pagos pendientes

No puede:
- editar ventas
- cancelar ventas
- eliminar ventas
- editar productos
- eliminar productos
- modificar configuraciones

---

# Dashboard

La pantalla se divide en estadísticas diarias y semanales.

## Vista diaria

Muestra información desde la apertura de caja actual:

- dinero actual en caja física
- ingresos por efectivo
- ingresos por transferencia
- ingresos por terminal
- ingresos por bonos
- producto que generó más ingresos
- producto más vendido

## Vista semanal

Muestra:

- ingresos totales de la semana
- ingresos por día de la semana
- producto que generó más ingresos
- producto más vendido por cantidad
- producto más vendido por número de ventas
- comparación con la semana anterior
- cantidad total de ventas por semana

## Visualización

- Las estadísticas semanales utilizarán gráficos de barras y pastel.
- Los cálculos se recalcularán dinámicamente utilizando la información almacenada.

---

# Ventas

## Acceso

### Administrador

- Control total.

### Empleado

Puede:
- generar ventas
- consultar historial

No puede:
- editar ventas
- cancelar ventas
- eliminar ventas

---

## Historial de ventas

- Muestra todas las ventas realizadas.
- Cada venta se muestra en una card con:
  - productos
  - cantidades
  - total
  - usuario
  - fecha
  - método de pago
  - estado

### Estados posibles

- completada
- cancelada

Las ventas canceladas:
- revierten movimientos de caja
- revierten ingresos correspondientes
- guardan motivo de cancelación
- generan logs

---

## Generar venta

### Búsqueda de productos

- Incluye buscador de productos.
- Permite agregar productos por nombre.

### Productos a granel

Antes de agregar un producto:
- se puede modificar cantidad
- seleccionar variantes rápidas:
  - 1kg
  - 1/2kg
  - 100gr
  - 50gr
- ingresar cantidad personalizada
- ingresar precio manualmente y calcular cantidad automáticamente

Ejemplos:
- ingresar `250gr` calcula automáticamente el precio
- ingresar `$50` calcula automáticamente la cantidad correspondiente

### Venta

La venta incluye:
- productos
- cantidades
- subtotal
- comisión
- total final
- método de pago
- usuario
- caja asociada

### Métodos de pago

- efectivo
- transferencia
- tarjeta
- bonos
- pago mixto

### Comisiones

- tarjeta: +5%
- bonos: +6.5%
- transferencia y efectivo: sin comisión

La comisión se suma al total del cliente.

### Caja física

- Sólo los pagos en efectivo afectan caja física.
- Transferencias, tarjetas y bonos se registran por separado.

### Stock

- Se pueden vender productos sin control de stock.
- Los productos con stock controlado sí deben validar disponibilidad.

---

# Inventario

## Acceso

### Administrador

- Control total.

### Empleado

- Sólo lectura.

---

## Categorías

- Se muestran todas las categorías existentes.
- Se pueden crear categorías.
- Las categorías sólo pueden eliminarse si no contienen productos.

---

## Subcategorías

- Son opcionales.
- Los productos pueden existir sin subcategoría.
- Al eliminar una subcategoría:
  - los productos pasan automáticamente a "Sin subcategoría"

---

## Búsqueda

### Global

- Busca productos en todas las categorías.

### Por categoría

- Filtra sólo productos de la categoría seleccionada.

---

## Agregar producto

### Campos obligatorios

- nombre
- categoría
- precio

### Campos opcionales

- marca
- subcategoría
- descripción
- control de stock
- tipo de producto

### Tipos de producto

- unidad
- granel

---

## Productos a granel

Los productos a granel almacenan:
- precio por kilogramo

Las cantidades y precios derivados se calculan automáticamente.

---

## Lista de productos

Los productos se ordenan automáticamente para mejorar la lectura visual y agrupar productos relacionados.

### Reglas de ordenamiento

1. Primero se agrupan productos por subcategoría si existe.
2. Dentro de cada subcategoría:
   - el primer producto mostrado será el más barato
   - los siguientes productos intentarán priorizar productos de la misma marca antes que otros similares
3. Si varios productos tienen precios similares, se prioriza mantener juntos los productos de la misma línea o marca.
4. Los productos sin subcategoría aparecerán en la sección "Sin subcategoría".

### Objetivo visual

El objetivo es que productos relacionados permanezcan visualmente cerca entre sí para facilitar:
- búsqueda rápida
- comparación de precios
- lectura visual
- identificación de variantes similares

### Ejemplo

Productos:
- Campeón Adulto — $46/kg
- Nucan Adulto — $50/kg
- Campeón Cachorro — $52/kg

Orden esperado:
1. Campeón Adulto
2. Campeón Cachorro
3. Nucan Adulto

---

## Detalles de producto

Muestra:
- descripción
- categoría
- marca
- precios calculados por porción
- configuración de stock

---

## Editar producto

- Reutiliza la interfaz de creación.
- Las modificaciones generan logs.
- Las ventas anteriores mantienen snapshots históricos.

---

# Caja

## Acceso

Sólo administrador y superadmin.

---

## Funciones

- abrir caja
- registrar dinero inicial
- registrar retiros
- consultar movimientos
- cerrar caja
- consultar diferencia esperada

---

## Restricciones

- Sólo puede existir una caja abierta.
- Si la aplicación se cierra sin cerrar caja:
  - la caja seguirá activa al volver a abrir la app
  - deberá cerrarse antes de abrir una nueva

---

## Movimientos

Cada movimiento debe guardar:
- monto
- motivo
- usuario
- fecha

---

## Caja física e ingresos

La caja debe separar ingresos según el método de pago.

### Caja física

Incluye:
- dinero inicial
- ingresos en efectivo
- retiros
- diferencia esperada

### Ingresos digitales

Se registran por separado:
- transferencias
- terminal
- bonos

Estos ingresos no modifican directamente el efectivo disponible en caja física.

---

# Usuarios

## Acceso

Sólo administrador y superadmin.

---

## Funciones

- crear usuarios
- editar usuarios
- habilitar usuarios
- inhabilitar usuarios
- desactivar usuarios

---

## Datos básicos

- id
- username
- password hash
- teléfono opcional
- rol
- enabled
- fecha de creación

---

# Calculadora

## Acceso

Sólo administrador y superadmin.

---

## Funciones

Permite:
- calcular precio por unidad
- calcular precio por gramos
- calcular precio por kilogramo
- calcular precio desde cajas o paquetes
- agregar porcentaje de ganancia

La calculadora no guarda resultados permanentemente.

---

# Pagos pendientes

## Acceso

Administrador, superadmin y empleado.

---

## Funciones

- crear pagos pendientes
- registrar abonos
- completar pagos
- consultar historial

---

## Datos

Cada pago pendiente debe guardar:

- nombre del cliente
- teléfono opcional
- descripción
- monto total
- monto pagado
- monto restante
- estado
- historial de abonos
- usuario que lo creó

---

## Estados

- pendiente
- parcial
- completado

---

## Integración con ventas

Una venta puede generar automáticamente un pago pendiente si el cliente no paga el total completo.

Ejemplo:
- total venta: $300
- cliente paga: $100
- restante pendiente: $200

---

## Logs de actividad

### Acceso
Sólo administrador y superadmin.

### Ubicación
Dentro de Administración / Configuración.

### Funciones
- Ver acciones importantes del sistema.
- Filtrar por usuario.
- Filtrar por fecha.
- Filtrar por módulo.
- Consultar detalles de acciones críticas.

### Restricciones
- Los logs no se pueden eliminar.
- Los logs no pueden ser editados.
- Los empleados no tienen acceso.

Las siguientes acciones generan logs:

- login
- logout
- apertura de caja
- cierre de caja
- retiros
- creación de usuarios
- edición de usuarios
- habilitación o inhabilitación de usuarios
- creación de productos
- edición de productos
- cambios de precio
- creación de ventas
- edición de ventas
- cancelación de ventas
- creación de pagos pendientes
- modificación de pagos pendientes
- registro de abonos
- sincronización importante de datos