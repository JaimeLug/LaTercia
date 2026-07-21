# Precios, descuentos e IVA

Reglas de negocio del cálculo de totales de una orden. El código vive en
[`lib/core/utils/pricing.dart`](../lib/core/utils/pricing.dart) (lógica pura,
sin UI ni base de datos, para poder probarla aislada — ver
[`test/pricing_test.dart`](../test/pricing_test.dart)).

## Descuentos

Un descuento puede ser de dos tipos:

- **Porcentaje** (`type == 'percentage'`): resta `subtotal × valor / 100`.
- **Fijo** (`type == 'fixed'`): resta una cantidad fija.

El monto del descuento siempre se **acota al rango `[0, subtotal]`**: un descuento
fijo mayor que la orden nunca puede dejar el total (ni el cambio a devolver) en
negativo.

### ¿Cuándo se puede aplicar un descuento?

Un descuento es elegible para una orden solo si cumple **todas** estas
condiciones (se configuran en el panel de admin):

- Está **activo**.
- La fecha actual está **dentro de su ventana de validez** (`validFrom` /
  `validUntil`, si están definidas).
- El subtotal **alcanza el mínimo** de compra (`minOrderAmount`).

## IVA por producto: incluido vs. añadido

Cada producto puede tener su **propia tasa de IVA** y su **propio modo**, o
heredar el default global de la configuración:

- **Tasa efectiva:** la del producto si la definió; si no, la global. Nunca
  negativa.
- **Modo efectivo:** el del producto si lo definió; si no, el global.

Hay dos modos de IVA, y una orden puede **mezclar** productos de ambos:

- **IVA incluido:** el precio del catálogo **ya trae el impuesto dentro**. El
  cliente paga ese precio tal cual; el IVA se calcula "hacia atrás" para
  desglosarlo en el ticket.
- **IVA añadido:** el precio del catálogo es sin impuesto, y el IVA **se suma
  encima** al cobrar.

## Cálculo de totales con IVA por línea

El cálculo por línea (`computeTaxedTotals`) produce cuatro cifras:

| Cifra       | Qué es |
|-------------|--------|
| `subtotal`  | Suma de los precios **mostrados** de cada línea, **antes** de descuento. Para líneas con IVA incluido, ese precio ya trae el impuesto. Es la fila "Subtotal" del POS. |
| `discount`  | El descuento, calculado sobre ese subtotal mostrado y **prorrateado** entre las líneas. |
| `tax`       | El IVA total desglosado: lo que se saca "hacia atrás" de las líneas con IVA incluido, más lo añadido de las que no. Es la cifra para el ticket y los reportes fiscales. |
| `total`     | Lo que el cliente **realmente paga**. Para IVA incluido no se vuelve a sumar (ya está dentro); para IVA añadido sí. Acotado a no ser negativo. |

> **Importante:** con líneas mixtas (unas con IVA incluido y otras con IVA
> añadido), la identidad ingenua `subtotal − descuento + iva == total` **no se
> cumple** — es inherente al IVA incluido. La cifra **`total` es siempre la
> autoritativa**.

## Inferir si el IVA estaba incluido (a partir de totales guardados)

Una orden ya cobrada guarda sus cuatro cifras, pero **no** una columna que diga
si el IVA fue incluido o añadido. Se infiere de los propios totales
(`taxIsIncludedInTotal`):

- Si no hubo IVA (`tax <= 0`): se considera **no incluido**.
- Si sumar el IVA al `subtotal − descuento` **excede** el total guardado,
  significa que el total **no creció** por el IVA ⇒ el IVA ya **estaba dentro**
  del precio (incluido).

Se usa una tolerancia de `0.01` para absorber el redondeo de centavos.
