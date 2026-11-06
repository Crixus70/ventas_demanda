# Guía para el tablero en Power BI

Carpeta de datos: `powerbi\` dentro de este repositorio.

Archivos:

| Archivo | Filas | Uso |
|---|---|---|
| `fact_ventas.csv` | 9,154 | Tabla de hechos: una fila por venta |
| `dim_producto.csv` | 19 | Productos y categoría |
| `dim_sucursal.csv` | 8 | Sucursales |
| `dim_cliente.csv` | 500 | Clientes y segmento |
| `dim_calendario.csv` | 731 | Calendario diario (2024-2025) |
| `pronostico_mensual.csv` | 33 | Real, pronóstico de prueba y proyección por mes |

Los datos son sintéticos.

## 1. Cargar los datos

En Power BI Desktop: **Inicio > Obtener datos > Consulta en blanco**. Crea una consulta por tabla, abre el **Editor avanzado** y pega el código correspondiente. Cambia `RUTA` si tu carpeta es distinta.

**fact_ventas**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\fact_ventas.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"id", Int64.Type}, {"fecha", type date}, {"cliente_id", Int64.Type},
        {"sucursal_id", Int64.Type}, {"producto_id", Int64.Type},
        {"cantidad", Int64.Type}, {"descuento", type number}, {"ingreso", type number}})
in
    Tipos
```

**dim_producto**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\dim_producto.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"id", Int64.Type}, {"nombre", type text}, {"categoria", type text}, {"precio", type number}})
in
    Tipos
```

**dim_sucursal**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\dim_sucursal.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"id", Int64.Type}, {"nombre", type text}, {"ciudad", type text}, {"estado", type text}})
in
    Tipos
```

**dim_cliente**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\dim_cliente.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"id", Int64.Type}, {"nombre", type text}, {"ciudad", type text},
        {"fecha_alta", type date}, {"segmento", type text}})
in
    Tipos
```

**dim_calendario**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\dim_calendario.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"fecha", type date}, {"anio", Int64.Type}, {"mes", Int64.Type},
        {"nombre_mes", type text}, {"trimestre", type text}, {"anio_mes", type text}})
in
    Tipos
```

**pronostico_mensual**
```m
let
    RUTA = "RUTA_A_LA_CARPETA\pronostico_mensual.csv",
    Origen = Csv.Document(File.Contents(RUTA), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),
    Encabezados = Table.PromoteHeaders(Origen, [PromoteAllScalars=true]),
    Tipos = Table.TransformColumnTypes(Encabezados, {
        {"mes", type date}, {"tipo", type text}, {"unidades", type number}})
in
    Tipos
```

## 2. Relaciones

Ve a la vista **Modelo** y crea estas relaciones de muchos a uno (de `fact_ventas` hacia la dimensión):

| Desde (fact_ventas) | Hacia (dimensión) |
|---|---|
| `producto_id` | `dim_producto[id]` |
| `sucursal_id` | `dim_sucursal[id]` |
| `cliente_id` | `dim_cliente[id]` |
| `fecha` | `dim_calendario[fecha]` |

Después marca `dim_calendario` como tabla de fechas: **Herramientas de tabla > Marcar como tabla de fechas > columna `fecha`**. Sin este paso, las medidas de año anterior no funcionan.

`pronostico_mensual` no se relaciona con las demás. Se usa solo en su página.

## 3. Medidas DAX

Crea una tabla vacía llamada `_Medidas` (Inicio > Escribir datos) para guardarlas ahí. Pega cada medida en **Nueva medida**.

```dax
Ingreso = SUM(fact_ventas[ingreso])

Unidades = SUM(fact_ventas[cantidad])

Ticket promedio = DIVIDE([Ingreso], COUNTROWS(fact_ventas))

Ingreso año anterior =
CALCULATE([Ingreso], SAMEPERIODLASTYEAR(dim_calendario[fecha]))

Variación vs año anterior % =
DIVIDE([Ingreso] - [Ingreso año anterior], [Ingreso año anterior])

% del ingreso total =
DIVIDE([Ingreso], CALCULATE([Ingreso], ALL(dim_producto), ALL(dim_sucursal)))

Unidades pronosticadas =
CALCULATE(
    SUM(pronostico_mensual[unidades]),
    pronostico_mensual[tipo] = "Pronóstico estacional (prueba)"
)

Unidades reales (prueba) =
VAR MesesPrueba =
    CALCULATETABLE(
        VALUES(pronostico_mensual[mes]),
        pronostico_mensual[tipo] = "Pronóstico estacional (prueba)"
    )
RETURN
CALCULATE(
    SUM(pronostico_mensual[unidades]),
    pronostico_mensual[tipo] = "Real",
    TREATAS(MesesPrueba, pronostico_mensual[mes])
)

Error % del pronóstico =
DIVIDE(
    ABS([Unidades reales (prueba)] - [Unidades pronosticadas]),
    [Unidades reales (prueba)]
)
```

Formato sugerido: `Ingreso` y `Ticket promedio` en moneda MXN, `Variación` y `% del ingreso` en porcentaje.

## 4. Páginas del tablero

**Página 1: Resumen de ventas**
- Tarjetas: Ingreso, Unidades, Ticket promedio, Variación vs año anterior %.
- Columnas: Ingreso por `dim_calendario[anio_mes]`.
- Segmentación: año (`dim_calendario[anio]`) y sucursal.
- Pregunta que responde: ¿cómo va el negocio y en qué meses sube?

**Página 2: Productos y categorías**
- Barras: Ingreso por `dim_producto[nombre]`, top 10 con filtro Top N.
- Anillo: `% del ingreso total` por `dim_producto[categoria]`.
- Matriz: categoría por sucursal con Ingreso.
- Pregunta que responde: ¿qué productos concentran el ingreso y dónde se venden más?

**Página 3: Sucursales**
- Barras: Ingreso por `dim_sucursal[nombre]`, ordenado de mayor a menor.
- Tabla: sucursal, Ingreso, Unidades, Ticket promedio.
- Pregunta que responde: ¿qué sucursales rinden más y cuál necesita atención?

**Página 4: Pronóstico de demanda**
- Línea: `pronostico_mensual[mes]` en el eje, `unidades` en valores y `tipo` como leyenda.
- Tarjetas: Error % del pronóstico, Unidades pronosticadas.
- Nota en el tablero: "Modelo estacional validado con los últimos 3 meses de 2025. Proyección para ene-mar 2026."
- Pregunta que responde: ¿cuántas unidades conviene planear?

## 5. Verificación

Compara estos valores con el README del proyecto:

- Ingreso por categoría: Electrónica 6,773,785 y Hogar 3,506,959.
- Error % del pronóstico en la página 4: 6.7 %. Es ponderado por unidades. El README reporta 7.3 %, que es el promedio de los errores mensuales; son medidas distintas.
- Filas de `fact_ventas`: 9,154.

Si los números no coinciden, revisa las relaciones y que `dim_calendario` esté marcada como tabla de fechas.
