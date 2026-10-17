## Cómo funciona D'Hondt en España

### El punto de partida

- El Congreso tiene **350 escaños**, que se eligen en **52 circunscripciones**: las 50 provincias más Ceuta y Melilla.
- Ceuta y Melilla eligen 1 escaño cada una. Cada provincia empieza con 2 escaños, y los 248 restantes se reparten según la población. En 2026 el resultado va de los 2 escaños de Soria a los 38 de Madrid.
- Se vota una **lista cerrada** de partido: no se pueden elegir ni reordenar los candidatos.
- Los escaños se asignan **por separado en cada provincia**. Los votos nunca se acumulan entre provincias, de modo que un voto que no sirve para obtener escaño en su provincia se pierde.

### La regla, paso a paso

1. En cada provincia se descartan las candidaturas con menos del **3% del voto válido** (los votos en blanco cuentan como válidos).
2. Los votos de cada candidatura restante se dividen entre 1, 2, 3, … hasta el número de escaños de la provincia.
3. Todos esos cocientes se ordenan de mayor a menor.
4. Los escaños son para los cocientes más altos, un escaño por cociente, hasta que se agotan los escaños de la provincia.

### Un ejemplo con 5 escaños

Una provincia elige 5 escaños y se emiten 215.000 votos válidos. El partido E, con 5.000 votos (2,3%), queda por debajo del umbral del 3% y se excluye. Los votos de los demás se dividen entre 1, 2, 3, etc.; los cinco cocientes más altos, en negrita, obtienen los escaños.

| Partido | Votos | ÷ 1 | ÷ 2 | ÷ 3 | ÷ 4 | Escaños |
|---|---|---|---|---|---|---|
| A | 100.000 | **100.000** | **50.000** | **33.333** | 25.000 | 3 |
| B | 60.000 | **60.000** | 30.000 | 20.000 | 15.000 | 1 |
| C | 35.000 | **35.000** | 17.500 | 11.667 | 8.750 | 1 |
| D | 15.000 | 15.000 | 7.500 | 5.000 | 3.750 | 0 |

El partido A se lleva el 60% de los escaños con el 47% de los votos. El partido D no obtiene nada con el 7%. El último escaño ha sido para el tercer cociente de A (33.333); el siguiente en la cola era el segundo de B (30.000), de modo que a B le han faltado 6.667 votos para conseguirlo.

### Qué significa en la práctica

- **El tamaño de la provincia pesa más que la fórmula.** D'Hondt es bastante proporcional cuando hay muchos escaños en juego, pero la mayoría de las provincias españolas son pequeñas: más de la mitad eligen 5 escaños o menos. En una provincia de 3 escaños, una candidatura necesita aproximadamente entre una quinta y una cuarta parte de los votos para obtener representación.
- **El umbral del 3% casi nunca es decisivo.** En casi todas las provincias la barrera real es mucho más alta que el 3%. El umbral legal solo excluye candidaturas en las circunscripciones más grandes, Madrid y Barcelona.
- **Los partidos grandes salen favorecidos.** En 2023 el PP obtuvo el 39% de los escaños con el 33% de los votos.
- **Los partidos medianos con el voto repartido por todo el territorio salen perdiendo.** En 2023 Sumar obtuvo el 9% de los escaños con el 12% de los votos, porque en muchas provincias pequeñas sus votos no dieron ningún escaño.
- **Los partidos concentrados en pocas provincias no salen perjudicados.** En 2023 el PNV obtuvo el 1,4% de los escaños con el 1,1% de los votos, todos en tres provincias.
- **Pequeños cambios pueden mover escaños.** El último escaño de una provincia se decide a menudo por unos cientos o unos miles de votos; por eso la proyección de esta aplicación muestra probabilidades y no una única cifra.
