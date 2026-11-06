# ¿Cuánto inventario comprar el próximo mes? Pronóstico de demanda con SQL y Python

Caso de negocio para una cadena minorista ficticia con 8 sucursales en México, dos de ellas en la Ciudad de México (Polanco y Santa Fe). Responde tres preguntas:

1. **¿Qué productos, categorías y sucursales generan más ingreso?**
2. **¿Cómo cambia la demanda mes a mes y en qué meses hay picos?**
3. **¿Cuántas unidades conviene planear para los próximos 3 meses?**

Todas las cifras están en pesos mexicanos (MXN).

> **Nota sobre los datos:** la base `data/ventas.db` es **sintética**. Los nombres de clientes, productos y sucursales fueron generados para practicar. Las conclusiones describen el comportamiento del dataset, no de una empresa real.

## Datos

| Tabla | Filas | Contenido |
|---|---|---|
| `sucursales` | 8 | Nombre, ciudad y estado |
| `productos` | 19 | Nombre, categoría y precio |
| `clientes` | 500 | Nombre, ciudad, fecha de alta y segmento |
| `ventas` | 9,154 | Fecha, cliente, sucursal, producto, cantidad y descuento |

El periodo cubre enero de 2024 a diciembre de 2025. La demanda tiene estacionalidad: sube en mayo, noviembre y diciembre.

El ingreso de cada venta se calcula como `cantidad × precio × (1 − descuento)`.

## Estructura

```
ventas_demanda/
├── data/
│   └── ventas.db                  # base SQLite sintética
├── sql/
│   └── analisis_ventas.sql        # vista base y 5 consultas de negocio
├── python/
│   ├── resultados_pronostico.ipynb  # demanda, modelos, métricas, utilidad y conclusiones
│   └── pronostico_demanda.png       # gráfica real frente a pronóstico
└── powerbi/
    ├── *.csv                      # modelo en estrella listo para Power BI
    └── GUIA_POWER_BI.md           # Power Query, relaciones, DAX y páginas del tablero
```

## Cómo ejecutarlo

Requiere Python 3.10 o superior, con `pandas` y `matplotlib`.

```powershell
pip install pandas matplotlib
```

Abre `python/resultados_pronostico.ipynb` en VS Code o Jupyter y ejecútalo de arriba a abajo. Muestra la demanda histórica, la comparación de modelos, las métricas, la utilidad para inventario y las conclusiones.

La implementación del modelo de pronóstico no se publica en este repositorio; aquí se muestran sus resultados.

Para explorar las consultas, abre `data/ventas.db` en cualquier cliente SQLite (DB Browser for SQLite, DBeaver o la extensión de VS Code) y ejecuta `sql/analisis_ventas.sql`. Primero crea la vista `v_ventas_detalle`, porque las demás consultas la usan.

## Resultados

**Ingreso y producto.** La categoría Electrónica genera 6.8 millones de pesos, casi el doble que Hogar. Los 10 productos principales concentran 90.2 % del ingreso, así que conviene vigilar su inventario con más frecuencia que el resto del catálogo.

**Sucursales y CDMX.** Las dos sucursales de la Ciudad de México (Polanco y Santa Fe) generan 25.1 % del ingreso con 2 de 8 sucursales. Malecón (Mazatlán) es la sucursal con más ingreso, con 1.8 millones de pesos.

**Estacionalidad.** La demanda mensual oscila entre 460 y 974 unidades. Los picos de noviembre y diciembre son consistentes en ambos años, lo que justifica planear inventario antes de esos meses.

**Pronóstico.** Se evaluó con los últimos 3 meses de 2025, sin usarlos para entrenar:

| Modelo | Error medio absoluto (unidades) | Error porcentual medio |
|---|---|---|
| Línea base: promedio de los últimos 3 meses | 164.9 | 18.6 % |
| Modelo estacional (mismo mes del año anterior, ajustado por tendencia) | **50.1** | **7.3 %** |

El modelo estacional reduce el error a menos de la mitad frente a la línea base. Esto importa porque la línea base no ve el repunte de fin de año y subestima diciembre en más de 380 unidades.

**Proyección para enero a marzo de 2026:** entre 550 y 625 unidades mensuales en total. Usa esta cifra como punto de partida para la compra, no como un valor exacto.

## Límites

- **Datos sintéticos.** Los patrones son los que se generaron para practicar. En una empresa real habría que validar la estacionalidad con varios años de historia.
- **Prueba corta.** La evaluación usa solo 3 meses. Con más historia, el error debería medirse con varias ventanas de prueba.
- **Modelo simple a propósito.** No incluye promociones, precios ni inventario inicial. Son variables que mejorarían el pronóstico y que se pueden agregar después.
- **Nivel agregado.** El pronóstico es del total mensual. Para planear inventario por sucursal o producto se necesita un modelo por esas dimensiones, con más datos por grupo.

## Siguientes pasos

- Pronosticar por categoría y sucursal, usando la consulta 5 como base.
- Añadir promociones y precios como variables.
- Terminar el tablero en Power BI siguiendo `powerbi/GUIA_POWER_BI.md`.
