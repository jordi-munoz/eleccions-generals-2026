# Projection model: national targets -> provincial votes (proportional swing
# fitted by raking) -> D'Hondt, with Monte Carlo noise at both levels.

MAX_REL_SD <- 0.30  # cap on the national error of a party, on the logit scale
MIN_REST   <- 0.01  # floor for lists not polled + blank votes

# Default uncertainty settings: the sidebar starts here, and the exported
# projection (R/export.R) always uses them.
DEFAULT_SIMS    <- 1000
DEFAULT_NAT_ERR <- 2     # points, for a party at 30%
DEFAULT_SIGMA   <- 0.12  # provincial deviation, log scale
SIM_SEED        <- 2026

TREND_HALF_LIFE <- 14  # days after which a poll weighs half in the trend
TREND_MIN_POLLS <- 8   # fewer polls than this for a party: no trend

# Trend estimate of each party's national share (percent). A straight line
# over time is fitted to all polls, with a level for each pollster (levels
# average zero, so the estimate is that of an average pollster) and more
# weight for recent polls. The estimate is the line at the date of the latest
# poll. Where the line cannot be trusted (few polls, not enough repeated
# pollsters to tell trend from pollster, or a value outside what polls show)
# the party keeps its value in `fallback`.
trend_estimate <- function(dates, pollster, shares, fallback) {
  level <- trend_fit(dates, pollster, shares)["level", ]
  # setNames: with a single party the line above drops the name.
  setNames(ifelse(is.na(level), fallback[colnames(shares)], level), colnames(shares))
}

# The fitted lines themselves: for each party, `level` on the date of the
# latest poll and `slope` in points per day (both NA where there is no line).
trend_fit <- function(dates, pollster, shares) {
  t <- as.numeric(dates - max(dates))
  w <- 0.5^(-t / TREND_HALF_LIFE)
  vapply(colnames(shares), function(p) {
    none <- c(level = NA_real_, slope = NA_real_)
    ok <- !is.na(shares[, p])
    if (sum(ok) < TREND_MIN_POLLS) return(none)
    d <- data.frame(y = shares[ok, p], t = t[ok], f = factor(pollster[ok]), w = w[ok])
    if (nlevels(d$f) > 1) contrasts(d$f) <- contr.sum(nlevels(d$f))
    fit <- lm(if (nlevels(d$f) > 1) y ~ t + f else y ~ t, data = d, weights = w)
    b <- coef(fit)
    # A tolerance keeps a line that ends exactly on the newest poll from being
    # rejected over rounding.
    tol <- 1e-6
    if (anyNA(b) || b[[1]] < min(d$y) - tol || b[[1]] > max(d$y) + tol) none else
      c(level = b[[1]], slope = b[["t"]])
  }, c(level = 0, slope = 0))
}

# Trend curves for the polls chart: the same fit as trend_fit(), repeated
# centred on each date of `grid`, with weights halving every TREND_HALF_LIFE
# days on both sides of that date. On the latest poll date only earlier polls
# exist, so the curve ends exactly at the trend estimate. Parties without a
# trend line (see trend_fit) get NA. Returns a matrix: grid dates x parties.
trend_curve <- function(dates, pollster, shares,
                        grid = seq(min(dates), max(dates), by = 1)) {
  t <- as.numeric(dates - max(dates))
  g <- as.numeric(grid - max(dates))
  has_line <- !is.na(trend_fit(dates, pollster, shares)["level", ])
  out <- matrix(NA_real_, length(grid), ncol(shares),
                dimnames = list(as.character(grid), colnames(shares)))
  for (p in colnames(shares)[has_line]) {
    ok <- !is.na(shares[, p])
    d <- data.frame(y = shares[ok, p], t = t[ok], f = factor(pollster[ok]))
    if (nlevels(d$f) > 1) contrasts(d$f) <- contr.sum(nlevels(d$f))
    form <- if (nlevels(d$f) > 1) y ~ dt + f else y ~ dt
    out[, p] <- vapply(g, function(at) {
      d$dt <- d$t - at
      d$w <- 0.5^(abs(d$dt) / TREND_HALF_LIFE)
      b <- coef(lm(form, data = d, weights = w))
      if (anyNA(b)) NA_real_ else b[[1]]
    }, numeric(1))
  }
  out
}

