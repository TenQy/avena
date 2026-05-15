# Database

## Enfoque general

La aplicación utiliza un enfoque offline-first.

Los datos se guardan localmente en el dispositivo y se sincronizan con la nube cuando exista conexión a internet.

La base de datos debe permitir:

- Operar sin internet.
- Sincronizar datos entre dispositivos.
- Registrar ventas aunque el dispositivo esté offline.
- Mantener historial confiable.
- Evitar sobrescribir ventas y movimientos de caja.
- Guardar snapshots de datos importantes.
- Mantener logs de acciones críticas.

---

# Reglas generales

- Todas las entidades principales deben usar `UUID` como identificador.
- No usar IDs autoincrementales, ya que la app puede trabajar offline en varios dispositivos.
- Las ventas nunca se sobrescriben.
- Los movimientos de caja nunca se sobrescriben.
- Las ventas deben guardar snapshots de productos, precios y usuario.
- Los productos pueden controlar stock o no.
- Si un producto no controla stock, su stock será `null`.
- Los cambios de productos y usuarios usan última modificación válida.
- Las eliminaciones importantes deben manejarse con desactivación o soft delete.
- Las acciones importantes generan logs.
- La sincronización debe registrar estado local/remoto.

---

# Campos comunes recomendados

La mayoría de entidades deberían incluir:

- `id`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `isDeleted`
- `syncStatus`

## syncStatus

Valores posibles:

- `synced`
- `pendingCreate`
- `pendingUpdate`
- `pendingDelete`
- `conflict`

---

# Entidades principales

## Users

Representa a los usuarios del sistema.

Roles posibles:

- `superadmin`
- `admin`
- `employee`

Campos:

- `id`
- `username`
- `passwordHash`
- `role`
- `isActive`
- `phone`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `isDeleted`
- `syncStatus`

Reglas:

- Los usuarios no deben eliminarse físicamente si ya tienen ventas, logs o movimientos asociados.
- Un usuario desactivado no puede iniciar sesión.
- El superadmin no debe poder eliminarse desde la app.
- Cada venta debe guardar snapshot del usuario que la realizó.

---

## EmployeeSessions

Representa sesiones o turnos de empleados.

Campos:

- `id`
- `userId`
- `startedByAdminId`
- `endedByAdminId`
- `startedAt`
- `endedAt`
- `status`
- `syncStatus`

Estados posibles:

- `active`
- `ended`
- `forcedClosed`

Reglas:

- El empleado puede vender offline si ya tenía sesión activa.
- Si el admin inhabilita al empleado, la sesión se cerrará cuando el dispositivo sincronice.
- Si el empleado está en una operación crítica, puede terminarla antes del cierre.

---

## Categories

Representa categorías principales.

Campos:

- `id`
- `name`
- `sortOrder`
- `isActive`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `isDeleted`
- `syncStatus`

Reglas:

- Una categoría sólo puede eliminarse si no tiene productos.
- Si tiene productos, debe impedirse la eliminación o solicitar mover productos antes.
- La categoría principal puede usar `sortOrder = 0`.

---

## Subcategories

Representa subcategorías dentro de una categoría.

Campos:

- `id`
- `categoryId`
- `name`
- `sortOrder`
- `isActive`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `isDeleted`
- `syncStatus`

Reglas:

- Una subcategoría pertenece a una categoría.
- Los productos pueden existir sin subcategoría.
- Si se elimina una subcategoría, los productos asociados pasan a `subcategoryId = null`.

---

## Products

Representa productos vendidos en la tienda.

Campos:

- `id`
- `name`
- `brand`
- `categoryId`
- `subcategoryId`
- `description`
- `productType`
- `price`
- `priceUnit`
- `trackStock`
- `stockQuantity`
- `isActive`
- `createdAt`
- `updatedAt`
- `deletedAt`
- `isDeleted`
- `syncStatus`

## productType

Valores posibles:

- `unit`
- `bulk`

## priceUnit

Valores posibles:

- `unit`
- `kg`

Reglas:

- Si `productType = bulk`, el precio representa precio por kilogramo.
- Si `productType = unit`, el precio representa precio por unidad.
- Si `trackStock = false`, `stockQuantity = null`.
- Si `trackStock = true`, `stockQuantity` debe tener valor numérico.
- Las ventas históricas no se modifican si cambia el producto.
- Los cambios de precio generan logs.

---

## CashSessions

Representa una caja abierta durante el día o turno.

Campos:

- `id`
- `openedByUserId`
- `closedByUserId`
- `openingCashAmount`
- `expectedCashAmount`
- `closingCashAmount`
- `cashDifference`
- `cashIncome`
- `transferIncome`
- `terminalIncome`
- `bonusIncome`
- `commissionTotal`
- `status`
- `openedAt`
- `closedAt`
- `syncStatus`

Estados posibles:

- `open`
- `closed`

Reglas:

- Sólo puede existir una caja abierta.
- No puede registrarse una venta sin caja abierta.
- Si la app se cierra sin cerrar caja, la caja sigue abierta.
- Antes de abrir una caja nueva, debe cerrarse la anterior.
- Sólo el efectivo modifica la caja física.
- Transferencias, terminal y bonos se registran por separado.

---

## CashMovements

Representa movimientos manuales de caja.

Campos:

- `id`
- `cashSessionId`
- `createdByUserId`
- `type`
- `amount`
- `reason`
- `createdAt`
- `syncStatus`

Tipos posibles:

- `withdrawal`
- `deposit`
- `adjustment`

Reglas:

- Todo retiro debe tener motivo.
- Los movimientos de caja nunca se sobrescriben.
- Cada movimiento genera log.

---

## Sales

Representa una venta.

Campos:

- `id`
- `cashSessionId`
- `userId`
- `userNameSnapshot`
- `userRoleSnapshot`
- `subtotal`
- `commissionTotal`
- `total`
- `paidAmount`
- `pendingAmount`
- `paymentStatus`
- `saleStatus`
- `createdAt`
- `cancelledAt`
- `cancelledByUserId`
- `cancelReason`
- `syncStatus`

## paymentStatus

Valores posibles:

- `paid`
- `partial`
- `pending`

## saleStatus

Valores posibles:

- `completed`
- `cancelled`

Reglas:

- Cada venta debe estar ligada a una caja abierta.
- Las ventas nunca se sobrescriben.
- Una venta cancelada no se elimina.
- Cancelar una venta revierte caja e ingresos correspondientes.
- Sólo admin y superadmin pueden cancelar ventas.
- La cancelación debe guardar motivo.
- Si una venta queda pendiente total o parcialmente, puede generar un pago pendiente.

---

## SaleItems

Representa productos dentro de una venta.

Campos:

- `id`
- `saleId`
- `productId`
- `productNameSnapshot`
- `productBrandSnapshot`
- `productTypeSnapshot`
- `priceUnitSnapshot`
- `unitPriceSnapshot`
- `quantity`
- `quantityUnit`
- `subtotal`

## quantityUnit

Valores posibles:

- `unit`
- `kg`
- `g`

Reglas:

- Siempre debe guardar snapshot del producto.
- Si el producto cambia después, la venta conserva los datos originales.
- Para productos a granel, se guarda cantidad y unidad usada.
- Para productos por unidad, se guarda cantidad de unidades.

---

## SalePayments

Representa los métodos de pago usados en una venta.

Campos:

- `id`
- `saleId`
- `paymentMethod`
- `baseAmount`
- `commissionRate`
- `commissionAmount`
- `totalCharged`
- `createdAt`
- `syncStatus`

## paymentMethod

Valores posibles:

- `cash`
- `transfer`
- `card`
- `bonus`

Reglas:

- Una venta puede tener uno o varios métodos de pago.
- El efectivo afecta caja física.
- Transferencia, tarjeta y bonos no afectan caja física.
- Tarjeta agrega comisión de 5%.
- Bonos agrega comisión de 6.5%.
- La comisión se suma al total cobrado al cliente.

Ejemplo:

- Venta base: `$100`
- Pago con tarjeta: `$100`
- Comisión: `5%`
- Total cobrado: `$105`
- Caja física: sin cambios
- Ingreso terminal: `$105`

---

## PendingPayments

Representa pagos pendientes o deudas.

No existe entidad `Customer` en la primera versión. Los datos del cliente se guardan directamente en el pago pendiente.

Campos:

- `id`
- `saleId`
- `customerName`
- `customerPhone`
- `description`
- `totalAmount`
- `paidAmount`
- `remainingAmount`
- `status`
- `createdByUserId`
- `createdAt`
- `completedAt`
- `syncStatus`

Estados posibles:

- `pending`
- `partial`
- `completed`

Reglas:

- Un pago pendiente puede nacer desde una venta.
- Un pago pendiente puede crearse manualmente.
- No se elimina al completarse.
- Se marca como `completed`.
- Debe conservar historial de abonos.

---

## PendingPaymentEntries

Representa abonos realizados a un pago pendiente.

Campos:

