# Design System

## Estilo general

La aplicación utiliza una estética cálida, limpia y suave, basada en tonos avena/café claro.

El diseño debe sentirse:
- simple
- rápido
- cálido
- ordenado
- amigable para una tienda pequeña
- fácil de usar en móvil

La interfaz debe priorizar claridad sobre decoración excesiva.

---

## Paleta de colores

```dart
class AppColors {
  static const Color headerNav = Color(0xFFEAE0CE);
  static const Color bodyBg    = Color(0xFFF2EDE4);
  static const Color cardSurface   = Color(0xFFFAF6F0);
  static const Color accent        = Color(0xFFD4BFA0);
  static const Color iconInactive  = Color(0xFF8C6A45);
  static const Color textPrimary   = Color(0xFF4A3220);
  static const Color textSecondary = Color(0xFF8C6A45);
  static const Color border        = Color(0xFFD4BFA0);
}
```

## Uso de colores

| Color | Uso |
|---|---|
| `headerNav` | Header, navbar inferior, zona visual superior de cards |
| `bodyBg` | Fondo general de pantallas |
| `cardSurface` | Cards, inputs, modales y superficies principales |
| `accent` | Detalles suaves, fondos secundarios, estados destacados |
| `iconInactive` | Íconos secundarios o inactivos |
| `textPrimary` | Texto principal, íconos activos, FAB |
| `textSecondary` | Texto secundario y descripciones |
| `border` | Bordes, divisores y separadores |

---

## Tipografía

La app usa tipografía del sistema mediante Flutter Material 3.

### Jerarquía

| Estilo | Tamaño | Peso | Uso |
|---|---:|---:|---|
| `titleLarge` | 18 | 600 | Títulos principales |
| `titleMedium` | 16 | 500 | Subtítulos o títulos de sección |
| `bodyLarge` | 15 | normal | Texto principal |
| `bodyMedium` | 14 | normal | Texto estándar |
| `bodySmall` | 12 | normal | Texto secundario |
| `labelSmall` | 11 | normal | Labels de navegación o detalles pequeños |

---

## Espaciado

Usar espaciado consistente en múltiplos de `4`.

### Valores recomendados

| Token | Valor | Uso |
|---|---:|---|
| `xs` | 4 | Separaciones mínimas |
| `sm` | 8 | Separación corta |
| `md` | 12 | Separación entre elementos cercanos |
| `lg` | 16 | Padding estándar de pantalla |
| `xl` | 20 | Modales y secciones importantes |
| `xxl` | 24 | Separación grande |

### Padding de pantalla

```dart
EdgeInsets.fromLTRB(16, 16, 16, 8)
```

Para listas con FAB:

```dart
EdgeInsets.fromLTRB(16, 8, 16, 100)
```

---

## Bordes y radios

### Radios principales

| Elemento | Radio |
|---|---:|
| Cards | 14 |
| Inputs generales | 12 |
| Inputs de búsqueda | 30 |
| Bottom sheets | 20 superior |
| Botones/acciones pequeñas | 10 a 12 |

### Bordes

Los bordes deben ser sutiles:

```dart
BorderSide(
  color: AppColors.border,
  width: 0.5,
)
```

---

## AppBar / Header

El header principal debe usar `AppHeader`.

### Estilo

- Fondo: `headerNav`
- Texto: `textPrimary`
- Elevación: `0`
- Altura visual limpia
- Sin sombra
- Íconos en `textPrimary`

### Uso

El header debe mostrar:
- título de pantalla
- acciones opcionales según módulo
- navegación clara cuando sea necesario

Ejemplo:

```dart
appBar: AppHeader(title: 'Inventario')
```

---

## Bottom Navigation Bar

La navegación inferior usa `AppNavBar`.

### Estilo

- Fondo: `headerNav`
- Item activo: `textPrimary`
- Item inactivo: `iconInactive`
- Elevación: `0`
- Tipo: `fixed`
- Label activo: `fontSize 11`, `fontWeight 600`
- Label inactivo: `fontSize 11`

### Uso

Debe mostrarse en pantallas principales como:
- Dashboard
- Ventas
- Inventario
- Caja / Configuración según rol

La navegación debe ocultar módulos que el rol actual no puede usar.

No debe mostrarse en:
- Login
- Formularios de creación complejos
- Pantallas modales
- Flujos donde el usuario debe enfocarse en una tarea

---

## Cards

Las cards deben usar `cardSurface` como fondo.

### Estilo base

```dart
CardThemeData(
  color: AppColors.cardSurface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(color: AppColors.border, width: 0.5),
  ),
  margin: EdgeInsets.zero,
)
```