# National estimates from the polls of load_polls() (percent, per polled
# party). The average takes the latest poll of each pollster; a party no poll
# publishes has no average and keeps its 2023 share. The trend uses every
# poll and, where it has no value, takes the average. `poll_n` is the sample
# size of each poll, DEFAULT_N where not published.
poll_estimates <- function(pl, base) {
  has_polls <- nrow(pl$polls) > 0
  avg <- if (has_polls) {
    colMeans(pl$shares[pl$in_avg, POLLED, drop = FALSE], na.rm = TRUE)
  } else {
    100 * base$nat23[POLLED]
  }
  avg[is.nan(avg)] <- NA
  trend <- if (has_polls) {
    shares <- pl$shares[, POLLED, drop = FALSE]
    trend_estimate(pl$polls$date, pl$pollster, shares, avg)
  } else {
    avg
  }
  list(has_polls = has_polls, avg = avg, trend = trend,
       poll_n = ifelse(is.na(pl$polls$n), DEFAULT_N, pl$polls$n))
}

# National targets (fractions over valid votes) for every column of the
# baseline. `pct` is a named vector in percent for the polled parties, NA where
# unknown. NAs are filled from `fallback` (the poll average) when available;
# lists nobody polls keep their 2023 national share, and the residual
# "others + blank" column takes whatever is left.
build_target <- function(pct, base, fallback = NULL) {
  cols <- colnames(base$seed)
  tgt <- setNames(rep(NA_real_, length(cols)), cols)
  tgt[names(pct)] <- pct / 100
  imputed <- character(0)
  if (!is.null(fallback)) {
    miss <- names(pct)[is.na(pct) & !is.na(fallback[names(pct)])]
    tgt[miss] <- fallback[miss] / 100
    imputed <- miss
  }
  entered <- sum(tgt, na.rm = TRUE)
  # A party polled inside another one takes its 2023 part of the joint figure.
  for (p in names(INSIDE)) {
    host <- INSIDE[[p]]
    if (is.na(tgt[p]) && !is.na(tgt[host])) {
      k <- base$nat23[[p]] / (base$nat23[[p]] + base$nat23[[host]])
      tgt[p] <- tgt[host] * k
      tgt[host] <- tgt[host] * (1 - k)
    }
  }
  held <- is.na(tgt) & cols != OTHERS
  tgt[held] <- base$nat23[held]
  named <- cols != OTHERS
  total <- sum(tgt[named])
  rescaled <- total > 1 - MIN_REST
  if (rescaled) tgt[named] <- tgt[named] * (1 - MIN_REST) / total
  tgt[OTHERS] <- 1 - sum(tgt[named])
  list(target = tgt, imputed = imputed, held = cols[held], entered = entered,
       rescaled = rescaled)
}

# Raking of S stacked province x party tables (array S x I x P) so that every
# province keeps its weight `w` and every party hits its national target
# (matrix S x P). Zero cells stay zero: nobody wins votes where it did not run.
rake <- function(A, w, tgt, iters = 12) {
  d <- dim(A)
  sim <- rep(seq_len(d[1]), times = d[2])
  W <- matrix(w, d[1], d[2], byrow = TRUE)
  for (k in seq_len(iters)) {
    cs <- rowsum(matrix(A, d[1] * d[2], d[3]), sim, reorder = FALSE)
    f <- ifelse(cs > 0, tgt / cs, 0)
    A <- A * array(f[, rep(seq_len(d[3]), each = d[2])], d)
    A <- A * as.vector(W / rowSums(A, dims = 2))
  }
  A
}

# D'Hondt for S simulations at once. V: S x P votes, already zeroed for lists
# below the threshold.
dhondt <- function(V, n) {
  seats <- matrix(0L, nrow(V), ncol(V))
  idx <- seq_len(nrow(V))
  for (k in seq_len(n)) {
    ij <- cbind(idx, max.col(V / (seats + 1L), ties.method = "first"))
    seats[ij] <- seats[ij] + 1L
  }
  seats
}

