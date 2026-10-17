## Com es fa la projecció

Aquesta aplicació converteix una estimació de vot **estatal** en una projecció d'escons al Congrés dels Diputats (350 escons, 52 circumscripcions). És un model mecànic, no una predicció: respon a la pregunta *«si el vot estatal fos aquest i es mantingués el patró territorial de 2023, com quedarien els escons?»*

### 1. Estimació de vot estatal

- Les **enquestes** es llegeixen, en obrir l'aplicació, de la taula d'enquestes estatals que es manté a la [Viquipèdia en anglès](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election). Només s'ofereixen les enquestes amb treball de camp acabat en els últims tres mesos (92 dies). Se n'exclouen dos tipus d'entrada: el panel setmanal d'Electomanía, que és una estimació contínua i no una enquesta, i les reestimacions de dades del CIS publicades per altres empreses. Si la pàgina no es pot llegir, l'aplicació recorre al [Poll of Polls de POLITICO Europe](https://www.politico.eu/europe-poll-of-polls/spain/), que recull menys enquestes.
- L'**estimació de tendència** (l'opció per defecte) respon a la pregunta *on és ara cada partit?* fent servir totes les enquestes del període, i no només les últimes. Per a cada partit s'ajusta una recta en el temps a les seves enquestes, amb dos refinaments. Cada empresa té el seu propi nivell, perquè algunes donen sistemàticament més o menys vot a un partit que d'altres; aquests nivells es restringeixen perquè la seva mitjana sigui zero, de manera que l'estimació és la d'una empresa mitjana i no depèn de quines empreses han publicat més recentment. I les enquestes recents pesen més: una enquesta compta la meitat per cada 30 dies d'antiguitat. L'estimació és el valor de la recta en la data de l'enquesta més recent, de manera que segueix un partit que puja o baixa però no es projecta mai cap al futur. Un partit amb menys de 8 enquestes, o amb una recta que acaba fora del rang observat a les seves enquestes, pren la mitjana descrita a continuació. La pestanya **Enquestes** dibuixa aquestes rectes sobre les enquestes individuals.
- La **mitjana** és la mitjana simple de l'**última enquesta de cada empresa** en aquest període, perquè les empreses que publiquen sovint no pesin més. Per a cada partit es calcula amb les enquestes que el publiquen. No té en compte les tendències, i una enquesta de fa tres mesos hi compta tant com una de la setmana passada.
- Quan una **enquesta concreta** no publica un partit (moltes ometen els partits d'àmbit no estatal), s'hi posa el valor de la mitjana dels tres mesos. La barra lateral indica quins valors s'han omplert així.
- **El meu escenari** substitueix l'enquesta pels percentatges que escriguis.
- Les candidatures que cap empresa publica (Nueva Canarias, UPL, Teruel Existe, Soria ¡Ya! i d'altres) mantenen el seu **percentatge estatal de 2023**. El que queda va a un grup residual d'«altres + vot en blanc», que no obté mai escons.
- **La CUP i Aliança Catalana** no es presenten a aquestes eleccions i no es modelen. Els vots de la CUP de 2023 formen part del grup residual.
- **Front Ampli** (Frente Amplio) és el nom amb què Sumar es presenta el 2026. Les enquestes que encara el recullen com a Sumar es llegeixen com a Front Ampli, i la seva referència de 2023 i el seu perfil territorial són els de Sumar.
- **Compromís** és el nom de la candidatura del Front Ampli a Alacant, Castelló i València. Les enquestes es recullen amb tots dos junts, de manera que la xifra conjunta es reparteix en proporció als seus vots de 2023, i els escons obtinguts en aquestes tres províncies es mostren com a Compromís.
- Una enquesta que no publica la mida de la mostra es tracta com si tingués **1.000 entrevistes**.

### 2. Del vot estatal a les províncies: swing proporcional

El punt de partida és el resultat de les eleccions generals de **juliol de 2023** a cada província (fitxers del Ministeri de l'Interior que hi ha en aquesta carpeta). Els vots provincials de 2023 de cada partit es multipliquen pel mateix factor a tot arreu —la raó entre el seu nou percentatge estatal i el de 2023—, de manera que un partit que es duplica al conjunt de l'Estat es duplica a totes les províncies on es va presentar i continua a zero on no ho va fer.

Aquest escalat, tot sol, deixa províncies que no sumen 100% i totals estatals que s'allunyen de l'enquesta. Per això la taula s'**ajusta iterativament** (*raking* o ajust proporcional iteratiu) fins que es compleixen dues condicions alhora: cada província conserva el seu pes de 2023 en el vot vàlid total, i el total estatal de cada partit coincideix amb l'objectiu. Se suposa, doncs, que les diferències de participació entre províncies es mantenen com el 2023.

Tres partits no fan servir el seu propi resultat de 2023 com a perfil territorial:

- **Podemos** es va presentar dins de Sumar el 2023, i per tant es distribueix com Sumar 2023.
- **SALF** no existia el 2023 i es distribueix com Vox 2023. És una aproximació poc fina; amb prop d'un 2% estatal gairebé no afecta els escons.
- **Adelante Andalucía** només es presenta a les vuit províncies andaluses. El seu percentatge estatal s'hi reparteix en proporció al seu resultat a les últimes eleccions andaluses (fitxer `data/aa_prior.csv`), i no rep vots enlloc més.

**Podemos a Catalunya.** Podemos no es presenta a Barcelona, Girona, Lleida ni Tarragona. El model primer el projecta allà com a qualsevol altre lloc, i després passa aquests vots a ERC i al Front Ampli en la proporció que fixa el control lliscant (la meitat a cadascun per defecte; amb 0 tot va al Front Ampli, amb 100 tot a ERC). Com que la xifra de Podemos a les enquestes es reparteix per tot l'Estat abans d'aquest pas, el seu percentatge estatal queda una mica per sota de l'enquesta, i els d'ERC i el Front Ampli una mica per sobre. Si les empreses ja compten aquests votants en altres partits, aquest pas els mou dues vegades. El control també s'aplica en l'escenari d'unitat de l'esquerra: la part que no va a ERC acaba a la llista conjunta.

### 3. Escons: D'Hondt a cada província

Els escons s'assignen amb la regla **D'Hondt** per separat a cada circumscripció, entre les candidatures amb almenys el **3% del vot vàlid** (vots en blanc inclosos) en aquella circumscripció. El nombre d'escons per província és el de 2023 amb els dos canvis de 2026: **Madrid 38 (+1)** i **Cadis 8 (−1)**. Aplicat al vot real de 2023 i al repartiment d'escons de 2023, el codi reprodueix exactament l'assignació oficial.

### 4. Incertesa: Monte Carlo

La projecció central és l'única execució sense soroll. Al seu voltant, l'aplicació simula les eleccions moltes vegades (1.000 per defecte) amb dues fonts d'error:

- **Error estatal.** El percentatge estatal de cada partit es torna a sortejar (en escala logit, i després es renormalitza a 100%). La variància té una part mostral, *p(1−p)/n*, on *n* és la mostra de l'enquesta (o la suma de mostres en el cas de la mitjana; cap en el teu propi escenari), i una part no mostral que reflecteix quant s'han equivocat les enquestes espanyoles més enllà de l'error mostral. El control lliscant fixa aquesta última com a desviació típica, en punts, per a un partit al 30% (2 punts per defecte); per a altres mides s'escala amb *√p(1−p)*. Per als partits molt petits, l'error relatiu es limita al 30%.
- **Error provincial.** Els partits no es mouen mai exactament en proporció a tot arreu. Cada cel·la província × partit de la taula de 2023 es multiplica per un soroll lognormal abans de l'ajust. La desviació típica per defecte, **12%**, s'ha estimat amb les dades d'aquesta carpeta: predir novembre de 2019 a partir d'abril de 2019, i juliol de 2023 a partir de novembre de 2019, amb aquest mateix mètode i el resultat estatal real, deixa errors provincials amb una desviació típica de 0,11–0,12 en escala logarítmica (al voltant de 0,10 per als partits per sobre del 20% i de 0,14 per als de menys del 10%).

Cada elecció simulada passa per D'Hondt. L'**interval del 90%** va del percentil 5 al 95 dels escons simulats, i les probabilitats (un escó en una província, una majoria per a un grup de partits) són la proporció de simulacions en què es dona el fet. La projecció central i la mitjana de les simulacions poden diferir en un o dos escons.

### Escenari d'unitat de l'esquerra

L'interruptor **Unitat de l'esquerra** mostra què passaria si el Front Ampli, Podemos i Compromís es presentessin en una sola llista, que es mostra com a «Front Ampli amb Podemos» («Compromís-FA-Podemos» a Alacant, Castelló i València). Cadascun es projecta per separat, exactament com s'ha descrit, i després els seus vots se sumen a cada província abans d'aplicar D'Hondt. Això suposa que la llista conjunta conserva tots els vots dels seus membres: ni atrau votants nous ni en perd pel fet d'anar junts. L'única excepció és Catalunya, on la part dels vots de Podemos que fixa el control continua anant a ERC. La diferència d'escons prové només de desaprofitar menys vots a les províncies petites i mitjanes. La columna 2023 de la llista conjunta és el resultat de Sumar d'aquell any, quan tots tres es van presentar junts.

### El que el model no sap

- Suposa les **mateixes candidatures** que el 2023, tret dels canvis descrits més amunt (la separació Sumar / Podemos, SALF, Adelante Andalucía i l'absència de la CUP). No es modelen altres coalicions ni escissions.
- Els errors se sortegen de manera **independent** entre partits i províncies. Els errors reals estan correlacionats (un partit que supera les enquestes ho sol fer en regions senceres), de manera que els intervals dels blocs probablement són una mica massa estrets.
- Les enquestes estatals mesuren malament els **partits d'àmbit no estatal**: una diferència de 0,2 punts per a ERC, Junts, EH Bildu o el PNB mou diversos escons.
- El patró provincial dels **partits nous o que creixen de pressa** és la baula més feble: el swing proporcional dona a Vox els guanys més grans allà on ja era fort.
- L'**estimació de tendència** suposa que cada partit es mou en línia recta durant els tres mesos i que les empreses, de mitjana, l'encerten. Un canvi sobtat en els últims dies només es recull parcialment, i un biaix compartit per totes les empreses no es corregeix. La mitjana d'enquestes no es pondera per mida de mostra ni per data.

Fonts: enquestes, [Viquipèdia](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election), amb el [Poll of Polls de POLITICO Europe](https://www.politico.eu/europe-poll-of-polls/spain/) com a alternativa; resultats, Ministeri de l'Interior; mapa, `mapSpain` (les Canàries, desplaçades al costat de la península).

Autor: Jordi Muñoz, Universitat de Barcelona ([www.jordimunoz.cat](https://www.jordimunoz.cat)).
