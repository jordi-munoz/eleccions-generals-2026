## How the projection is made

This app turns a **national** vote estimate into a seat projection for the Congress of Deputies (350 seats, 52 constituencies). It is a mechanical model, not a forecast: it answers *"if the national vote were this, and the territorial pattern of 2023 held, what would the seats look like?"*

### 1. National vote estimate

- **Polls** are read when the app starts from the table of national polls kept on [Wikipedia](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election). Only polls whose fieldwork ended in the last three months (92 days) are offered. Two kinds of entry in that table are left out: Electomanía's weekly panel, which is a running estimate and not a poll, and re-estimates of CIS data published by other firms. If the page cannot be read, the app falls back on [POLITICO Europe's Poll of Polls](https://www.politico.eu/europe-poll-of-polls/spain/), which lists fewer polls.
- **Trend estimate** (the default) answers *where does each party stand now?* using all the polls of the period, not only the latest ones. For each party a straight line over time is fitted to its polls, with two refinements. Each pollster gets its own level, because some firms are consistently higher or lower for a party than others; these levels are constrained to average zero, so the estimate is that of an average pollster and does not depend on which firms happened to publish last. And recent polls weigh more: a poll counts half as much for every 30 days of age. The estimate is the value of the line on the date of the most recent poll, so it follows a party that is rising or falling but is never projected into the future. A party with fewer than 8 polls, or whose line ends outside the range seen in its polls, takes the average described next. The **Polls** tab plots these lines over the individual polls.
- **Average** is the simple mean of the **latest poll of each pollster** in that period, so that firms publishing often do not weigh more. Each party is averaged over the polls that publish it. It ignores trends, and a poll from three months ago counts as much as one from last week.
- When a **single poll** does not publish a party (many omit the regional parties), the value of the three-month average is used for that party. The sidebar says which values were filled in.
- **Your own scenario** replaces the poll with the percentages you type.
- Lists that no pollster reports (Nueva Canarias, UPL, Teruel Existe, Soria ¡Ya!, and others) keep their **2023 national share**. Whatever is left goes to a residual "others + blank votes" group, which never wins seats.
- **CUP and Aliança Catalana** do not run in this election and are not modelled. CUP's 2023 votes are part of the residual group.
- **Frente Amplio** is the name under which Sumar runs in 2026. Polls that still report it as Sumar are read as Frente Amplio, and its 2023 reference and territorial profile are those of Sumar.
- **Compromís** ran as the Sumar list in Alicante, Castellón and Valencia in 2023. Polls are recorded with Frente Amplio and Compromís together, so the joint figure is split in proportion to their 2023 votes. In 2026 the list in those three provinces is **Compromís-Front Valencià** (see below).
- A poll that does not publish its sample size is treated as having **1,000 interviews**.

### 2. From national vote to provinces: proportional swing

The baseline is the result of the **July 2023** general election in each province (Ministry of the Interior files in this folder). Each party's 2023 provincial votes are scaled by the same factor everywhere — the ratio between its new national share and its 2023 national share — so a party that doubles nationally doubles in every province where it ran, and stays at zero where it did not.

Scaling alone leaves provinces that do not add up to 100% and national totals that drift from the poll. The table is therefore **raked** (iterative proportional fitting) until two conditions hold at once: every province keeps its 2023 weight in the national valid vote, and every party's national total equals the target. Turnout differences between provinces are thus assumed to stay as in 2023.

Three parties do not use their own 2023 result as territorial profile:

- **Podemos** ran inside Sumar in 2023, so it is distributed like Sumar 2023.
- **SALF** did not exist in 2023 and is distributed like Vox 2023. This is a rough proxy; at around 2% nationally it barely affects seats.
- **Adelante Andalucía** runs only in the eight Andalusian provinces. Its national share is distributed among them in proportion to its result in the last Andalusian regional election (file `data/aa_prior.csv`), and it gets no votes elsewhere.

**Where Podemos does not run on its own.** Podemos and Frente Amplio run as separate lists in most of Spain, with three exceptions. The model first projects Podemos in every province like any other party, and then hands its votes over where it has no list of its own:

- **Catalonia** (Barcelona, Girona, Lleida, Tarragona): Podemos does not run. Its votes are split **50-50 between ERC and Frente Amplio**. This split is fixed.
- **Alicante, Castellón and Valencia**: Compromís, Frente Amplio and Podemos run together as **Compromís-Front Valencià**. Its 2023 reference is the Sumar list of those provinces (Compromís), and Podemos's votes are added to it.
- **Las Palmas and Santa Cruz de Tenerife**: Frente Amplio and Podemos run together as **Unidad del Pueblo Canario**, and Podemos's votes are added to the Frente Amplio projection. In the national table this list is counted under Frente Amplio.

The joint lists keep all the votes of their members: they neither attract new voters nor lose any by running together. Because the poll figure for Podemos is spread over the whole country before these steps, its national share ends up well below the poll, and those of Frente Amplio, Compromís-Front Valencià and ERC above. If pollsters already count Podemos's Catalan voters under other parties, the Catalan step moves them twice.

### 3. Seats: D'Hondt in each province

Seats are allocated with the **D'Hondt** rule separately in each constituency, among lists with at least **3% of the valid vote** (blank votes included) in that constituency. The number of seats per province is that of 2023 with the two changes for 2026: **Madrid 38 (+1)** and **Cádiz 8 (−1)**. Applied to the actual 2023 vote and the 2023 seat distribution, the code reproduces the official allocation exactly.

### 4. Uncertainty: Monte Carlo

The central projection is the single run without noise. Around it, the app simulates the election many times (1,000 by default) with two sources of error:

- **National error.** Each party's national share is redrawn (on the logit scale, then renormalised to 100%). Its variance has a sampling part, *p(1−p)/n* with *n* the sample of the poll (or the sum of samples for the average; none for your own scenario), and a non-sampling part that reflects how much Spanish polls have missed beyond sampling error. The slider sets the latter as the standard deviation, in points, for a party at 30% (default 2 points); it scales with *√p(1−p)* for other sizes. For very small parties the relative error is capped at 30%.
- **Provincial error.** Parties never move exactly in proportion everywhere. Each province × party cell of the 2023 table is multiplied by lognormal noise before raking. The default standard deviation, **12%**, was estimated from the data in this folder: predicting November 2019 from April 2019, and July 2023 from November 2019, with this same method and the true national result, leaves provincial errors with a standard deviation of 0.11–0.12 on the log scale (about 0.10 for parties above 20%, 0.14 for those below 10%).

Each simulated election goes through D'Hondt. The **90% interval** is the 5th–95th percentile of simulated seats, and probabilities (a seat in a province, a majority for a group of parties) are the share of simulations in which the event happens. The central projection and the simulation mean can differ by a seat or two.

### What the model does not know

- It assumes the **same lists** as in 2023, apart from the changes described above (the Frente Amplio / Podemos split and its exceptions, SALF, Adelante Andalucía, and CUP not running). Other coalitions or splits are not modelled.
- Errors are drawn **independently** across parties and provinces. Real errors are correlated (a party beating its polls tends to do so in whole regions), so the intervals for regional blocs are probably somewhat too narrow.
- **Regional parties** are poorly measured by national polls: a difference of 0.2 points for ERC, Junts, EH Bildu or the PNV moves several seats.
- The provincial pattern of **new or fast-growing parties** is the weakest link: proportional swing gives Vox its largest gains where it was already strong.
- The **trend estimate** assumes each party moves in a straight line over the three months and that pollsters are right on average. A sudden change in the last few days is only partly picked up, and a bias shared by all pollsters is not corrected. The poll average is not weighted by sample size or date.

### Data files

Data files for this app can be found in [JSON](export/projection.json) and [CSV](export/projection.csv).

Sources: polls, [Wikipedia](https://en.wikipedia.org/wiki/Opinion_polling_for_the_2026_Spanish_general_election), with [POLITICO Europe Poll of Polls](https://www.politico.eu/europe-poll-of-polls/spain/) as fallback; results, Ministerio del Interior; map, `mapSpain` (Canary Islands moved next to the peninsula).

Author: Jordi Muñoz, Universitat de Barcelona ([www.jordimunoz.cat](https://www.jordimunoz.cat)).
