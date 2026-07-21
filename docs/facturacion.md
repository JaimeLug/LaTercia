# Facturación — prellenado CFDI 4.0

## Qué es (y qué NO es)

Este módulo **prepara** todos los datos fiscales de una venta en el formato del
CFDI 4.0 y los **exporta** a un archivo (Excel/CSV) que el dueño o su contador
importan a cualquier facturador/PAC que ya usen (Facturama, SW, Alegra, Contpaqi,
portal SAT…).

- **NO** timbra ni sella. **NO** somos PAC. **NO** generamos el CFDI legal.
- El archivo exportado es un **prellenado listo para timbrar**, no una factura
  válida. El CFDI real solo existe cuando el PAC lo timbra.
- Este disclaimer debe estar **visible en la pantalla de exportación**, con texto
  claro (ver §Disclaimer).

Resolvemos ~90% del trabajo (capturar y ordenar los datos) sin tocar la parte
legal.

## Alcance v1 vs. fase 2

**v1:**
- Export Excel/CSV genérico con **todas** las columnas del CFDI 4.0, **una fila
  por concepto**. Sin plantilla de facturador específico, sin XML.
- Ambos flujos: (A) **factura individual** cuando el cliente la pide, y (B)
  **factura global** del periodo (todo lo no facturado), colgada del corte Z.
- Buscador de claves SAT con catálogo local.
- Snapshot fiscal congelado al momento de la venta.

**Fase 2 (documentado, fuera de v1):**
- Generar el **XML CFDI 4.0 pre-sello**.
- Plantillas de importación por facturador específico.
- Complemento de **recepción de pagos** (tipo P) para PPD.
- Timbrado/PAC — **nunca** (decisión estratégica).

> Regla de diseño transversal: el **modelo de datos** se diseña pensando en la
> fase 2 (generar el XML). No debe faltar ningún campo del CFDI 4.0, aunque en v1
> solo se exporte a Excel.

## Se reutiliza lo que ya existe

- IVA: `Products.taxRate` + `Products.taxIncluded`, y
  `Orders.taxAmount`/`subtotal`/`discountAmount`/`total`.
- Conceptos ya inmutables: `OrderItems` guarda `productName`, `unitPrice`,
  `quantity`, `modifiersJson`, `itemNote`.
- Formas de pago tipadas: `Payments.method`
  (`efectivo`/`tarjeta`/`transferencia`/`otro`) → se mapea a códigos SAT.
- Periodo de la global: `Shifts.zNumber` delimita el corte Z.
- Clientes: `Customers` — se le agregan campos fiscales opcionales.

## Modelo de datos (migración Drift → schemaVersion 10)

### Columnas nuevas en tablas existentes

- **`Products`** (se llenan una vez por producto, no por venta):
  - `claveProdServ` (text nullable) — `c_ClaveProdServ`.
  - `claveUnidad` (text nullable) — `c_ClaveUnidad`.
  - `objetoImp` (text nullable) — `c_ObjetoImp`: `01` no objeto de impuesto,
    `02` sí objeto, `03` sí objeto y no obligado al desglose.
- **`Customers`** (todos nullable/opcionales; solo si el cliente pide factura):
  - `rfc`, `razonSocial`, `cpFiscal`, `regimenFiscal` (`c_RegimenFiscal`),
    `usoCfdiPreferido` (`c_UsoCFDI`, default sugerido `G03`).
- **`Settings`** (emisor del negocio, key/value):
  - `rfc_emisor`, `razon_social_emisor`, `regimen_fiscal_emisor`,
    `cp_lugar_expedicion`.

### Tabla nueva `FiscalDocs` (cabecera del documento fiscal)

Liga una `orderId` (o un periodo, en la global) con el **snapshot fiscal del
receptor**:

- `id`, `orderId` (nullable para la global consolidada).
- Receptor congelado: `receptorRfc`, `receptorRazonSocial`, `receptorCpFiscal`,
  `receptorRegimen`, `receptorUsoCfdi`.
- `tipo`: `individual` | `global`.
- `estado`: `pendiente` | `exportada`.
- `periodoRef`: para la global, referencia del periodo (día/semana/mes+año).
- `exportedAt` (nullable), `createdAt`, `updatedAt`.

### Tabla nueva `FiscalDocItems` (conceptos congelados)

Snapshot **inmutable** de cada concepto, congelado al momento de la venta / al
marcar la orden para factura (NO se recalcula al exportar):