### Reglas

- No usar sombras fuertes.
- Priorizar bordes suaves.
- Mantener padding interno claro.
- Evitar saturar la card con demasiada información.
- Usar `textPrimary` para contenido importante.
- Usar `textSecondary` para detalles.

---

## Cards de categoría

Las cards de categoría tienen una estructura visual dividida en dos zonas.

### Zona superior

- Fondo: `headerNav`
- Altura aproximada: `80`
- Ícono centrado
- Ícono en `iconInactive`
- Tamaño de ícono: `36`

### Zona inferior

- Fondo: `cardSurface`
- Padding horizontal: `12`
- Padding vertical: `10`
- Nombre en mayúsculas
- Color: `textPrimary`
- Tamaño: `13`
- Peso: `500`
- Letter spacing: `0.6`
- Máximo una línea con ellipsis

### Comportamiento

- Tap: abre la categoría.
- Long press: muestra opciones.
- Si es categoría principal, puede ocupar una card destacada.
- El resto de categorías se muestran en grid de dos columnas.

---

## Inputs

Los inputs deben ser suaves, claros y fáciles de identificar. El estilo base debe sentirse más rectangular que circular para mantener una interfaz ordenada y de lectura rápida.

### Estilo

- Fondo: `cardSurface`
- Radio: `12`
- Borde: `border`, `0.5`, con opacidad suave cuando aplique
- Borde enfocado: `accent` o `textPrimary`, `0.5` a `1` según jerarquía
- Padding interno: horizontal `16`, vertical `12`
- Hint: `iconInactive`, tamaño `14`

### Inputs con ícono

Para formularios importantes como login:
- El ícono debe ir dentro del input.
- El ícono debe usar `iconInactive`.
- Debe existir un separador vertical sutil entre ícono y texto.
- El separador debe usar `border`, `0.5`.
- El bloque de ícono debe tener ancho estable, alrededor de `52`.
- El separador debe cubrir visualmente la altura útil del input.
- Los inputs pueden llevar padding horizontal externo para no ocupar todo el ancho de la pantalla.
- Los inputs de contraseña deben incluir acción para mostrar u ocultar el texto.

### Layout de formularios

- En mobile, los inputs deben ser anchos pero no tocar los bordes visuales del contenido.
- Usar un ancho máximo razonable en pantallas grandes, alrededor de `420`.
- Mantener separación vertical amplia entre grupos principales.
- Evitar encerrar formularios simples en cards si la pantalla ya tiene un foco claro.

### Search input

El buscador debe incluir:
- ícono de búsqueda a la izquierda
- botón de limpiar cuando hay texto
- cierre de teclado al tocar fuera

Ejemplo de hint:

```text
Buscar producto...
```

---

## Floating Action Button

Usar `AppFab` para acciones principales.

### Estilo

- Fondo: `textPrimary`
- Texto/ícono: `cardSurface`
- Elevación: `0`

### Uso

El FAB puede tener múltiples acciones cuando la pantalla lo requiera.

Ejemplo en inventario:
- Nuevo producto
- Nueva categoría

### Reglas

- No usar FAB para acciones destructivas.
- No mostrar demasiadas acciones.
- Máximo recomendado: 3 acciones.
- Si aparece un snackbar inferior, el FAB debe desplazarse hacia arriba y volver a su posición cuando el snackbar desaparezca.

---

## Botones principales

Los botones principales deben sentirse claros y táctiles sin verse pesados.

### Estilo

- Radio: `12`
- Fondo: `textPrimary`
- Texto/ícono: `cardSurface`
- Elevación: `0`
- Padding vertical suficiente para toque cómodo.

### Uso en formularios

- El botón principal debe aparecer debajo de los inputs.
- Puede ser más angosto que los inputs para reforzar jerarquía.
- En login, el botón debe estar centrado.
- Si el botón tiene ícono y texto, el ícono puede ir a la derecha cuando la acción representa avanzar o entrar.
- En formularios y acciones compactas, cuando un botón tiene texto e ícono, el ícono debe colocarse a la derecha del texto para mantener consistencia visual.
- Los formularios en bottom sheet deben separar el título del contenido con un divisor sutil usando `AppColors.border` cuando el contenido empiece inmediatamente debajo del encabezado.

---

## Login

La pantalla de login debe ser simple, centrada y sin navbar.

### Estructura visual

- Fondo general: `bodyBg`.
- No usar card o recuadro contenedor para todo el formulario.
- Logo/ícono de tienda centrado en la parte superior.
- Logo grande, con fondo `headerNav` y radio suave.
- Nombre de tienda centrado debajo del logo.
- Texto secundario centrado debajo del nombre.
- Inputs centrados debajo del texto, con separación vertical amplia.
- Botón principal centrado debajo de los inputs.

