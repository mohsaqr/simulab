# simulab

simulab simulates tidy data with known ground truth. Each simulator
takes the parameters of a data-generating process and returns the
observations it produces, together with the parameters themselves as
tidy tables. The package covers declarative variable definitions,
correlated and clustered data, treatment assignment, missingness,
survival and competing risks, latent-variable and item-response models,
longitudinal processes, event sequences, and static, bipartite,
multiplex, temporal and transition networks.

The package is written in base R. It has no hard dependencies beyond the
base distribution and requires R 4.1.0 or later.

## Installation

``` r

remotes::install_github("mohsaqr/simulab")
```

Four packages are suggested and none is required at run time. `tna`
(1.2.3 or later) supplies the transition-network estimators used by
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md).
`igraph` (2.0.0 or later) receives graphs from
[`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md).
`simstudy` is used as an equivalence oracle in the test suite.
`testthat`, `knitr` and `rmarkdown` build the tests and the vignette.

## The result contract

Every simulator returns a `simulab_sim` object. The object inherits from
`data.frame` and holds one row per observation, so it can be passed
directly to [`lm()`](https://rdrr.io/r/stats/lm.html),
[`table()`](https://rdrr.io/r/base/table.html),
[`aggregate()`](https://rdrr.io/r/stats/aggregate.html) or any function
that accepts a data frame. The parameters that generated the data are
attached as named tables.

[`components()`](https://mohsaqr.github.io/simulab/reference/components.md)
lists the tables a result carries. It takes a `simulab_sim` object and
returns a data frame with one row per table and columns `table`, `rows`
and `columns`.

[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) retrieves
one table. It takes the object and a `what` argument naming the table,
and returns a base data frame. `what = "data"` is the default and
returns the observations.

``` r

result <- simulate_ttest(n_a = 40, n_b = 40, mean_a = 0, mean_b = 0.6, seed = 1)
components(result)
#>        table rows columns
#> 1       data   80       3
#> 2 parameters    2       4
#> 3    effects    1       4

as.data.frame(result, what = "parameters")
#>   group  n mean sd
#> 1     A 40  0.0  1
#> 2     B 40  0.6  1

as.data.frame(result, what = "effects")
#>   contrast mean_difference pooled_sd cohens_d
#> 1    B - A             0.6         1      0.6
```

The `parameters` table records the population means and standard
deviations that were requested. The `effects` table records the
population contrast implied by them: a mean difference of 0.6 with a
pooled standard deviation of 1 gives a Cohen’s *d* of 0.6. Neither table
is estimated from the sample. Both state what the generating process was
set to.

[`summary()`](https://rdrr.io/r/base/summary.html) describes the
observations. It returns one row per variable with the storage class,
the number of observations, the count of missing values, the number of
distinct values, and the mean, standard deviation, minimum and maximum
for numeric columns.

[`print()`](https://rdrr.io/r/base/print.html) shows the first ten rows
with a header giving the simulator type and the dimensions of the
observation table.

``` r

print(result)
#> <simulab_sim:ttest> 80 rows x 3 columns
#>    id group    outcome
#> 1   1     A -0.6264538
#> 2   2     A  0.1836433
#> 3   3     A -0.8356286
#> ... 70 more rows
```

Results are ordinary data frames, so no accessor is needed to analyse
them. The `what` argument exists to reach the generating parameters,
which are the part a simulation study needs and a plain data frame
cannot carry.

## Long-form input

Every argument that is a matrix, an array or a list of matrices also
accepts the equivalent long-form data frame. A transition matrix and its
tidy table generate the same data under the same seed.

``` r

simulate_hmm(
  n = 40, chain_length = 10,
  transition = data.frame(from = c("A", "A", "B", "B"),
                          to = c("A", "B", "A", "B"),
                          probability = c(0.7, 0.3, 0.4, 0.6)),
  emission = data.frame(state = c("A", "A", "B", "B"),
                        observation = c("x", "y", "x", "y"),
                        probability = c(0.9, 0.1, 0.2, 0.8))
)
```

Row and column order follows first appearance, so the layout is
controlled by ordering the rows of the table. A symmetric argument such
as a correlation or covariance may be given as one triangle: the mirror
cell is filled and the diagonal defaults to 1 for a correlation. A list
of matrices is one table with a grouping column, so
[`simulate_sequence_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_clusters.md)
takes a `cluster` column and
[`simulate_group_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_group_sequences.md)
takes a `group` column.

[`simulate_prediction()`](https://mohsaqr.github.io/simulab/reference/simulate_prediction.md)
takes the levels, effects and sampling probabilities of its categorical
predictors as one table with `variable`, `level`, `effect` and
`probability` columns, in place of three parallel lists.

30 of the package’s 35 matrix, array and list arguments accept long-form
input. The remaining five are named lists of data frames, where a list
is the correct shape.

A table that omits cells raises `simulab_incomplete_tidy_input`; one
missing a required column raises `simulab_bad_tidy_input`.

## Reproducibility

Every simulator accepts a `seed` argument. Passing a seed makes the
result reproducible. It also leaves the calling session’s random-number
state unchanged, so a seeded simulator does not advance the stream that
surrounds it.

``` r

set.seed(99)
before <- .Random.seed
a <- simulate_ttest(10, 10, 0, 1, seed = 7)
after <- .Random.seed
b <- simulate_ttest(10, 10, 0, 1, seed = 7)

identical(as.data.frame(a), as.data.frame(b))
#> [1] TRUE
identical(before, after)
#> [1] TRUE
```

The behaviour is implemented by saving `.Random.seed`, calling
[`set.seed()`](https://rdrr.io/r/base/Random.html), generating the data,
and restoring the saved state on exit. Sixty-four exported functions
accept a `seed` argument. Both properties were checked directly on 33
simulators spanning every family.

## Declarative studies

[`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md)
states a data-generating process as distribution calls. The variable
name is the argument name, and the distribution is a call whose
arguments are its parameters.

``` r

specification <- define_variables(
  age     = normal(mean = 50, sd = 10),
  treated = binary(prob = 0.5),
  outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
)

simulate_study(500, specification, seed = 42)
```