- `id`, `fiscalDocId`.
- `claveProdServ`, `claveUnidad`, `descripcion`.
- `cantidad`, `valorUnitario` (**sin IVA**), `importe` (**sin IVA**), `descuento`.
- `objetoImp`, `base`, `tasaIva`, `importeIva`.

> **Por qué snapshot y no leer el producto al exportar:** la clave/precio/IVA de
> un producto puede cambiar después de la venta. La factura debe reflejar lo que
> se vendió **ese día**, no el estado actual del catálogo.

### Manejo de `taxIncluded` (crítico)

El CFDI desglosa el IVA aparte, así que si el precio del producto **incluye** IVA
hay que separarlo al congelar el concepto:

- Base (valor sin IVA) = `importe / (1 + tasa)`.
- IVA del concepto = `importe − base`.

Si el IVA es **añadido** (no incluido), el `unitPrice` ya es la base y el IVA se
suma. La lógica de separación reutiliza `Products.taxIncluded` + `taxRate` (ver
`docs/precios-e-iva.md`).

### Prorrateo del descuento y reconciliación

Los conceptos fiscales deben **cuadrar exacto** con los totales que la orden ya
guardó (subtotal/descuento/IVA/total, calculados por `computeTaxedTotals`). Para
lograrlo, el congelado replica la misma matemática por línea:

- `factor = (subtotalBruto − descuento) / subtotalBruto` (proporción que queda
  tras el descuento; `1.0` si no hay descuento).
- Por concepto, con `net` = importe de la línea **sin IVA**:
  - `Importe` (sin IVA, antes de descuento) = `net`.
  - `ValorUnitario` = `net / cantidad`.
  - `Descuento` = `net × (1 − factor)`.
  - `Base` (gravable) = `net × factor` = `Importe − Descuento`.
  - `TasaOCuota` = `tasa/100` (fracción; ej. `0.16`).
  - `ImporteImpuesto` (IVA del concepto) = `Base × tasa/100`.

Así `Σ Base = base gravable de la orden`, `Σ ImporteImpuesto = order.taxAmount`, y
`Σ (Base + IVA) = order.total`. La función que lo calcula es **pura** (sin BD ni
UI) para poder probar la reconciliación con tests.

## Catálogos SAT (asset local + buscador)

Los datos salen de los **catálogos oficiales del SAT** (CSV publicados, ya en el
repo de origen). Contenido y tamaño real:

| Catálogo | Filas | Uso |
|----------|------:|-----|
| `c_ClaveProdServ` | 52,514 | Clave de producto/servicio (el grande) |
| `c_ClaveUnidad` | 2,419 | Unidad de medida |
| `c_Moneda` | 184 | Moneda (MXN) |
| `c_UsoCFDI` | 25 | Uso del CFDI |
| `c_RegimenFiscal` | 20 | Régimen fiscal |
| `c_FormaPago` | 23 | Forma de pago |
| `c_ObjetoImp` | 9 | Objeto de impuesto |
| `c_TipoDeComprobante` | 6 | Tipo de comprobante (I) |
| `c_MetodoPago` | 3 | PUE/PPD |
| `claves_sugeridas_cafeteria` | 23 | Curado: claves típicas de cafetería |

Cada CSV tiene una columna `id` (la clave) y `texto` (la descripción), más
metadatos por catálogo (ej. `c_ClaveProdServ` trae `iva_trasladado`,
`vigencia_desde/hasta`; `c_UsoCFDI` trae `aplica_fisica/moral` y
`regimenes_fiscales_receptores`). Todos en UTF-8.

### Empaquetado: SQLite pre-armado (no CSV en memoria)

- Un script **`tool/build_sat_catalog.dart`** convierte los CSV →
  `assets/sat/catalogos_sat.sqlite` (una tabla por catálogo, con índice en
  `texto` para búsqueda). Se corre una sola vez en desarrollo; el `.sqlite`
  resultante se **commitea como asset**. El CSV crudo no viaja en la app.
- **Por qué SQLite y no CSV:** 52k filas buscadas por subcadena en cada tecla —
  un índice de SQLite busca al instante y sin cargar 3.5 MB a la RAM. Además ya
  usamos el paquete `sqlite3` (para el `.db` de respaldo), así que sin
  dependencias nuevas.
- **Runtime:** los assets no tienen ruta de archivo; en el primer arranque se
  copia el `.sqlite` del bundle a la carpeta de soporte de la app y se abre en
  **solo lectura** con `sqlite3` (mismo patrón que la restauración parcial en
  `docs/backups.md`).

### UI

