# CLAUDE.md

Este archivo entrega contexto a Claude Code (claude.ai/code) para trabajar en este repositorio.

## Comandos

```sh
uv sync                                    # instala dependencias (Python >=3.12, gestionado con uv)
uv run python -m carrito total --pedido 42 # corre el CLI para el pedido #42
uv run pytest                              # corre toda la suite de tests
uv run pytest tests/test_descuentos.py::test_cupon_porcentual_se_aplica_antes_que_el_de_monto_fijo -v  # un solo test
```

CI (`.github/workflows/tests.yml`) corre `uv sync --all-groups` y luego `uv run pytest` en cada push/PR.

Flags del CLI: `--sin <promo>` (repetible) descarta una promoción antes de calcular el total; `--detalle` imprime producto/cantidad/precio de cada línea antes del resumen.

## Convenciones

- **Nombres a futuro**: el código actual mezcla nombres de funciones en inglés y en español (p. ej. `precio_linea`, `costo_envio` vs. `free_shipping_for_new_customer`, `volume_discount`). De ahora en adelante, escribe el código nuevo —nombres de funciones, variables, módulos— en inglés. No renombres de paso los nombres en español existentes salvo que se pida explícitamente; aplica esta regla al código nuevo y al código que ya estés tocando por otra razón.
- **Conflictos entre documentación y código**: cuando la documentación (README, docstrings) y el comportamiento real del código no coincidan, trata la documentación como la fuente correcta y avísame de la discrepancia — no "arregles" el código en silencio ni actualices la documentación para que calce con el código sin decir nada.

## Arquitectura

Pipeline pequeño que calcula el total de un pedido a partir de `datos/ejemplo.json`, repartido en módulos de responsabilidad única bajo `src/carrito/`. Cada etapa toma el monto de la etapa anterior y devuelve un nuevo monto entero (todo el dinero son pesos chilenos enteros, sin fracciones — ver `dinero.py`):

1. `datos.py` carga `datos/ejemplo.json` y arma los dataclasses de `modelo.py` (`Producto`, `Linea`, `Cupon`, `Pedido`). `pedido(numero)` lanza `KeyError` si el pedido no existe.
2. `precios.py` — `subtotal()` suma `precio_linea()` de todas las líneas del `Pedido`.
3. `descuentos.py` — `total_con_descuentos()` aplica los descuentos en dos pasadas:
   - Primero, `PROMOCIONES` (la lista `pedido.promociones` — `2x1`, `volumen`, `primera-compra`). Cada función de promoción se llama de forma independiente sobre el *mismo* subtotal previo a descuentos y los resultados se suman (no se van encadenando entre sí).
   - Luego, `pedido.cupones`: los cupones porcentuales se aplican antes que los de monto fijo, en ese orden — este orden es deliberado y está documentado en el docstring del módulo y en `README.md`; un test (`tests/test_descuentos.py`) lo fija. No cambies el orden sin actualizar ambos.
   - El resultado nunca baja de 0.
4. `impuestos.py` — 19% de IVA sobre el monto ya descontado. Ojo: `iva()` trunca (`int(monto * IVA / 100)`) en vez de usar `dinero.redondear`/`dinero.porcentaje` como el resto del código — fue un ajuste deliberado (ver historial de git: "Ajuste rápido del redondeo del IVA") para calzar con boletas reales, no un descuido a "limpiar".
5. `envio.py` — costo de envío por región (`TRAMOS`), gratis sobre `UMBRAL_ENVIO_GRATIS` ($50.000), y *además* gratis sin condición para `pedido.cliente_nuevo` sin importar el monto (`free_shipping_for_new_customer`).
6. `resumen.py` — orquesta los pasos 2-5 en un `dict[str, int]` ordenado (Subtotal → Descuentos (solo si no es cero) → IVA → Envío → Total). Esto es lo que imprime `cli.py`.

`exportar.py` (`a_csv()`) existe pero deliberadamente *no* está conectado al CLI — se espera que la generación de CSV/reportes ocurra en un sistema de reportes externo, no en este repo (ver el commit de git "El CSV se genera desde el sistema de reportes, no desde el CLI"). No vuelvas a agregar un flag `--csv` a `cli.py` sin consultarlo antes con el usuario.