# Runs the central projection plus `sims` Monte Carlo draws.
#   n_poll     sample size behind the target (NA = no sampling error)
#   nat_err    non-sampling national error, in points for a party at 30%
#   sigma_prov sd of the provincial deviation from proportional swing (log scale)
simulate_election <- function(base, target, n_poll = NA, sims = DEFAULT_SIMS,
                              nat_err = DEFAULT_NAT_ERR, sigma_prov = DEFAULT_SIGMA,
                              seed = SIM_SEED, lists_2026 = TRUE) {
  set.seed(seed)
  S <- sims + 1L  # row 1 carries no noise: the central projection
  I <- nrow(base$seed)
  P <- ncol(base$seed)
  cols <- colnames(base$seed)

  # National level: error on the logit scale, then renormalised.
  v <- (if (is.na(n_poll)) 0 else 1 / n_poll) + (nat_err / 100)^2 / (0.3 * 0.7)
  sd_logit <- pmin(sqrt(v / (target * (1 - target))), MAX_REL_SD)
  sd_logit[target <= 0] <- 0
  Z <- matrix(rnorm(S * P), S, P)
  Z[1, ] <- 0
  nat <- plogis(matrix(qlogis(target), S, P, byrow = TRUE) + Z * rep(sd_logit, each = S))
  nat <- nat / rowSums(nat)

  # Provincial level: 2023 distribution with lognormal noise, raked to targets.
  E <- array(rnorm(S * I * P, sd = sigma_prov), c(S, I, P))
  E[1, , ] <- 0
  w <- base$valid / sum(base$valid)
  A <- rake(array(rep(base$seed, each = S), c(S, I, P)) * exp(E), w, nat)

  # Podemos is projected everywhere like any other party. Where it does not run
  # on its own, its votes are then handed over: half to ERC and half to Frente
  # Amplio in Catalonia, all to the joint list it belongs to in the Valencian
  # provinces and the Canary Islands.
  pod <- match("PODEMOS", cols)
  give <- function(A, prov, to, frac) {
    i <- match(prov, base$cpro)
    j <- match(to, cols)
    A[, i, j] <- A[, i, j] + A[, i, pod] * frac
    A
  }
  A <- give(A, PODEMOS_ABSENT, "ERC", PODEMOS_TO_ERC)
  A <- give(A, PODEMOS_ABSENT, "SUMAR", 1 - PODEMOS_TO_ERC)
  for (to in names(PODEMOS_JOINED)) A <- give(A, PODEMOS_JOINED[[to]], to, 1)
  A[, match(c(PODEMOS_ABSENT, unlist(PODEMOS_JOINED)), base$cpro), pod] <- 0

  # Navarra: UPN runs on a joint list with PP, which takes its votes.
  # (lists_2026 = FALSE keeps the 2023 lists, for the check against 2023.)
  if (lists_2026) {
    i <- match(NAVARRA_PROV, base$cpro)
    A[, i, match("PP", cols)] <- A[, i, match("PP", cols)] + A[, i, match("UPN", cols)]
    A[, i, match("UPN", cols)] <- 0
  }

  seats <- array(0L, c(S, I, P))
  share <- array(0, c(S, I, P))
  for (i in seq_len(I)) {
    sh <- A[, i, ] / w[i]
    share[, i, ] <- sh
    sh[sh < THRESHOLD] <- 0
    sh[, cols == OTHERS] <- 0
    seats[, i, ] <- dhondt(sh, base$seats[i])
  }
  dn <- list(base$cpro, cols)
  list(
    share = structure(share[1, , ], dimnames = dn),
    seats = structure(seats[1, , ], dimnames = dn),
    nat_share = setNames(colSums(A[1, , ]), cols),
    sim_seats = seats[-1, , , drop = FALSE],
    sim_share = share[-1, , , drop = FALSE],
    cols = cols
  )
}

# One row per party for a province (i = row index) or for Spain (i = NULL).
summarise_seats <- function(sim, base, i = NULL) {
  if (is.null(i)) {
    draws <- apply(sim$sim_seats, c(1, 3), sum)
    out <- data.frame(share = sim$nat_share, share23 = base$nat23,
                      seats = colSums(sim$seats), seats23 = colSums(base$seats23))
  } else {
    draws <- sim$sim_seats[, i, ]
    out <- data.frame(share = sim$share[i, ],
                      share23 = base$votes23[i, ] / base$valid[i],
                      seats = sim$seats[i, ], seats23 = base$seats23[i, ])
  }
  out$code <- sim$cols
  out$lo <- apply(draws, 2, quantile, 0.05, names = FALSE, type = 1)
  out$hi <- apply(draws, 2, quantile, 0.95, names = FALSE, type = 1)
  out$mean <- colMeans(draws)
  out$p_any <- colMeans(draws > 0)
  out <- out[out$code != OTHERS, ]
  out[order(-out$seats, -out$share), ]
}

# Share of simulations in which each party wins at least k seats in province
# i (matrix party x k): how safe its first, second, ... seat is.
seat_probs <- function(sim, i) {
  draws <- sim$sim_seats[, i, ]
  p <- vapply(seq_len(max(draws, 1)), function(k) colMeans(draws >= k), numeric(ncol(draws)))
  rownames(p) <- sim$cols
  p
}

# Who takes the last seat of a province in the central projection, who is next
# in line and how many points of the valid vote the latter is short of.
last_seat <- function(sim, base, i) {
  sh <- sim$share[i, ]
  sh[sh < THRESHOLD | names(sh) == OTHERS] <- 0
  s <- sim$seats[i, ]
  won <- ifelse(s > 0, sh / pmax(s, 1), 0)
  nxt <- sh / (s + 1)
  winner <- names(which.max(ifelse(s > 0, -won, -Inf)))
  runner <- names(which.max(nxt))
  list(winner = winner, runner = runner,
       gap = 100 * (won[[winner]] - nxt[[runner]]) * (s[[runner]] + 1))
}