### Reglas

- No mostrar información secundaria innecesaria.
- Mantener el login limpio y enfocado.
- Evitar sombras y bordes fuertes.
- Cerrar teclado al tocar fuera del formulario.

---

## Bottom Sheets

Los bottom sheets se usan para:
- crear categorías
- mostrar opciones rápidas
- confirmar acciones secundarias

### Estilo

```dart
showModalBottomSheet(
  isScrollControlled: true,
  backgroundColor: AppColors.cardSurface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
)
```

### Handle visual

- Ancho: `36`
- Alto: `4`
- Color: `border`
- Radio: `2`

---

## Diálogos de confirmación

Usar diálogos de confirmación para acciones destructivas como:
- eliminar categoría
- cancelar venta
- desactivar usuario
- cerrar caja

### Reglas

Todo diálogo destructivo debe explicar:
- qué se eliminará o modificará
- si la acción se puede deshacer
- consecuencia principal

Ejemplo:

```text
Se eliminará "Categoría" y todos los productos dentro. Esta acción no se puede deshacer.
```

Nota: para categorías con productos, la regla funcional final debe evitar eliminación directa y pedir mover productos o cancelar acción. Porque borrar todo por accidente es una tradición humana que conviene no facilitar.

---

## Íconos

Usar íconos redondeados de Material Icons.

### Categorías

Los íconos se asignan automáticamente por nombre de categoría.

Reglas actuales:
- alimento, mascota, perro, gato → `Icons.pets_rounded`
- granel → `Icons.scale_rounded`
- dulce, candy, golosina → `Icons.cookie_rounded`
- especia, chile, hierba, condimento → `Icons.grass_rounded`
- abarrote, básico → `Icons.shopping_basket_rounded`
- combustible, carbón, leña → `Icons.local_fire_department_rounded`
- fallback → `Icons.category_rounded`

---

## Estados vacíos

Las pantallas sin datos deben mostrar:
- ícono grande
- mensaje principal
- mensaje secundario opcional

### Ejemplo

```text
Sin categorías aún
Toca + para agregar una
```

### Estilo

- Ícono: tamaño `48`, color `iconInactive`
- Texto principal: `textSecondary`, tamaño `15`
- Texto secundario: `iconInactive`, tamaño `13`

---

## Listas y grids

### Categorías

- La categoría principal aparece primero.
- Las demás categorías se muestran en grid de dos columnas.
- Separación horizontal: `12`
- Separación vertical: `12`
- Padding inferior amplio si existe FAB.

### Productos

- Deben priorizar lectura rápida.
- Agrupar visualmente por subcategoría.
- Mantener productos similares cerca.
- Evitar cards demasiado altas.

---

## Estados de conexión

La app debe mostrar de forma discreta el estado de sincronización.

### Estados posibles

- Online
- Offline
- Sincronizando
- Error de sincronización

### Reglas visuales

- No interrumpir al usuario por estar offline.
- Mostrar estado en header, banner pequeño o indicador discreto.
- No usar alertas invasivas salvo que una acción no pueda completarse.

---

## Acciones destructivas

Acciones como eliminar, cancelar o desactivar deben usar color rojo sólo en puntos específicos.

### Uso permitido de rojo

- Ícono de eliminar
- Texto de acción destructiva
- Confirmaciones críticas

No usar rojo para decoración general.

---

## Tono visual por módulo

### Dashboard

- Cards resumidas.
- Métricas claras.
- Gráficos simples.
- Sin saturar la pantalla.

### Ventas

- Flujo rápido.
- Botones grandes.
- Total siempre visible.
- Métodos de pago claros.

### Inventario

- Visual por categorías.
- Cards limpias.
- Buscador visible.
- FAB para crear producto/categoría.

### Caja

- Separar caja física e ingresos digitales.
- Mostrar diferencias de forma clara.
- Resaltar retiros y movimientos importantes.

### Usuarios

- Listas simples.
- Estado activo/inactivo visible.
- Acciones administrativas protegidas.

---

## Reglas generales de UI

- Mantener diseño mobile-first.
- Evitar pantallas saturadas.
- Priorizar acciones rápidas.
- Usar textos cortos y claros.
- Mantener consistencia entre cards, inputs y modales.
- No usar colores fuera de la paleta salvo estados críticos.
- Evitar sombras fuertes.
- Evitar animaciones pesadas.
- Mantener una estética cálida y sobria.
