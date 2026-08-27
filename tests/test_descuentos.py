"""Verifica el orden de aplicación de los descuentos del pedido.

Tanto el README como el docstring de `carrito.descuentos` documentan la misma
política: primero se aplican los cupones porcentuales, y sobre el monto que
queda, los vales de monto fijo.
"""

from carrito.descuentos import total_con_descuentos
from carrito.modelo import Cupon, Linea, Pedido, Producto


def test_cupon_porcentual_se_aplica_antes_que_el_de_monto_fijo():
    producto = Producto(sku="P1", nombre="Producto de prueba", precio=100_000)
    pedido = Pedido(
        numero=1,
        lineas=[Linea(producto, cantidad=1)],
        cupones=[
            Cupon(codigo="DESC10", tipo="porcentaje", valor=10),
            Cupon(codigo="VALE5000", tipo="monto", valor=5_000),
        ],
    )

    # Subtotal: 100_000
    # 1) Cupón porcentual (10%):   100_000 - 10_000 = 90_000
    # 2) Cupón de monto fijo ($5_000): 90_000 - 5_000 = 85_000
    assert total_con_descuentos(pedido) == 85_000
