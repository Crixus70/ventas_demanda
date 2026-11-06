-- Ingreso neto por línea de venta: cantidad * precio, menos descuento.
-- Vista base reutilizable en las consultas siguientes.
CREATE VIEW IF NOT EXISTS v_ventas_detalle AS
SELECT
    v.id,
    v.fecha,
    strftime('%Y-%m', v.fecha)                         AS mes,
    v.sucursal_id,
    s.nombre                                            AS sucursal,
    s.estado,
    v.producto_id,
    p.nombre                                            AS producto,
    p.categoria,
    v.cantidad,
    v.cliente_id,
    ROUND(v.cantidad * p.precio * (1 - v.descuento), 2) AS ingreso
FROM ventas v
JOIN sucursales s ON s.id = v.sucursal_id
JOIN productos  p ON p.id = v.producto_id;

-- 1. Ingreso y unidades por sucursal y año, con variación contra el año anterior.
WITH anual AS (
    SELECT
        sucursal,
        strftime('%Y', fecha) AS anio,
        SUM(ingreso)          AS ingreso,
        SUM(cantidad)         AS unidades
    FROM v_ventas_detalle
    GROUP BY sucursal, anio
)
SELECT
    sucursal,
    anio,
    ROUND(ingreso, 0) AS ingreso,
    unidades,
    ROUND(100.0 * (ingreso - LAG(ingreso) OVER (PARTITION BY sucursal ORDER BY anio))
          / LAG(ingreso) OVER (PARTITION BY sucursal ORDER BY anio), 1) AS var_pct_vs_anio_ant
FROM anual
ORDER BY ingreso DESC;

-- 2. Top 10 productos por ingreso, con su participación en el total.
SELECT
    producto,
    categoria,
    SUM(cantidad)                                       AS unidades,
    ROUND(SUM(ingreso), 0)                              AS ingreso,
    ROUND(100.0 * SUM(ingreso) / (SELECT SUM(ingreso) FROM v_ventas_detalle), 2) AS pct_ingreso
FROM v_ventas_detalle
GROUP BY producto, categoria
ORDER BY ingreso DESC
LIMIT 10;

-- 3. Categorías dentro de cada sucursal: qué sucursal vende más de cada categoría.
SELECT
    categoria,
    sucursal,
    ROUND(SUM(ingreso), 0) AS ingreso,
    RANK() OVER (PARTITION BY categoria ORDER BY SUM(ingreso) DESC) AS lugar_en_categoria
FROM v_ventas_detalle
GROUP BY categoria, sucursal
ORDER BY categoria, lugar_en_categoria;

-- 4. Demanda mensual total en unidades (serie para el pronóstico en Python).
SELECT
    mes,
    SUM(cantidad)        AS unidades,
    ROUND(SUM(ingreso), 0) AS ingreso
FROM v_ventas_detalle
GROUP BY mes
ORDER BY mes;

-- 5. Demanda mensual por categoría (para decidir inventario por línea).
SELECT
    mes,
    categoria,
    SUM(cantidad) AS unidades
FROM v_ventas_detalle
GROUP BY mes, categoria
ORDER BY categoria, mes;
