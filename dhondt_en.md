## How D'Hondt works in Spain

### The basics

- The Congress has **350 seats**, elected in **52 constituencies**: the 50 provinces plus Ceuta and Melilla.
- Ceuta and Melilla elect 1 seat each. Every province starts with 2 seats, and the remaining 248 are shared out by population. In 2026 the result ranges from 2 seats in Soria to 38 in Madrid.
- You vote for a **closed party list**: you cannot pick or reorder candidates.
- Seats are allocated **separately in each province**. Votes are never pooled across provinces, so a vote that does not help win a seat in its province is lost.

### The rule, step by step

1. In each province, lists with less than **3% of the valid vote** (blank votes count as valid) are set aside.
2. The votes of every remaining list are divided by 1, 2, 3, … up to the number of seats in the province.
3. All those quotients are ranked from highest to lowest.
4. The seats go to the highest quotients, one seat per quotient, until the province's seats run out.

### An example with 5 seats

A province elects 5 seats and 215,000 valid votes are cast. Party E, with 5,000 votes (2.3%), is below the 3% threshold and drops out. The votes of the others are divided by 1, 2, 3 and so on; the five highest quotients, in bold, win the seats.

| Party | Votes | ÷ 1 | ÷ 2 | ÷ 3 | ÷ 4 | Seats |
|---|---|---|---|---|---|---|
| A | 100,000 | **100,000** | **50,000** | **33,333** | 25,000 | 3 |
| B | 60,000 | **60,000** | 30,000 | 20,000 | 15,000 | 1 |
| C | 35,000 | **35,000** | 17,500 | 11,667 | 8,750 | 1 |
| D | 15,000 | 15,000 | 7,500 | 5,000 | 3,750 | 0 |

Party A takes 60% of the seats with 47% of the vote. Party D gets nothing with 7%. The last seat went to A's third quotient (33,333); the next in line was B's second (30,000), so B was 6,667 votes short of taking it.

### What this means in practice

- **Province size matters more than the formula.** D'Hondt is close to proportional when many seats are at stake, but most Spanish provinces are small: more than half elect 5 seats or fewer. In a 3-seat province a list needs roughly a fifth to a quarter of the vote to win anything.
- **The 3% threshold rarely matters.** In almost every province the real barrier is much higher than 3%. The legal threshold only excludes lists in the largest constituencies, Madrid and Barcelona.
- **Large parties get a bonus.** In 2023 the PP won 39% of the seats with 33% of the vote.
- **Mid-sized parties with an evenly spread vote lose out.** In 2023 Sumar won 9% of the seats with 12% of the vote, because in many small provinces its votes won nothing.
- **Parties concentrated in a few provinces are not penalised.** In 2023 the PNV won 1.4% of the seats with 1.1% of the vote, all of it in three provinces.
- **Small shifts can move seats.** The last seat in a province is often decided by a few hundred or a few thousand votes, which is why the projection in this app shows probabilities rather than a single number.