- Alta/edición de producto → buscador por nombre para `claveProdServ` y
  `claveUnidad`, con las **claves sugeridas de cafetería** como acceso rápido.
- Datos fiscales del cliente → selector de régimen y uso de CFDI desde catálogo.

## Flujo A — Factura individual (en checkout)

1. En el modal de cobro, switch **"¿Requiere factura?"**.
2. Si sí: capturar o recuperar los datos fiscales del cliente (`Customers`) y
   guardarlos para la próxima. Selector de `usoCfdi` para esta venta.
3. Al cerrar la venta: crear `FiscalDoc` (tipo `individual`, estado `pendiente`)
   + congelar sus `FiscalDocItems`.

## Flujo B — Factura global (colgada del corte Z)

1. Al hacer corte Z (o desde el módulo con selector de periodo): consolidar
   **todas** las ventas del periodo que **no** tienen factura individual.
2. Receptor fijo (público en general):
   - RFC `XAXX010101000`, nombre `PUBLICO EN GENERAL`,
     `RegimenFiscalReceptor` `616`, `UsoCFDI` `S01`,
     domicilio fiscal = CP del emisor.
3. Incluir el nodo de **Información Global** (Periodicidad / Mes / Año).
4. Regla operativa: la global debe poder timbrarse **dentro de 24 h** del cierre
   del periodo — el flujo lo facilita, no lo bloquea.
5. **Modo de itemización (flag):**
   - **Default:** una fila por concepto itemizado del periodo.
   - **Alternativa:** una línea por ticket con clave genérica `01010101` /
     unidad `ACT` (algunos contadores lo prefieren).

## Exportador Excel/CSV — columnas (CFDI 4.0)

Una fila por concepto. Manejar `taxIncluded` (separar base/IVA como arriba).

**Nivel comprobante** (repetido por fila o en hoja aparte):
Fecha (de la venta), FormaPago (`c_FormaPago`), MetodoPago (PUE/PPD, default PUE),
Moneda (MXN), TipoDeComprobante (`I`), LugarExpedicion (CP emisor), Folio interno
(`orderNumber`).

**Receptor:**
Rfc, Nombre/RazonSocial, DomicilioFiscalReceptor (CP), RegimenFiscalReceptor,
UsoCFDI.

**Concepto:**
ClaveProdServ, NoIdentificacion (SKU, opcional), Cantidad, ClaveUnidad,
Descripcion, ValorUnitario (sin IVA), Importe (sin IVA), Descuento (opcional),
ObjetoImp, Impuesto (`002`=IVA), TipoFactor (`Tasa`), TasaOCuota (ej.
`0.160000`), Base, ImporteImpuesto (IVA del concepto).

**Botones:** "Exportar facturas individuales pendientes (periodo)" y "Exportar
factura global (periodo)". Al exportar, marcar los `FiscalDocs` como `exportada`
(con fecha).

## Mapeos SAT (verificar contra catálogos vigentes)

- **FormaPago:** efectivo→`01`, transferencia→`03`, tarjeta crédito→`04`, tarjeta
  débito→`28`. `Payments.method` **no** distingue crédito vs. débito → se usa
  `04` por default, **configurable**, y se documenta.
- **MetodoPago:** `PUE` por default (el café se paga en el acto); `PPD` solo si
  hay crédito.
- **ObjetoImp / IVA de alimentos:** matiz real (preparado para consumo suele
  16%, hay casos 0%) → viene del producto (`objetoImp` + `taxRate`), **no** se
  calcula en el export.

## Disclaimer obligatorio (UI de export)

Texto visible en la pantalla de exportación, tipo:

> "Este archivo es un **prellenado para timbrar**, NO es una factura válida. El
> CFDI existe solo cuando tu facturador/PAC lo timbra."

## Orden de implementación sugerido

1. Migración v10 (columnas + tablas nuevas) + servicio de emisor en Settings.
2. Catálogos SAT como asset + servicio de búsqueda (empezar con un seed curado
   de alimentos/cafetería, con la infraestructura para el catálogo completo).
3. Servicio fiscal puro: congelar `FiscalDocItems` desde una orden (con la
   separación base/IVA), crear `FiscalDoc` individual y consolidar la global.
4. UI: campos SAT en producto, datos fiscales en cliente, emisor en Config.
5. Flujo A en el modal de cobro; Flujo B en el corte Z / módulo de facturación.
6. Exportador Excel/CSV con las columnas de arriba + disclaimer.
7. Tests con dientes en cada capa (sobre todo la separación base/IVA, la
   consolidación de la global, y el mapeo SAT).
