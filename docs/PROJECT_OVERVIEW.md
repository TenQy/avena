# Project Overview

La aplicación busca ayudar a una tienda pequeña a gestionar productos, ventas, caja, empleados y pagos pendientes desde dispositivos móviles, priorizando rapidez, bajo costo, funcionamiento sin internet y facilidad de uso.

El sistema está pensado principalmente para tiendas pequeñas donde no se desea depender de una computadora. El administrador o dueño podrá gestionar el negocio desde su celular, mientras que los empleados podrán registrar ventas desde sus propios dispositivos con acceso controlado.

## Objetivo principal

Crear una aplicación móvil que permita operar una tienda pequeña de forma sencilla, manteniendo la información disponible localmente y sincronizándola con la nube cuando exista conexión a internet.

## Funciones principales

- Control de inventario.
- Registro e historial de ventas.
- Apertura, seguimiento y cierre de caja.
- Dashboard con analíticas del día y la semana.
- Gestión de pagos pendientes de clientes.
- Administración de usuarios y permisos de empleados.
- Activación e inhabilitación temporal del acceso de empleados.
- Calculadora para estimar precios de venta.
- Funcionamiento offline para operaciones principales.
- Sincronización con la nube cuando haya conexión a internet.
- Conexión entre al menos dos dispositivos: administrador y empleado.

## Enfoque técnico general

La app seguirá un enfoque offline-first.

Esto significa que las operaciones principales deberán funcionar aunque no exista conexión a internet. Los datos se guardarán localmente en el dispositivo y, cuando exista conexión, se sincronizarán con una base de datos en la nube.

La base de datos externa deberá evitar costos obligatorios. Para esto se evaluará el uso de Firebase o Supabase, aprovechando sus planes gratuitos y optimizando el uso de datos, evitando almacenar archivos pesados como imágenes.

## Usuarios principales

### Administrador / Dueño

Usuario principal del sistema. Puede gestionar productos, empleados, caja, ventas, pagos pendientes, estadísticas y configuración general.

Al iniciar el sistema, existirá una cuenta base de administrador. El dueño deberá actualizar sus datos para comenzar a usar la aplicación sin pasar por un flujo largo de configuración inicial.

### Empleado

Usuario creado por el administrador. Puede iniciar sesión desde su propio dispositivo y registrar ventas mientras su acceso esté habilitado.

El administrador puede habilitar o inhabilitar el acceso del empleado. Si el acceso está inhabilitado, el empleado no podrá iniciar sesión ni seguir usando la aplicación.

## Flujo principal

1. El administrador abre la aplicación.
2. El sistema utiliza una cuenta base de administrador.
3. El dueño actualiza los datos de la cuenta principal.
4. El administrador abre la caja registrando el dinero inicial.
5. El administrador habilita el acceso del empleado.
6. El empleado inicia sesión desde su dispositivo.
7. El empleado registra ventas durante su turno.
8. El sistema actualiza inventario, caja e historial de ventas.
9. Si no hay internet, los datos se guardan localmente.
10. Cuando vuelve la conexión, los datos pendientes se sincronizan con la nube.
11. Al terminar el turno, el administrador inhabilita el acceso del empleado.
12. El empleado pierde acceso y no puede volver a iniciar sesión hasta que el administrador lo habilite nuevamente.

## Restricciones importantes

- La app debe funcionar principalmente en móvil.
- Las operaciones principales deben funcionar sin internet.
- La sincronización en la nube debe evitar costos obligatorios.
- No se almacenarán imágenes de productos en la nube durante la primera versión.
- El sistema debe contemplar al menos dos dispositivos: administrador y empleado.
- El acceso de empleados debe poder habilitarse e inhabilitarse desde la app.
- La interfaz debe ser rápida, simple y clara para uso en tienda.

## Alcance inicial

La primera versión se enfocará en:

- Inventario básico.
- Registro de ventas.
- Control de caja.
- Usuarios con roles.
- Acceso habilitado o inhabilitado para empleados.
- Funcionamiento local.
- Sincronización básica con la nube.
- Dashboard simple del día y la semana.

## Decisiones pendientes

- Definir si se usará Firebase o Supabase.
- Definir la base de datos local: SQLite, Drift, Isar u otra alternativa.
- Definir estrategia exacta de sincronización entre dispositivos.
- Definir cómo se resolverán conflictos cuando dos dispositivos modifiquen datos relacionados.
- Definir si el empleado podrá registrar ventas sin internet desde su dispositivo personal.
- Definir si el cierre de caja será obligatorio antes de terminar turno.