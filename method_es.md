## Cómo se hace la proyección

Esta aplicación convierte una estimación de voto **nacional** en una proyección de escaños en el Congreso de los Diputados (350 escaños, 52 circunscripciones). Es un modelo mecánico, no una predicción: responde a la pregunta *«si el voto nacional fuera este y se mantuviera el patrón territorial de 2023, ¿cómo quedarían los escaños?»*

### 1. Estimación de voto nacional

- Las **encuestas** se leen, al abrir la aplicación, de la tabla de encuestas nacionales que se mantiene en la [Wikipedia en inglés](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election). Solo se ofrecen las encuestas con trabajo de campo terminado en los últimos tres meses (92 días). Se excluyen dos tipos de entrada: el panel semanal de Electomanía, que es una estimación continua y no una encuesta, y las reestimaciones de datos del CIS publicadas por otras empresas. Si la página no se puede leer, la aplicación recurre al [Poll of Polls de POLITICO Europe](https://www.politico.eu/europe-poll-of-polls/spain/), que recoge menos encuestas.
- La **estimación de tendencia** (la opción por defecto) responde a la pregunta *¿dónde está ahora cada partido?* usando todas las encuestas del periodo, y no solo las últimas. Para cada partido se ajusta una recta en el tiempo a sus encuestas, con dos refinamientos. Cada empresa tiene su propio nivel, porque algunas dan sistemáticamente más o menos voto a un partido que otras; esos niveles se restringen para que su media sea cero, de modo que la estimación es la de una empresa media y no depende de qué empresas han publicado más recientemente. Y las encuestas recientes pesan más: una encuesta cuenta la mitad por cada 30 días de antigüedad. La estimación es el valor de la recta en la fecha de la encuesta más reciente, de modo que sigue a un partido que sube o baja pero nunca se proyecta hacia el futuro. Un partido con menos de 8 encuestas, o con una recta que termina fuera del rango observado en sus encuestas, toma la media descrita a continuación. La pestaña **Encuestas** dibuja estas rectas sobre las encuestas individuales.
- La **media** es la media simple de la **última encuesta de cada empresa** en ese periodo, para que las empresas que publican a menudo no pesen más. Para cada partido se calcula con las encuestas que lo publican. No tiene en cuenta las tendencias, y una encuesta de hace tres meses cuenta tanto como una de la semana pasada.
- Cuando una **encuesta concreta** no publica un partido (muchas omiten los partidos de ámbito no estatal), se usa el valor de la media de los tres meses. La barra lateral indica qué valores se han rellenado así.
- **Mi propio escenario** sustituye la encuesta por los porcentajes que escribas.
- Las candidaturas que ninguna empresa publica (Nueva Canarias, UPL, Teruel Existe, Soria ¡Ya! y otras) mantienen su **porcentaje nacional de 2023**. Lo que queda va a un grupo residual de «otros + voto en blanco», que nunca obtiene escaños.
- **La CUP y Aliança Catalana** no se presentan a estas elecciones y no se modelan. Los votos de la CUP de 2023 forman parte del grupo residual.
- **Frente Amplio** es el nombre con el que Sumar se presenta en 2026. Las encuestas que todavía lo recogen como Sumar se leen como Frente Amplio. La Wikipedia recoge las encuestas de antes y de después del acuerdo del Frente Amplio en dos tablas, que se unen; en la segunda, el Front Valencià (FV) se suma al Frente Amplio, igual que antes Compromís se incluía en Sumar. Su referencia de 2023 y su perfil territorial son los de Sumar.
- **Compromís** fue la candidatura de Sumar en Alicante, Castellón y Valencia en 2023. Las encuestas recogen al Frente Amplio y Compromís juntos, de modo que la cifra conjunta se reparte en proporción a sus votos de 2023. En 2026 la candidatura de esas tres provincias es **Compromís-Front Valencià** (véase más abajo).
- Una encuesta que no publica el tamaño de la muestra se trata como si tuviera **1.000 entrevistas**.

### 2. Del voto nacional a las provincias: swing proporcional

El punto de partida es el resultado de las elecciones generales de **julio de 2023** en cada provincia (ficheros del Ministerio del Interior que hay en esta carpeta). Los votos provinciales de 2023 de cada partido se multiplican por el mismo factor en todas partes —la razón entre su nuevo porcentaje nacional y el de 2023—, de modo que un partido que se duplica en el conjunto de España se duplica en todas las provincias donde se presentó y sigue en cero donde no lo hizo.

Ese escalado, por sí solo, deja provincias que no suman 100% y totales nacionales que se alejan de la encuesta. Por eso la tabla se **ajusta iterativamente** (*raking* o ajuste proporcional iterativo) hasta que se cumplen dos condiciones a la vez: cada provincia conserva su peso de 2023 en el voto válido total, y el total nacional de cada partido coincide con el objetivo. Se supone, por tanto, que las diferencias de participación entre provincias se mantienen como en 2023.

Tres partidos no usan su propio resultado de 2023 como perfil territorial:

- **Podemos** se presentó dentro de Sumar en 2023, así que se distribuye como Sumar 2023.
- **SALF** no existía en 2023 y se distribuye como Vox 2023. Es una aproximación poco fina; con cerca de un 2% nacional apenas afecta a los escaños.
- **Adelante Andalucía** solo se presenta en las ocho provincias andaluzas. Su porcentaje nacional se reparte entre ellas en proporción a su resultado en las últimas elecciones andaluzas (fichero `data/aa_prior.csv`), y no recibe votos en ningún otro lugar.

**Donde Podemos no se presenta solo.** Podemos y el Frente Amplio se presentan por separado en la mayor parte de España, con tres excepciones. El modelo primero proyecta Podemos en todas las provincias como cualquier otro partido, y después pasa sus votos allí donde no tiene candidatura propia:

- **Cataluña** (Barcelona, Girona, Lleida, Tarragona): Podemos no se presenta. Sus votos se reparten **a partes iguales entre ERC y el Frente Amplio**. Este reparto es fijo.
- **Alicante, Castellón y Valencia**: Compromís, el Frente Amplio y Podemos se presentan juntos como **Compromís-Front Valencià**. Su referencia de 2023 es la candidatura de Sumar en esas provincias (Compromís), y se le suman los votos de Podemos.
- **Las Palmas y Santa Cruz de Tenerife**: el Frente Amplio y Podemos se presentan juntos como **Unidad del Pueblo Canario**, y los votos de Podemos se suman a la proyección del Frente Amplio. En la tabla nacional, esta candidatura se cuenta dentro del Frente Amplio.

Las candidaturas conjuntas conservan todos los votos de sus miembros: ni atraen votantes nuevos ni pierden ninguno por ir juntos. Como la cifra de Podemos en las encuestas se reparte por toda España antes de estos pasos, su porcentaje nacional queda bastante por debajo de la encuesta, y los del Frente Amplio, Compromís-Front Valencià y ERC por encima. Si las empresas ya cuentan a los votantes catalanes de Podemos en otros partidos, el paso de Cataluña los mueve dos veces.

### 3. Escaños: D'Hondt en cada provincia

Los escaños se asignan con la regla **D'Hondt** por separado en cada circunscripción, entre las candidaturas con al menos el **3% del voto válido** (votos en blanco incluidos) en esa circunscripción. El número de escaños por provincia es el de 2023 con los dos cambios de 2026: **Madrid 38 (+1)** y **Cádiz 8 (−1)**. Aplicado al voto real de 2023 y al reparto de escaños de 2023, el código reproduce exactamente la asignación oficial.

### 4. Incertidumbre: Monte Carlo

La proyección central es la única ejecución sin ruido. A su alrededor, la aplicación simula las elecciones muchas veces (1.000 por defecto) con dos fuentes de error:

- **Error nacional.** El porcentaje nacional de cada partido se vuelve a sortear (en escala logit, y después se renormaliza a 100%). La varianza tiene una parte muestral, *p(1−p)/n*, donde *n* es la muestra de la encuesta (o la suma de muestras en el caso de la media; ninguna en tu propio escenario), y una parte no muestral que refleja cuánto se han equivocado las encuestas españolas más allá del error muestral. El control deslizante fija esta última como desviación típica, en puntos, para un partido al 30% (2 puntos por defecto); para otros tamaños se escala con *√p(1−p)*. Para los partidos muy pequeños, el error relativo se limita al 30%.
- **Error provincial.** Los partidos nunca se mueven exactamente en proporción en todas partes. Cada celda provincia × partido de la tabla de 2023 se multiplica por un ruido lognormal antes del ajuste. La desviación típica por defecto, **12%**, se ha estimado con los datos de esta carpeta: predecir noviembre de 2019 a partir de abril de 2019, y julio de 2023 a partir de noviembre de 2019, con este mismo método y el resultado nacional real, deja errores provinciales con una desviación típica de 0,11–0,12 en escala logarítmica (en torno a 0,10 para los partidos por encima del 20% y a 0,14 para los de menos del 10%).

Cada elección simulada pasa por D'Hondt. El **intervalo del 90%** va del percentil 5 al 95 de los escaños simulados, y las probabilidades (un escaño en una provincia, una mayoría para un grupo de partidos) son la proporción de simulaciones en las que ocurre el hecho. La proyección central y la media de las simulaciones pueden diferir en uno o dos escaños.

### Lo que el modelo no sabe

- Supone las **mismas candidaturas** que en 2023, salvo los cambios descritos más arriba (la separación Frente Amplio / Podemos y sus excepciones, SALF, Adelante Andalucía y la ausencia de la CUP). No se modelan otras coaliciones ni escisiones.
- Los errores se sortean de forma **independiente** entre partidos y provincias. Los errores reales están correlacionados (un partido que supera a las encuestas suele hacerlo en regiones enteras), de modo que los intervalos de los bloques probablemente son algo demasiado estrechos.
- Las encuestas nacionales miden mal a los **partidos de ámbito no estatal**: una diferencia de 0,2 puntos para ERC, Junts, EH Bildu o el PNV mueve varios escaños.
- El patrón provincial de los **partidos nuevos o que crecen deprisa** es el eslabón más débil: el swing proporcional da a Vox las mayores ganancias allí donde ya era fuerte.
- La **estimación de tendencia** supone que cada partido se mueve en línea recta durante los tres meses y que las empresas, de media, aciertan. Un cambio brusco en los últimos días solo se recoge en parte, y un sesgo compartido por todas las empresas no se corrige. La media de encuestas no se pondera por tamaño de muestra ni por fecha.

### Ficheros de datos

Los ficheros de datos de esta aplicación se pueden encontrar en [JSON](https://jordi-munoz.github.io/eleccions-generals-2026/projection.json) y [CSV](https://jordi-munoz.github.io/eleccions-generals-2026/projection.csv).

Fuentes: encuestas, [Wikipedia](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election), con el [Poll of Polls de POLITICO Europe](https://www.politico.eu/europe-poll-of-polls/spain/) como alternativa; resultados, Ministerio del Interior; mapa, `mapSpain` (Canarias, desplazadas junto a la península).

Autor: Jordi Muñoz, Universitat de Barcelona ([www.jordimunoz.cat](https://www.jordimunoz.cat)).
