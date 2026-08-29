## Parameter recovery check for simulab.
##
## Each block generates data from known parameters, fits the corresponding
## model to the simulated data, and reports the largest absolute discrepancy
## between the true and recovered values. Run with:
##
##   Rscript inst/recovery-check.R
##
## Sample sizes are chosen so that Monte Carlo error is small relative to the
## quantities being recovered. The script uses only base R and simulab.

row <- function(label, target, estimate) {
  cat(sprintf("%-34s %-22s %-22s %.4f\n", label,
      paste(round(target, 3), collapse = " "),
      paste(round(estimate, 3), collapse = " "),
      max(abs(target - estimate))))
}
cat(sprintf("%-34s %-22s %-22s %s\n", "quantity", "true value", "recovered", "max |diff|"))

# 1. Linear regression coefficients, recovered by lm() on the simulated data.
d <- simulate_regression(50000, c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3), seed = 1)
row("regression coefficients", c(1, 0.5, -0.3),
    unname(coef(lm(outcome ~ x1 + x2, data = as.data.frame(d)))))

# 2. Two-parameter IRT item probabilities, against numerical integration over theta.
a <- c(1, 1.2, 0.8); b <- c(-1, 0, 1)
d <- as.data.frame(simulate_irt(200000, a, b, seed = 11))
row("IRT 2PL marginal item p",
    vapply(seq_along(a), function(j) integrate(
      function(t) plogis(a[j] * (t - b[j])) * dnorm(t), -8, 8)$value, numeric(1)),
    vapply(paste0("item_", 1:3), function(v) mean(d[[v]]), numeric(1)))

# 3. Markov transition matrix, recovered by counting observed transitions.
tm <- matrix(c(0.7, 0.3, 0.4, 0.6), 2, byrow = TRUE)
tr <- summarize_transitions(
  simulate_markov(4000, tm, 60, states = c("A", "B"), seed = 5), normalize = TRUE)
row("Markov transition matrix", as.vector(t(tm)),
    c(tr$probability[tr$from == "A" & tr$to == "A"], tr$probability[tr$from == "A" & tr$to == "B"],
      tr$probability[tr$from == "B" & tr$to == "A"], tr$probability[tr$from == "B" & tr$to == "B"]))

# 4. Hidden Markov emission matrix, recovered by cross-tabulating state and observation.
em <- matrix(c(0.9, 0.1, 0.2, 0.8), 2, byrow = TRUE)
h <- as.data.frame(simulate_hmm(3000, tm, 40, em, seed = 6))
row("HMM emission matrix", as.vector(t(em)),
    as.vector(t(prop.table(table(h$state, h$observation), 1))))

# 5. Lag-one VAR matrix, recovered by regressing each series on both lags.
A <- matrix(c(0.5, 0.1, 0.0, 0.4), 2, byrow = TRUE)
v <- as.data.frame(simulate_longitudinal(400, 120, A,
                                         between_covariance = matrix(0, 2, 2), seed = 15))
lagged <- do.call(rbind, lapply(split(v, v$id), function(g) {
  g <- g[order(g$occasion), ]
  data.frame(y1 = g$variable_1[-1], y2 = g$variable_2[-1],
             l1 = head(g$variable_1, -1), l2 = head(g$variable_2, -1))
}))
row("VAR(1) transition matrix", as.vector(t(A)),
    c(unname(coef(lm(y1 ~ l1 + l2, lagged))[-1]),
      unname(coef(lm(y2 ~ l1 + l2, lagged))[-1])))

# 6. Weibull proportional-hazards coefficient, read off the AFT scale as -beta/shape.
s <- as.data.frame(simulate_proportional_survival(60000, c(x1 = 0.7), shape = 1.5,
                                                  censoring = 0, seed = 16))
row("Weibull AFT log-HR", -0.7 / 1.5, unname(coef(lm(log(time) ~ x1, data = s))[2]))

# 7. Confirmatory factor model, compared against the loading-implied covariance.
L <- matrix(c(0.8, 0.7, 0.6, 0, 0, 0, 0, 0, 0, 0.8, 0.7, 0.6), ncol = 2)
f <- as.data.frame(simulate_factors(100000, L, seed = 3))
implied <- L %*% t(L)
row("CFA implied covariance", implied[lower.tri(implied)],
    cov(f[, paste0("item_", 1:6)])[lower.tri(implied)])