A parameter may be any expression over variables defined earlier in the
same call, which is how a regression is written. Parameters may be
positional, in the order
[`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
reports, so `normal(5, 1)` is `normal(mean = 5, sd = 1)`.

Distribution names are never evaluated, so
[`gamma()`](https://rdrr.io/r/base/Special.html),
[`beta()`](https://rdrr.io/r/base/Special.html),
[`t()`](https://rdrr.io/r/base/t.html) and `f()` name distributions
without reaching the base functions of those names. A parameter that
refers to an undefined variable is reported by name rather than silently
resolving to a base function.

[`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
reports the catalogue: 79 distributions, all built on base R with no
added dependency. Every one is checked against its theoretical mean in
`tests/testthat/test-distributions.R` and in
`inst/distribution-check.R`.

Mixtures nest distribution calls, and a link is a function in the
expression rather than a separate column:

``` r

define_variables(
  score = mixture(normal(0, 1), normal(5, 1), weights = c(0.3, 0.7)),
  group = categorical(probs = c(0.2, 0.5, 0.3)),
  sick  = binary(prob = plogis(-4 + 0.06 * age))
)
```

A parameter that leaves its distribution’s support is reported by name
rather than returning a column of missing values, so
`poisson(lambda = x)` on an `x` that can be negative raises
`simulab_invalid_parameter` naming the variable.

### The same specification reaches every simulator

A specification written as distribution calls is accepted wherever one
is taken.
[`augment_study()`](https://mohsaqr.github.io/simulab/reference/augment_study.md)
generates it into data that already exists, and a parameter may refer to
a column that was already there:

``` r

augment_study(
  data.frame(id = 1:100, treated = rep(0:1, each = 50)),
  specification = define_variables(
    outcome = normal(mean = 3 + 2 * treated, sd = 1),
    visits  = poisson(lambda = exp(0.2 * outcome))
  ),
  seed = 3
)
```

[`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md)
uses it as the marginals of a Gaussian copula, so each variable keeps
its own distribution while the set is correlated:

``` r

simulate_copula(
  n = 500,
  specification = define_variables(
    score  = normal(mean = 10, sd = 2),
    visits = poisson(lambda = 4),
    rate   = beta(shape1 = 2, shape2 = 5)
  ),
  rho = 0.6, seed = 1
)
```

A copula marginal has to be invertible, so
`list_distributions(copula = TRUE)` reports the 69 distributions that
carry a quantile function. Naming one of the other ten raises
`simulab_no_quantile` rather than failing later.

### Conditions and hazards

[`define_conditions()`](https://mohsaqr.github.io/simulab/reference/define_conditions.md)
states a rule as a condition and a distribution. Repeating the variable
name gives it one rule per condition, and every distribution in the
catalogue is available:

``` r

apply_conditions(
  data.frame(id = 1:200, group = rep(0:1, 100)),
  specification = define_conditions(
    outcome = when(group == 1, normal(mean = 5, sd = 1)),
    outcome = when(group == 0, poisson(lambda = 2)),
    bonus   = when(group == 1, gamma(shape = 2, rate = 0.5))
  ),
  seed = 1
)
```

Rules are applied in order, so a later rule may replace what an earlier
one wrote, and `when(TRUE, ...)` is the rule that applies to every row.
A row no rule selects is left missing.

[`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md)
states a process as a hazard, whose log rate is an expression over the
covariates. Repeating the event name gives a piecewise hazard, where
`from` is the time the segment begins:

``` r

simulate_survival(
  n = 500,
  specification = define_survivals(
    time = hazard(log_rate = -8 + 0.5 * treatment, shape = 0.3),
    time = hazard(log_rate = -5 + 0.5 * treatment, shape = 0.3, from = 60)
  ),
  covariates = data.frame(id = 1:500, treatment = rep(0:1, each = 250)),
  seed = 1
)
```

## Specification columns

[`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md)
records a data-generating process as a table. It takes the columns of
that table as named vectors and returns one row per variable. `variable`
and `formula` are required. A column given as a single value is recycled
across every variable, so `variance` and `distribution` are written once
when they are shared.

`formula` is the mean or the linear predictor, written as R source text.
It may refer to variables defined earlier in the same specification.
[`simulate_study()`](https://mohsaqr.github.io/simulab/reference/simulate_study.md)
takes a sample size and a specification and generates the variables in
the order they appear.

``` r

specification <- define_variables(
  variable     = c("baseline", "treatment", "outcome"),
  formula      = c("0", "0.5", "0.4 * baseline + 0.8 * treatment"),
  variance     = c("1", "0", "1"),
  distribution = c("normal", "binary", "normal")
)
specification
#>    variable distribution                          formula variance     link
#> 1  baseline       normal                                0        1 identity
#> 2 treatment       binary                              0.5        0 identity
#> 3   outcome       normal 0.4 * baseline + 0.8 * treatment        1 identity

simulate_study(500, specification, seed = 42)
```

`variance` is a variance, not a standard deviation. A `variance` of 100
gives a standard deviation of 10.

[`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md)
builds one row at a time and is accepted by
[`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md)
as an alternative to the column form. It takes a name, a `formula`, a
`variance`, a `distribution` and a `link`. The two forms cannot be mixed
in one call.

[`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md),
[`define_missingnesses()`](https://mohsaqr.github.io/simulab/reference/define_missingnesses.md)
and
[`define_conditions()`](https://mohsaqr.github.io/simulab/reference/define_conditions.md)
take the same two forms, with the columns their own specifications
require.

Seventeen distributions are available in this lane – fewer than the 79 a
distribution call reaches, because each is parameterized by a mean and a
dispersion rather than by its own parameters: `beta`, `binary`,
`binomial`, `categorical`, `cluster_size`, `custom`, `deterministic`,
`exponential`, `gamma`, `mixture`, `negative_binomial`, `normal`,
`no_zero_poisson`, `poisson`, `treatment`, `uniform` and
`uniform_integer`.

[`augment_study()`](https://mohsaqr.github.io/simulab/reference/augment_study.md)
adds variables to data that already exists. It takes a data frame and a
specification, and returns the input with the new variables appended.
Formulas may refer to columns already present.

[`update_definition()`](https://mohsaqr.github.io/simulab/reference/update_definition.md)
replaces one field of an existing specification.
[`repeat_variables()`](https://mohsaqr.github.io/simulab/reference/repeat_variables.md)
generates a numbered family of variables from a single template.
[`read_definitions()`](https://mohsaqr.github.io/simulab/reference/read_definitions.md)
reads a specification from a CSV file with columns `variable`,
`distribution`, `formula`, `variance` and `link`.

[`apply_conditions()`](https://mohsaqr.github.io/simulab/reference/apply_conditions.md)
applies different generating rules to different subsets of the same
data. It takes a data frame and rules built by
[`define_condition()`](https://mohsaqr.github.io/simulab/reference/define_condition.md),
where each rule pairs a logical expression with a generating formula.

### Which lane to use

The two lanes are not two spellings of one thing, and neither is
deprecated.

A **distribution call** parameterizes a distribution by its own
parameters: `gamma(shape = 2, rate = 0.5)` says shape and rate. It
reaches all 79 distributions, nests, and takes expressions directly.

A **specification column** parameterizes it by a mean and a dispersion
on a link scale: `formula` is the mean or linear predictor, `link` is
the scale it is written on, and `variance` is the dispersion. That is
the parameterization
[`calibrate_distribution()`](https://mohsaqr.github.io/simulab/reference/calibrate_distribution.md),
[`calibrate_icc()`](https://mohsaqr.github.io/simulab/reference/calibrate_icc.md)
and
[`calibrate_logistic()`](https://mohsaqr.github.io/simulab/reference/calibrate_logistic.md)
speak, the one
[`read_definitions()`](https://mohsaqr.github.io/simulab/reference/read_definitions.md)
reads from a CSV, and the one the multilevel and longitudinal simulators
build programmatically. `link` is meaningful only here; in a call, a
link is a function inside the expression.

Reach for calls when you know the distribution’s parameters, and for
columns when you know a mean and a dispersion.
[`calibrate_moments()`](https://mohsaqr.github.io/simulab/reference/calibrate_moments.md)
converts between them.

## Simulator catalogue

[`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md)
returns the canonical simulators as a data frame with columns
`simulator`, `family` and `primary_shape`.
[`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md)
dispatches on the `simulator` name and passes its remaining arguments
through.

| Family | Simulators |
|----|----|
| general | `study`, `correlation`, `copula`, `ordinal` |
| statistical | `ttest`, `anova`, `regression`, `clusters`, `prediction` |
| latent | `lpa`, `lca`, `factors` |
| measurement | `irt` |
| longitudinal | `multilevel`, `growth`, `longitudinal` |
| sequence | `markov`, `sequence_clusters`, `hmm`, `group_sequences`, `group_tna`, `event_log` |
| survival | `survival`, `proportional_survival` |
| empirical | `synthetic`, `density` |
| functional | `spline` |
| network | `network`, `edge_list`, `temporal_network`, `network_matrix`, `bipartite_network`, `multiplex_network`, `tna_network` |

The `primary_shape` column records the layout of the observation table.
Most simulators return one row per unit. Sequence simulators return one
row per unit per position. Network simulators return one row per edge,
except `network_matrix`, which returns one row per matrix cell.

## What each simulator exposes as truth

The tables attached to a result differ by simulator, because different
designs have different parameters. The table below lists the observation
columns and the component tables for a representative set.

| Simulator | Observation columns | Component tables |
|----|----|----|
| `simulate_ttest` | `id`, `group`, `outcome` | `parameters`, `effects` |
| `simulate_regression` | `id`, `x1`, `outcome` | `coefficients`, `effects`, `predictor_correlation` |
| `simulate_multilevel` | `id`, `cluster`, `x1`, `outcome` | `fixed_effects`, `variance_components`, `random_effects` |
| `simulate_irt` | `id`, `item_1`, `item_2` | `parameters`, `abilities` |
| `simulate_lca` | `id`, `latent_class`, `item_1`, `item_2` | `parameters` |
| `simulate_markov` | `id`, `period`, `state` | `transitions`, `initial_probabilities`, `wide` |
| `simulate_sequences` | `id`, `period`, `state` | `transitions`, `initial_probabilities`, `wide`, `settings` |
| `simulate_network` | `from`, `to`, `weight` | `nodes`, `adjacency`, `settings` |
| `simulate_temporal_network` | `from`, `to`, `onset`, `terminus`, `weight`, `censored` | `events`, `snapshots`, `nodes`, `settings` |
| `simulate_copula` | `id`, `a`, `b` | `definitions`, `latent_correlation` |

Alternate views of one result are component tables rather than separate
functions.
[`simulate_markov()`](https://mohsaqr.github.io/simulab/reference/simulate_markov.md)
returns long-form observations and carries the wide form as a component.
[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
returns an edge list and carries the adjacency matrix as a component.
[`simulate_temporal_network()`](https://mohsaqr.github.io/simulab/reference/simulate_temporal_network.md)
returns spells and carries both the event stream and per-period
snapshots.

## Parameter recovery

The generating parameters can be recovered from the simulated data by
fitting the corresponding model. The script below runs seven such checks
and reports the largest absolute discrepancy for each. It uses only base
R and the package itself.

``` r

library(simulab)

# Linear regression coefficients, recovered by lm() on the simulated data.
d <- simulate_regression(50000, c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3), seed = 1)
coef(lm(outcome ~ x1 + x2, data = as.data.frame(d)))

# Markov transition matrix, recovered by counting observed transitions.
tm <- matrix(c(0.7, 0.3, 0.4, 0.6), 2, byrow = TRUE)
summarize_transitions(simulate_markov(4000, tm, 60, states = c("A", "B"), seed = 5),
                      normalize = TRUE)
```

The full script is shipped as `inst/recovery-check.R` and is run with
`Rscript inst/recovery-check.R`. It reports:

| Quantity | True value | Recovered | Max abs. difference |
|----|----|----|----|
| Regression coefficients | 1, 0.5, -0.3 | 1.004, 0.493, -0.299 | 0.0068 |
| IRT 2PL marginal item probability | 0.697, 0.500, 0.331 | 0.696, 0.498, 0.333 | 0.0021 |
| Markov transition matrix | 0.7, 0.3, 0.4, 0.6 | 0.701, 0.299, 0.399, 0.601 | 0.0012 |
| HMM emission matrix | 0.9, 0.1, 0.2, 0.8 | 0.900, 0.100, 0.199, 0.801 | 0.0007 |
| VAR(1) transition matrix | 0.5, 0.1, 0.0, 0.4 | 0.502, 0.096, -0.004, 0.402 | 0.0038 |
| Weibull AFT log hazard ratio | -0.467 | -0.467 | 0.0007 |
| CFA loading-implied covariance | 0.56, 0.48, 0.42 and 9 zeros | 0.570, 0.484, 0.422 and 9 near-zeros | 0.0097 |

The IRT row compares the simulated item means against the marginal
probabilities obtained by integrating the two-parameter logistic curve
over a standard normal ability distribution, rather than against a rule
of thumb. The Weibull row uses the accelerated-failure-time identity,
under which a proportional-hazards coefficient of 0.7 with shape 1.5
appears as a slope of -0.7 / 1.5 on the log-time scale. Each discrepancy
is within Monte Carlo error for the sample size used.

## Correlated data

[`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md)
draws multivariate normal variables. It takes a sample size, means,
standard deviations, and a correlation specification, and returns one
row per observation with the correlation and covariance matrices as
component tables.

The correlation is specified in one of three ways. `rho` with
`structure = "exchangeable"` gives a constant off-diagonal correlation.
`rho` with `structure = "ar1"` gives a first-order autoregressive
pattern. A `correlation` matrix gives an arbitrary target.

Leaving `structure` unset selects `"exchangeable"` when a non-zero `rho`
is supplied and `"custom"` when a `correlation` matrix is supplied.
Requesting `structure = "independent"` together with a non-zero `rho`
raises an error of class `simulab_contradictory_structure` rather than
returning uncorrelated data.

[`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md)
draws correlated variables with non-normal margins. It takes a sample
size, a specification of the marginal distributions, and a latent
correlation. The correlation applies to the latent normal variables, so
the observed rank correlation is close to the requested value while the
observed product-moment correlation is attenuated by the marginal
transforms.

[`simulate_ordinal()`](https://mohsaqr.github.io/simulab/reference/simulate_ordinal.md)
draws correlated ordinal variables by thresholding latent normal
variables. `rho` again describes the latent correlation. A requested
latent correlation of 0.4 across three ordered categories produces an
observed Pearson correlation near 0.32 on the category codes, which is
the expected polychoric attenuation.

[`correlation_structure()`](https://mohsaqr.github.io/simulab/reference/correlation_structure.md)
and
[`block_correlation()`](https://mohsaqr.github.io/simulab/reference/block_correlation.md)
build correlation matrices without simulating data.
[`block_correlation()`](https://mohsaqr.github.io/simulab/reference/block_correlation.md)
constructs matrices with separate within-period, between-period and
within-individual blocks, with optional decay.

## Missingness

[`inject_missingness()`](https://mohsaqr.github.io/simulab/reference/inject_missingness.md)
sets values to `NA` under a named mechanism. It takes a data frame, a
`mechanism` of `"MCAR"`, `"MAR"` or `"MNAR"`, a target `proportion`, and
the variables to affect. MAR missingness additionally takes an observed
`predictor`.

The target proportion is calibrated rather than approximated. The
function solves for the multiplier that makes the expected missing
fraction equal the requested value, and the solve is checked for
convergence before its result is used.

[`define_missingness()`](https://mohsaqr.github.io/simulab/reference/define_missingness.md)
and
[`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md)
separate the two steps for longitudinal data.
[`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md)
returns a logical mask with the same shape as the input.
[`observed_data()`](https://mohsaqr.github.io/simulab/reference/observed_data.md)
applies a mask, holding identifier columns exempt. The `monotone`
argument makes a unit that becomes missing stay missing at later
periods.

## Treatment assignment and design structure

[`assign_treatment()`](https://mohsaqr.github.io/simulab/reference/assign_treatment.md)
allocates units to groups. It takes a data frame, a number of groups or
their labels, optional `strata`, and optional allocation `ratios`. With
`balanced = TRUE` the allocation is exactly balanced within each
stratum.

[`observe_treatment()`](https://mohsaqr.github.io/simulab/reference/observe_treatment.md)
generates a non-randomised exposure from covariates. It takes
probability formulas and a link, and returns the input with an exposure
variable appended.

[`assign_stepped_wedge()`](https://mohsaqr.github.io/simulab/reference/assign_stepped_wedge.md)
builds a stepped-wedge trial. It takes long-form data with cluster and
period columns, a number of waves, and a wave length, and returns the
input with treatment and transition indicators.

[`expand_clusters()`](https://mohsaqr.github.io/simulab/reference/expand_clusters.md)
turns cluster-level data into unit-level data.
[`expand_periods()`](https://mohsaqr.github.io/simulab/reference/expand_periods.md)
turns unit-level data into long form, with either common period values
or irregular gamma-spaced intervals.
[`factorial_design()`](https://mohsaqr.github.io/simulab/reference/factorial_design.md)
builds a factorial grid from a named vector of level counts.
[`encode_factors()`](https://mohsaqr.github.io/simulab/reference/encode_factors.md)
applies factor, dummy or effect coding.

## Survival and competing risks

[`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md)
records one event-time process. It takes an event name, a log-hazard
`formula`, a Weibull `shape`, and an optional `transition` time at which
the specification takes effect. Splitting a process across two
definitions with different transition times gives a piecewise hazard.

[`simulate_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_survival.md)
and
[`augment_survival()`](https://mohsaqr.github.io/simulab/reference/augment_survival.md)
generate event times from such definitions.
[`combine_competing_risks()`](https://mohsaqr.github.io/simulab/reference/combine_competing_risks.md)
reduces several event-time variables to an observed time, an integer
event code, and an event type.

[`simulate_proportional_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_proportional_survival.md)
generates times from a proportional-hazards model directly. It takes
named covariate coefficients, a baseline of `"weibull"`, `"exponential"`
or `"gompertz"`, a shape, and a target censoring proportion. The
censoring rate is solved for rather than fixed, so the realised
proportion matches the request.

[`calibrate_survival()`](https://mohsaqr.github.io/simulab/reference/calibrate_survival.md)
goes the other way. It takes observed times and survival probabilities
and returns the Weibull formula and shape that reproduce them, with the
optimiser’s convergence code and the root mean squared error in the
result.

## Latent variable and measurement models

[`simulate_lpa()`](https://mohsaqr.github.io/simulab/reference/simulate_lpa.md)
draws continuous indicators from a mixture of normals. It takes a
`means` matrix with one row per profile and one column per indicator,
standard deviations in the same layout or a scalar, and mixing
`proportions`.

[`simulate_lca()`](https://mohsaqr.github.io/simulab/reference/simulate_lca.md)
draws categorical indicators from a latent class model. It takes a
`probabilities` array with dimensions class, indicator and category. The
array is the least obvious input in the package, so its example builds
one explicitly.

[`simulate_factors()`](https://mohsaqr.github.io/simulab/reference/simulate_factors.md)
draws indicators from a confirmatory factor model. It takes a `loadings`
matrix with one row per item and one column per factor, plus optional
uniquenesses and a factor correlation matrix.

[`simulate_irt()`](https://mohsaqr.github.io/simulab/reference/simulate_irt.md)
draws item responses from an item-response model. It takes
`discrimination` and `difficulty` vectors, a `model` of `"rasch"`,
`"2pl"` or `"3pl"`, and a `guessing` parameter for the three-parameter
form. Multiple ability dimensions are available through `dimensions` and
`ability_correlation`.

## Longitudinal and multilevel designs

[`simulate_multilevel()`](https://mohsaqr.github.io/simulab/reference/simulate_multilevel.md)
draws data from a random-intercept and random-slope model. It takes a
number of clusters, a cluster size, a fixed intercept, named fixed
`slopes`, and standard deviations for the random intercept, the random
slope and the residual. The realised intraclass correlation matches the
value implied by the variance components.

[`simulate_growth()`](https://mohsaqr.github.io/simulab/reference/simulate_growth.md)
draws latent growth curves. It takes measurement `times`, a mean
intercept and slope, an optional quadratic term, random-effect standard
deviations, and a residual standard deviation.

[`simulate_longitudinal()`](https://mohsaqr.github.io/simulab/reference/simulate_longitudinal.md)
draws a multivariate first-order vector autoregressive process. It takes
a lag-one `transition` matrix, an innovation covariance, an initial
covariance, and a between-unit covariance of person means.
`beeps_per_day` resets temporal carryover at each day boundary, which
matches experience-sampling designs. `burn_in` discards warm-up
occasions.

## Sequences and transition networks

[`simulate_markov()`](https://mohsaqr.github.io/simulab/reference/simulate_markov.md)
draws state sequences from a first-order Markov chain. It takes a
`transition` matrix or a tidy table with `from`, `to` and `probability`
columns, a `chain_length`, and state labels. `initial` accepts either a
named starting state or a vector of starting probabilities. `trim_state`
truncates each sequence at the first occurrence of an absorbing state.

[`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md)
generates sequences with additional structure. Without a supplied
transition matrix it draws one from a Dirichlet distribution, with
`concentration` controlling how uneven the rows are.
`stable_transitions` names preferred `from` and `to` pairs that are
followed with probability `stability_probability`. `instability`
perturbs the remaining transitions by one of `"random_jump"`,
`"perturb"` or `"unlikely_jump"`. `missing_tail` removes a random number
of trailing positions from each sequence.

[`simulate_hmm()`](https://mohsaqr.github.io/simulab/reference/simulate_hmm.md)
draws observed symbols from a hidden Markov model, returning both the
latent state and the observation for each position.
[`simulate_sequence_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_clusters.md)
draws sequences from a mixture of transition matrices and records the
generating cluster.

[`summarize_transitions()`](https://mohsaqr.github.io/simulab/reference/summarize_transitions.md)
counts observed transitions in long-form sequence data. It returns one
row per ordered state pair with a count and, when `normalize = TRUE`, a
row-normalised probability.

[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
estimates a transition network from sequence data using the `tna`
package. It takes sequence data and a `model` of `"tna"`, `"ftna"`,
`"ctna"` or `"atna"`, and returns a tidy edge list.
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md)
converts the result to a native `tna` object when downstream plotting or
inference requires one.

[`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md),
[`sample_tna()`](https://mohsaqr.github.io/simulab/reference/sample_tna.md),
[`cross_validate_tna()`](https://mohsaqr.github.io/simulab/reference/cross_validate_tna.md),
[`assess_tna_reliability()`](https://mohsaqr.github.io/simulab/reference/assess_tna_reliability.md)
and
[`compare_tna_models()`](https://mohsaqr.github.io/simulab/reference/compare_tna_models.md)
are simulation workflows built on the same estimators.
[`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md)
repeatedly generates sequences from a known transition system and
reports how well each estimator recovers it.

[`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md)
and
[`sample_learning_states()`](https://mohsaqr.github.io/simulab/reference/sample_learning_states.md)
supply labelled state spaces in eight categories, including
metacognitive, cognitive, behavioural, social, motivational, affective,
group-regulation and learning-management-system states.
[`simulate_event_log()`](https://mohsaqr.github.io/simulab/reference/simulate_event_log.md)
generates educational event logs with groups, actors, courses,
timestamps and achievement levels.

## Networks

[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
generates a graph from one of seven models: `"bernoulli"`,
`"barabasi_albert"`, `"small_world"`, `"block"`, `"regular"`,
`"geometric"` and `"forest_fire"`. It returns a tidy edge list with
`from`, `to` and `weight` columns, and carries the node table and the
adjacency matrix as components.

Five further verbs cover the network layouts that a tidy edge list alone
does not express.
[`simulate_edge_list()`](https://mohsaqr.github.io/simulab/reference/simulate_edge_list.md)
generates plain edge lists with optional node types and edge classes.
[`simulate_temporal_network()`](https://mohsaqr.github.io/simulab/reference/simulate_temporal_network.md)
generates activity spells with formation and dissolution probabilities,
and carries an event stream and per-period snapshots.
[`simulate_network_matrix()`](https://mohsaqr.github.io/simulab/reference/simulate_network_matrix.md)
generates adjacency, transition, frequency or co-occurrence matrices.
[`simulate_bipartite_network()`](https://mohsaqr.github.io/simulab/reference/simulate_bipartite_network.md)
generates actor-event incidence.
[`simulate_multiplex_network()`](https://mohsaqr.github.io/simulab/reference/simulate_multiplex_network.md)
generates several layers over a shared node set.

[`network_centrality()`](https://mohsaqr.github.io/simulab/reference/network_centrality.md)
computes degree, strength, betweenness, closeness, eigenvector and
PageRank centralities.
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md)
and
[`compare_centralities()`](https://mohsaqr.github.io/simulab/reference/compare_centralities.md)
compare two graphs.
[`evaluate_edge_recovery()`](https://mohsaqr.github.io/simulab/reference/evaluate_edge_recovery.md)
scores an estimated edge set against a known one.
[`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md)
converts a result to an `igraph` graph.

## Calibration

[`calibrate_moments()`](https://mohsaqr.github.io/simulab/reference/calibrate_moments.md)
solves a distribution’s own parameters from a target mean and variance,
across 36 distributions. The result names the parameters a distribution
call takes, so a moment target becomes a specification.

``` r

calibrate_moments("lognormal", mean = 10, variance = 25)
#>   distribution mean variance parameter     value
#> 1    lognormal   10       25   meanlog 2.1910133
#> 2    lognormal   10       25     sdlog 0.4723807

define_variables(income = lognormal(meanlog = 2.1910133, sdlog = 0.4723807))
```

A one-parameter family takes the mean alone, because its mean already
fixes its variance, and the reported `variance` is the one that follows.
Targets recycle, so
`calibrate_moments("gamma", mean = c(5, 10, 20), variance = 9)` is one
call. Moments no member of the family attains – a beta variance at or
above `mean * (1 - mean)`, a negative binomial less dispersed than a
Poisson – raise `simulab_unattainable_moments` rather than returning a
nonsense parameter.
[`calibrate_moments()`](https://mohsaqr.github.io/simulab/reference/calibrate_moments.md)
with no arguments reports what it can invert.

Most solves are closed form. For a scale family whose shape is fixed by
the coefficient of variation alone – Weibull, log-logistic, Frechet,
Nakagami – the shape is found by root finding and the scale then follows
exactly. Some families cannot reach every pair, and say so: a Nakagami
squared coefficient of variation is at most `pi / 2 - 1`, a Lomax with a
finite variance always has one above 1.

Each inversion is checked by integrating the quantile function it
produced, which recovers the target mean and variance to about 1e-9 – a
check the algebra cannot fake, and one a sampling test cannot make,
because the sample variance of a heavy tail is still per cent-accurate
at half a million draws.

[`calibrate_distribution()`](https://mohsaqr.github.io/simulab/reference/calibrate_distribution.md)
converts a mean and dispersion into the shape parameters of a beta,
gamma or negative binomial distribution. That is the parameterization
the specification columns use, and it agrees with {simstudy}’s.

[`calibrate_icc()`](https://mohsaqr.github.io/simulab/reference/calibrate_icc.md)
returns the random-effect variance that produces a target intraclass
correlation, for normal, binary, Poisson, gamma and negative binomial
outcomes.

[`calibrate_logistic()`](https://mohsaqr.github.io/simulab/reference/calibrate_logistic.md)
returns logistic coefficients that produce a target population
prevalence. It optionally scales the coefficients to a target area under
the ROC curve, or solves for a treatment coefficient that produces a
target risk ratio or risk difference.

Every calibration is solved by root finding, and every solve is checked.
A target that no coefficient can produce raises an error of class
`simulab_no_solution`. A search that does not reach its tolerance raises
`simulab_no_convergence`. Neither returns an approximate answer
silently.

## Scenario studies, batches and export

[`scenario_grid()`](https://mohsaqr.github.io/simulab/reference/scenario_grid.md)
builds a scenario table from named vectors, with replications.
[`simulate_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulate_scenarios.md)
runs one simulator across every row of such a table, giving each row a
deterministic seed offset, and returns the pooled results with a
scenario identifier.

[`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md)
builds parameter designs by full factorial expansion, random sampling or
Latin hypercube sampling. Its own arguments are named `n`, `method` and
`seed`, so a grid parameter cannot use those three names.

[`apply_batch()`](https://mohsaqr.github.io/simulab/reference/apply_batch.md)
applies a function across a named list of inputs and stacks the results
with a batch identifier.
[`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md),
[`simulate_network_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_network_batches.md)
and
[`simulate_tna_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_batches.md)
repeat a simulator a fixed number of times with independent seeds.

[`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md)
aggregates simulated variables by group.
[`validate_recovery()`](https://mohsaqr.github.io/simulab/reference/validate_recovery.md)
compares estimated parameters against known truth and reports bias,
absolute and relative error, and whether each parameter falls within a
tolerance.
[`write_simulation()`](https://mohsaqr.github.io/simulab/reference/write_simulation.md)
writes a result or one of its component tables to CSV or RDS.

## Input validation

Argument checks state the contract that was broken and name the
argument.

``` r

simulate_clusters(n = 10, centers = list(c(0, 0), c(4, 4)))
#> Error: `centers` must be a matrix, with at least 2 rows

simulate_regression(n = 10, coefficients = c(1, 0.5))
#> Error: `coefficients` must be a named numeric vector, with at least one element
```

Conditions that a caller might reasonably catch carry a class:
`simulab_contradictory_structure` for a correlation request that cannot
be satisfied, `simulab_no_solution` and `simulab_no_convergence` for
calibration failures, and `simulab_bad_definition_file`,
`simulab_duplicate_variable`, `simulab_unknown_distribution` and
`simulab_unknown_link` for malformed specification files.

## Relationship to other packages

simulab supersedes Saqrlab and continues its version numbering. Saqrlab
is unchanged, because the seeded output of its
[`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md)
is a fixture contract for other projects. `SAQRLAB_COVERAGE.md` maps
each of Saqrlab’s 87 exported names to its resolution in simulab.

simstudy is an equivalence oracle rather than a dependency. Under the
same seed, simulab reproduces simstudy 0.9.2 values exactly for normal,
binary and gamma declarative generation, and its beta, gamma and
negative binomial parameter conversions match exactly. Nine assertions
check this, and they run whenever simstudy is installed.
`FEATURE_COVERAGE.md` maps each simstudy capability to its simulab verb.

The `tna` package supplies the transition-network estimators. simulab
keeps tidy edge lists as its result contract and provides
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md)
as the explicit bridge to native `tna` objects.

## Package status

Version 0.4.0 is the first release under the simulab name. The version
continues the line of Saqrlab (0.4.1), which has never been on CRAN. The
package is a CRAN release candidate and a new submission.

The test suite contains 612 assertions across 26 files and covers 89.9%
of package lines, measured with `covr`. With every suggested package
installed there are no skips. Tests include statistical calibration
checks, seeded regression checks, recovery checks for transition
networks and grouped models, error-path checks by condition class,
equivalence tests against simstudy, and identity checks between the
matrix and long-form call styles. Every distribution is checked against
its theoretical mean, every entry that carries both a sampler and a
quantile function is checked for agreeing with itself, and every moment
inversion is checked by integrating the quantile function it produced.

All 123 exported functions carry runnable examples, which `R CMD check`
executes. `R CMD check --as-cran` reports one note, the standard note
for a first submission, on R 4.5.2 under macOS on arm64. GitHub Actions
runs the same check on macOS, Windows and Ubuntu across R release, devel
and oldrel-1.

## Function reference

Specification and study generation:
[`define_variable()`](https://mohsaqr.github.io/simulab/reference/define_variable.md),
[`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md),
[`update_definition()`](https://mohsaqr.github.io/simulab/reference/update_definition.md),
[`repeat_variables()`](https://mohsaqr.github.io/simulab/reference/repeat_variables.md),
[`read_definitions()`](https://mohsaqr.github.io/simulab/reference/read_definitions.md),
[`simulate_study()`](https://mohsaqr.github.io/simulab/reference/simulate_study.md),
[`augment_study()`](https://mohsaqr.github.io/simulab/reference/augment_study.md),
[`define_condition()`](https://mohsaqr.github.io/simulab/reference/define_condition.md),
[`define_conditions()`](https://mohsaqr.github.io/simulab/reference/define_conditions.md),
[`apply_conditions()`](https://mohsaqr.github.io/simulab/reference/apply_conditions.md).

Correlated data:
[`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md),
[`simulate_correlation()`](https://mohsaqr.github.io/simulab/reference/simulate_correlation.md),
[`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md),
[`augment_correlated()`](https://mohsaqr.github.io/simulab/reference/augment_correlated.md),
[`simulate_ordinal()`](https://mohsaqr.github.io/simulab/reference/simulate_ordinal.md),
[`correlation_structure()`](https://mohsaqr.github.io/simulab/reference/correlation_structure.md),
[`block_correlation()`](https://mohsaqr.github.io/simulab/reference/block_correlation.md).

Statistical designs:
[`simulate_ttest()`](https://mohsaqr.github.io/simulab/reference/simulate_ttest.md),
[`simulate_anova()`](https://mohsaqr.github.io/simulab/reference/simulate_anova.md),
[`simulate_regression()`](https://mohsaqr.github.io/simulab/reference/simulate_regression.md),
[`simulate_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_clusters.md),
[`simulate_prediction()`](https://mohsaqr.github.io/simulab/reference/simulate_prediction.md).

Latent and measurement models:
[`simulate_lpa()`](https://mohsaqr.github.io/simulab/reference/simulate_lpa.md),
[`simulate_lca()`](https://mohsaqr.github.io/simulab/reference/simulate_lca.md),
[`simulate_factors()`](https://mohsaqr.github.io/simulab/reference/simulate_factors.md),
[`simulate_irt()`](https://mohsaqr.github.io/simulab/reference/simulate_irt.md),
[`simulate_hmm()`](https://mohsaqr.github.io/simulab/reference/simulate_hmm.md).

Longitudinal designs:
[`simulate_multilevel()`](https://mohsaqr.github.io/simulab/reference/simulate_multilevel.md),
[`simulate_growth()`](https://mohsaqr.github.io/simulab/reference/simulate_growth.md),
[`simulate_longitudinal()`](https://mohsaqr.github.io/simulab/reference/simulate_longitudinal.md).

Survival:
[`define_survival()`](https://mohsaqr.github.io/simulab/reference/define_survival.md),
[`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md),
[`simulate_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_survival.md),
[`augment_survival()`](https://mohsaqr.github.io/simulab/reference/augment_survival.md),
[`combine_competing_risks()`](https://mohsaqr.github.io/simulab/reference/combine_competing_risks.md),
[`simulate_proportional_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_proportional_survival.md),
[`calibrate_survival()`](https://mohsaqr.github.io/simulab/reference/calibrate_survival.md),
[`survival_curve()`](https://mohsaqr.github.io/simulab/reference/survival_curve.md).

Missingness:
[`define_missingness()`](https://mohsaqr.github.io/simulab/reference/define_missingness.md),
[`define_missingnesses()`](https://mohsaqr.github.io/simulab/reference/define_missingnesses.md),
[`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md),
[`observed_data()`](https://mohsaqr.github.io/simulab/reference/observed_data.md),
[`inject_missingness()`](https://mohsaqr.github.io/simulab/reference/inject_missingness.md).

Treatment and design structure:
[`assign_treatment()`](https://mohsaqr.github.io/simulab/reference/assign_treatment.md),
[`observe_treatment()`](https://mohsaqr.github.io/simulab/reference/observe_treatment.md),
[`assign_stepped_wedge()`](https://mohsaqr.github.io/simulab/reference/assign_stepped_wedge.md),
[`expand_clusters()`](https://mohsaqr.github.io/simulab/reference/expand_clusters.md),
[`expand_periods()`](https://mohsaqr.github.io/simulab/reference/expand_periods.md),
[`factorial_design()`](https://mohsaqr.github.io/simulab/reference/factorial_design.md),
[`augment_factorial()`](https://mohsaqr.github.io/simulab/reference/augment_factorial.md),
[`encode_factors()`](https://mohsaqr.github.io/simulab/reference/encode_factors.md),
[`merge_studies()`](https://mohsaqr.github.io/simulab/reference/merge_studies.md),
[`select_variables()`](https://mohsaqr.github.io/simulab/reference/select_variables.md).

Sequences:
[`simulate_markov()`](https://mohsaqr.github.io/simulab/reference/simulate_markov.md),
[`augment_markov()`](https://mohsaqr.github.io/simulab/reference/augment_markov.md),
[`simulate_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_sequences.md),
[`simulate_sequence_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_clusters.md),
[`simulate_group_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_group_sequences.md),
[`simulate_until_event()`](https://mohsaqr.github.io/simulab/reference/simulate_until_event.md),
[`trim_events()`](https://mohsaqr.github.io/simulab/reference/trim_events.md),
[`summarize_transitions()`](https://mohsaqr.github.io/simulab/reference/summarize_transitions.md),
[`encode_sequences()`](https://mohsaqr.github.io/simulab/reference/encode_sequences.md),
[`generate_transition_system()`](https://mohsaqr.github.io/simulab/reference/generate_transition_system.md),
[`simulate_event_log()`](https://mohsaqr.github.io/simulab/reference/simulate_event_log.md),
[`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md),
[`learning_state_categories()`](https://mohsaqr.github.io/simulab/reference/learning_state_categories.md),
[`sample_learning_states()`](https://mohsaqr.github.io/simulab/reference/sample_learning_states.md).

Transition networks:
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md),
[`as_tna_model()`](https://mohsaqr.github.io/simulab/reference/as_tna_model.md),
[`simulate_group_tna()`](https://mohsaqr.github.io/simulab/reference/simulate_group_tna.md),
[`simulate_tna_network()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_network.md),
[`compare_tna_models()`](https://mohsaqr.github.io/simulab/reference/compare_tna_models.md),
[`bootstrap_tna()`](https://mohsaqr.github.io/simulab/reference/bootstrap_tna.md),
[`sample_tna()`](https://mohsaqr.github.io/simulab/reference/sample_tna.md),
[`cross_validate_tna()`](https://mohsaqr.github.io/simulab/reference/cross_validate_tna.md),
[`assess_tna_reliability()`](https://mohsaqr.github.io/simulab/reference/assess_tna_reliability.md),
[`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md),
[`fit_tna_batch()`](https://mohsaqr.github.io/simulab/reference/fit_tna_batch.md),
[`simulate_tna_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_tna_batches.md).

Networks:
[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md),
[`simulate_edge_list()`](https://mohsaqr.github.io/simulab/reference/simulate_edge_list.md),
[`simulate_temporal_network()`](https://mohsaqr.github.io/simulab/reference/simulate_temporal_network.md),
[`simulate_network_matrix()`](https://mohsaqr.github.io/simulab/reference/simulate_network_matrix.md),
[`simulate_bipartite_network()`](https://mohsaqr.github.io/simulab/reference/simulate_bipartite_network.md),
[`simulate_multiplex_network()`](https://mohsaqr.github.io/simulab/reference/simulate_multiplex_network.md),
[`simulate_network_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_network_batches.md),
[`network_centrality()`](https://mohsaqr.github.io/simulab/reference/network_centrality.md),
[`compare_networks()`](https://mohsaqr.github.io/simulab/reference/compare_networks.md),
[`compare_centralities()`](https://mohsaqr.github.io/simulab/reference/compare_centralities.md),
[`evaluate_edge_recovery()`](https://mohsaqr.github.io/simulab/reference/evaluate_edge_recovery.md),
[`summarize_networks()`](https://mohsaqr.github.io/simulab/reference/summarize_networks.md),
[`as_igraph()`](https://mohsaqr.github.io/simulab/reference/as_igraph.md).

Empirical and functional:
[`simulate_synthetic()`](https://mohsaqr.github.io/simulab/reference/simulate_synthetic.md),
[`augment_synthetic()`](https://mohsaqr.github.io/simulab/reference/augment_synthetic.md),
[`simulate_density()`](https://mohsaqr.github.io/simulab/reference/simulate_density.md),
[`augment_density()`](https://mohsaqr.github.io/simulab/reference/augment_density.md),
[`simulate_spline()`](https://mohsaqr.github.io/simulab/reference/simulate_spline.md),
[`spline_basis()`](https://mohsaqr.github.io/simulab/reference/spline_basis.md),
[`spline_curves()`](https://mohsaqr.github.io/simulab/reference/spline_curves.md),
[`linear_formula()`](https://mohsaqr.github.io/simulab/reference/linear_formula.md),
[`mixture_formula()`](https://mohsaqr.github.io/simulab/reference/mixture_formula.md),
[`categorical_formula()`](https://mohsaqr.github.io/simulab/reference/categorical_formula.md).

Calibration:
[`calibrate_moments()`](https://mohsaqr.github.io/simulab/reference/calibrate_moments.md),
[`calibrate_distribution()`](https://mohsaqr.github.io/simulab/reference/calibrate_distribution.md),
[`calibrate_icc()`](https://mohsaqr.github.io/simulab/reference/calibrate_icc.md),
[`calibrate_logistic()`](https://mohsaqr.github.io/simulab/reference/calibrate_logistic.md).

Workflows:
[`scenario_grid()`](https://mohsaqr.github.io/simulab/reference/scenario_grid.md),
[`simulate_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulate_scenarios.md),
[`parameter_grid()`](https://mohsaqr.github.io/simulab/reference/parameter_grid.md),
[`apply_batch()`](https://mohsaqr.github.io/simulab/reference/apply_batch.md),
[`simulate_sequence_batches()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_batches.md),
[`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md),
[`validate_recovery()`](https://mohsaqr.github.io/simulab/reference/validate_recovery.md),
[`write_simulation()`](https://mohsaqr.github.io/simulab/reference/write_simulation.md),
[`simulation_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulation_scenarios.md),
[`run_simulation_scenario()`](https://mohsaqr.github.io/simulab/reference/run_simulation_scenario.md),
[`list_simulators()`](https://mohsaqr.github.io/simulab/reference/list_simulators.md),
[`simulate_data()`](https://mohsaqr.github.io/simulab/reference/simulate_data.md),
[`global_names()`](https://mohsaqr.github.io/simulab/reference/global_names.md),
[`global_name_regions()`](https://mohsaqr.github.io/simulab/reference/global_name_regions.md),
[`sample_global_names()`](https://mohsaqr.github.io/simulab/reference/sample_global_names.md).

Result methods:
[`components()`](https://mohsaqr.github.io/simulab/reference/components.md),
[`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html),
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html).

## License

MIT. See `LICENSE`.

## Citation

Saqr, M. (2026). simulab: Unified Simulation of Statistical and Study
Data. R package version 0.4.0. <https://github.com/mohsaqr/simulab>