- `id`
- `pendingPaymentId`
- `createdByUserId`
- `amount`
- `paymentMethod`
- `createdAt`
- `note`
- `syncStatus`

Reglas:

- Cada abono se registra por separado.
- Los abonos nunca se sobrescriben.
- Cada abono actualiza el monto pagado y restante del pago pendiente.
- Si el monto restante llega a 0, el pago pendiente se marca como completado.

---

## ActivityLogs

Registra acciones importantes del sistema.

Campos:

- `id`
- `userId`
- `userNameSnapshot`
- `userRoleSnapshot`
- `action`
- `entityType`
- `entityId`
- `description`
- `createdAt`
- `syncStatus`

Acciones mínimas:

- `login`
- `logout`
- `open_cash_session`
- `close_cash_session`
- `create_cash_movement`
- `create_user`
- `update_user`
- `enable_user`
- `disable_user`
- `create_product`
- `update_product`
- `change_product_price`
- `create_sale`
- `edit_sale`
- `cancel_sale`
- `create_pending_payment`
- `update_pending_payment`
- `create_payment_entry`
- `sync_completed`
- `sync_conflict`

Reglas:

- Los logs no deben eliminarse.
- Los logs deben guardar snapshot del usuario.
- Los logs deben ser consultables por admin y superadmin.

---

## SyncQueue

Representa operaciones locales pendientes de sincronización.

Campos:

- `id`
- `entityType`
- `entityId`
- `operation`
- `payload`
- `status`
- `attempts`
- `lastError`
- `createdAt`
- `updatedAt`

## operation

Valores posibles:

- `create`
- `update`
- `delete`

## status

Valores posibles:

- `pending`
- `processing`
- `synced`
- `failed`

Reglas:

- Cada cambio local importante debe agregarse a la cola de sincronización.
- La app debe intentar sincronizar cuando recupere conexión.
- Si falla, debe incrementar `attempts`.
- Si hay conflicto, debe marcarse para revisión o resolverse con reglas definidas.

---

# Snapshots

Las siguientes entidades deben guardar snapshots:

## Sales

- `userNameSnapshot`
- `userRoleSnapshot`

## SaleItems

- `productNameSnapshot`
- `productBrandSnapshot`
- `productTypeSnapshot`
- `priceUnitSnapshot`
- `unitPriceSnapshot`

## ActivityLogs

- `userNameSnapshot`
- `userRoleSnapshot`

Objetivo:

- Evitar que ventas antiguas cambien si un producto se edita.
- Mantener historial confiable.
- Poder auditar acciones aunque un usuario sea desactivado.
- Evitar inconsistencias visuales en historial.

---

# Reglas de sincronización

## Ventas

- Las ventas nunca se sobrescriben.
- Si dos dispositivos crean ventas offline, ambas ventas se conservan.
- Cada venta debe tener UUID propio.
- Cada venta pertenece a una caja.

## Movimientos de caja

- Los movimientos de caja nunca se sobrescriben.
- Cada movimiento se agrega como evento nuevo.

## Productos

- Los productos usan última modificación válida.
- Si existe conflicto, gana el registro con `updatedAt` más reciente.
- Las ventas antiguas no cambian porque usan snapshots.

## Usuarios

- Los usuarios usan última modificación válida.
- Si un usuario es inhabilitado en otro dispositivo, el cambio se aplica al sincronizar.

## Pagos pendientes

- Los abonos nunca se sobrescriben.
- Cada abono se agrega como entrada nueva.
- El estado del pago pendiente se recalcula según total pagado.

---

# Relaciones principales

```text
User
 ├── EmployeeSessions
 ├── Sales
 ├── CashSessions
 ├── CashMovements
 ├── PendingPayments
 ├── PendingPaymentEntries
 └── ActivityLogs

Category
 ├── Subcategories
 └── Products

Subcategory
 └── Products

Product
 └── SaleItems

CashSession
 ├── Sales
 └── CashMovements

Sale
 ├── SaleItems
 ├── SalePayments
 └── PendingPayment

PendingPayment
 └── PendingPaymentEntries
```

---

# Decisiones tomadas

- Se usará enfoque offline-first.
- Se usarán UUIDs.
- No habrá entidad `Customer` en la primera versión.
- Los datos del cliente se guardarán dentro de `PendingPayments`.
- Los productos sin control de stock tendrán `stockQuantity = null`.
- Las ventas se ligan siempre a una caja abierta.
- La caja física sólo cambia con efectivo.
- Transferencias, terminal y bonos se registran por separado.
- Las ventas canceladas no se eliminan.
- Las acciones críticas generan logs.
- La sincronización debe ser incremental.