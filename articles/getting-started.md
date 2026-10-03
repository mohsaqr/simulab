# Simulating Data with Known Parameters in simulab

A simulation study evaluates statistical methods using data generated
under a specified model. Because the generating parameters are known,
estimates can be compared with their target values across repeated
samples. A study therefore requires a defined aim, a data-generating
mechanism, estimands, methods, and performance measures.

`simulab` generates data for a range of statistical models and study
designs. Each simulation result contains the generated data together
with component tables describing its parameters, design, and, where
available, derived population quantities. These components support
comparisons between fitted results and the corresponding generating
values.

The package uses four conventions:

- **Tidy results.** A single-dataset simulation returns a data frame
  that can be passed directly to compatible analysis functions such as
  [`lm()`](https://rdrr.io/r/stats/lm.html),
  [`glm()`](https://rdrr.io/r/stats/glm.html), and
  [`aggregate()`](https://rdrr.io/r/stats/aggregate.html).
- **Accessible generating information.**
  [`components()`](https://mohsaqr.github.io/simulab/reference/components.md)
  lists the tables attached to a result, and
  `as.data.frame(x, what = ...)` extracts a selected component.
- **Local seeds.** Supplying `seed` makes the call reproducible under
  the same random-number settings and restores the session’s previous
  random-number state on return.
- **Replication.** Supplying `batch` requests a list of replicate
  datasets generated with the same model arguments.

Inputs such as transition matrices, factor loadings, and profile means
can be supplied as matrices or tidy tables. Named inputs describing the
same variables, states, or profiles are aligned by their names where
supported. Unnamed inputs follow the positional conventions of the
relevant function.

This vignette introduces the simulation workflow and then describes the
supported model families. Examples specify generating parameters,
inspect the resulting components, and compare selected sample estimates
with their targets. Individual fitted examples illustrate sampling
variation; repeated simulations are needed to evaluate estimator
performance.

``` r

library(simulab)
```

## Part I: The simulation workflow

### Data and parameters

[`simulate_regression()`](https://mohsaqr.github.io/simulab/reference/simulate_regression.md)
generates data from the linear model

``` math
y_i = \beta_0 + \mathbf{x}_i^\top\boldsymbol\beta + \varepsilon_i,
```

where $`\mathbf{x}_i \sim N(\boldsymbol\mu, \boldsymbol\Sigma)`$ and the
errors are independent normal draws with variance $`\sigma^2`$.
`coefficients` supplies the named intercept and slopes.
`predictor_means`, `predictor_sds`, and `correlation` specify the
predictor distribution, while `error_sd` specifies $`\sigma`$. The
defaults give independent standard normal predictors and residual
standard deviation 1.

``` r

regression <- simulate_regression(
  n = 100,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1
)
regression
#> <simulab_sim:regression> 100 rows x 4 columns
#>    id         x1          x2    outcome
#> 1   1 -0.6264538 -0.62036668  1.2822849
#> 2   2  0.1836433  0.04211587  2.7680602
#> 3   3 -0.8356286 -0.91092165  2.4420506
#> 4   4  1.5952808  0.15802877  1.4193240
#> 5   5  0.3295078 -0.65458464 -0.9241063
#> 6   6 -0.8204684  1.76728727  2.5572412
#> 7   7  0.4874291  0.71670748  1.6957685
#> 8   8  0.7383247  0.91017423  1.6374374
#> 9   9  0.5757814  0.38418536  1.1592355
#> 10 10 -0.3053884  1.68217608  0.8527614
#> ... 90 more rows
components(regression)
#>                   table rows columns
#> 1                  data  100       4
#> 2          coefficients    3       2
#> 3               effects    1       3
#> 4 predictor_correlation    4       3
```

The generated data contain `id`, the named predictors, and `outcome`.
The `coefficients` component records the generating coefficients.
`effects` contains the signal variance
$`\boldsymbol\beta^\top\boldsymbol\Sigma\boldsymbol\beta`$, residual
variance $`\sigma^2`$, and population $`R^2`$, calculated as signal
variance divided by total outcome variance. `predictor_correlation`
stores the predictor correlation matrix in tidy format.

``` r

as.data.frame(regression, what = "coefficients")
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
#> 3          x2        -0.3
as.data.frame(regression, what = "effects")
#>   signal_variance residual_variance r_squared
#> 1            0.34                 1 0.2537313
```

With slopes 0.5 and −0.3 and independent standard normal predictors,
signal variance is $`0.5^2 + 0.3^2 = 0.34`$. Residual variance is 1,
giving population $`R^2 = 0.34/1.34 \approx 0.254`$.

### Seeds

A call with the same arguments and `seed` reproduces the dataset under
the same random-number settings. The seeded call restores the preceding
random-number state, so subsequent draws continue from that state.

``` r

set.seed(2024)
state_before <- .Random.seed
again <- simulate_regression(
  n = 100,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1
)
identical(again, regression)
#> [1] TRUE
identical(state_before, .Random.seed)
#> [1] TRUE
```

The two checks return `TRUE`: `again` matches `regression`, and the
session’s random-number state is unchanged by the call. With
`seed = NULL`, simulations use and advance the session’s current
random-number stream.

### Replication and performance measures

Estimator performance concerns behavior across repeated samples.
`batch = 500` requests 500 replicate datasets with the same sample size
and generating parameters. When `seed` is supplied, the batch mechanism
draws a separate seed for each dataset. With `seed = NULL`, datasets use
successive draws from the current random-number stream.

``` r

datasets <- simulate_regression(
  n = 100,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1,
  batch = 500
)
length(datasets)
#> [1] 500
```

[`apply_batch()`](https://mohsaqr.github.io/simulab/reference/apply_batch.md)
applies an analysis function to each dataset and combines its data-frame
outputs, adding `batch_id` to identify the replication. Additional
arguments are passed to the analysis function. Here,
`estimate_coefficients()` fits a linear model and returns its
coefficient estimates in tidy format.

``` r

estimate_coefficients <- function(data, formula) {
  fit <- lm(formula, data = data)
  data.frame(term = names(coef(fit)), estimate = unname(coef(fit)))
}

estimates <- apply_batch(datasets, estimate_coefficients, formula = outcome ~ x1 + x2)
head(estimates)
#>   batch_id        term   estimate
#> 1        1 (Intercept)  0.9921637
#> 2        1          x1  0.4973782
#> 3        1          x2 -0.4061121
#> 4        2 (Intercept)  1.0071737
#> 5        2          x1  0.5316143
#> 6        2          x2 -0.4862266
```

[`validate_recovery()`](https://mohsaqr.github.io/simulab/reference/validate_recovery.md)
matches estimates to their generating values by `term`. It reports the
signed estimation error in `bias`, its magnitude in `absolute_error`,
and whether that magnitude is within `tolerance` in `recovered`. The
`bias` column contains individual estimation errors; their mean across
replications estimates statistical bias. `true_value = "coefficient"`
identifies the generating-value column in `truth`.

``` r

truth <- as.data.frame(regression, what = "coefficients")
recovery <- validate_recovery(estimates, truth, true_value = "coefficient", tolerance = 0.2)
head(recovery)
#>   batch_id        term   estimate truth         bias absolute_error
#> 1        1 (Intercept)  0.9921637   1.0 -0.007836287    0.007836287
#> 2        1          x1  0.4973782   0.5 -0.002621787    0.002621787
#> 3        1          x2 -0.4061121  -0.3 -0.106112128    0.106112128
#> 4        2 (Intercept)  1.0071737   1.0  0.007173665    0.007173665
#> 5        2          x1  0.5316143   0.5  0.031614277    0.031614277
#> 6        2          x2 -0.4862266  -0.3 -0.186226618    0.186226618
#>   relative_error recovered
#> 1   -0.007836287      TRUE
#> 2   -0.005243574      TRUE
#> 3    0.353707094      TRUE
#> 4    0.007173665      TRUE
#> 5    0.063228554      TRUE
#> 6    0.620755393      TRUE
```

[`summarize_simulations()`](https://mohsaqr.github.io/simulab/reference/summarize_simulations.md)
reports the non-missing count, mean, standard deviation, minimum, and
maximum of selected numeric variables. Grouping by `term` summarizes
each coefficient across replications. The mean of `bias` estimates bias,
and the standard deviation of `estimate` estimates the sampling standard
deviation, often called the empirical standard error.

``` r

summarize_simulations(recovery, by = "term", variables = c("estimate", "bias"))
#>          term variable observations         mean        sd    minimum   maximum
#> 1 (Intercept) estimate          500  1.004524666 0.1003488  0.6869128 1.3106459
#> 2 (Intercept)     bias          500  0.004524666 0.1003488 -0.3130872 0.3106459
#> 3          x1 estimate          500  0.501262413 0.1018302  0.2149156 0.8985527
#> 4          x1     bias          500  0.001262413 0.1018302 -0.2850844 0.3985527
#> 5          x2 estimate          500 -0.301266961 0.1003781 -0.5668912 0.0682355
#> 6          x2     bias          500 -0.001266961 0.1003781 -0.2668912 0.3682355
```

The mean slope estimates are approximately 0.501 and −0.301. Their
estimated biases are 0.0013 and −0.0013. The Monte Carlo standard error
of each estimated bias is the corresponding empirical standard error
divided by $`\sqrt{500}`$, approximately 0.0045. The estimated biases
are small relative to this simulation uncertainty.

The empirical standard errors are 0.102 and 0.100. These are close to
the approximation $`\sigma/\sqrt{n} = 0.1`$ for independent
unit-variance predictors; exact model-based standard errors also depend
on the realized predictor values.

Increasing the sample size from 100 to 400 provides a second simulation
condition. Under the same generating model, standard errors are expected
to decrease by approximately half.

``` r

larger <- simulate_regression(
  n = 400,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1,
  batch = 500
)
larger_recovery <- validate_recovery(
  apply_batch(larger, estimate_coefficients, formula = outcome ~ x1 + x2),
  truth,
  true_value = "coefficient",
  tolerance = 0.2
)
summarize_simulations(larger_recovery, by = "term", variables = "bias")
#>          term variable observations         mean         sd    minimum
#> 1 (Intercept)     bias          500 -0.002911290 0.05148512 -0.1463768
#> 2          x1     bias          500  0.001310449 0.04983413 -0.2022521
#> 3          x2     bias          500  0.003157642 0.04863093 -0.1472518
#>     maximum
#> 1 0.1553902
#> 2 0.1385956
#> 3 0.1412823
```

The resulting slope standard errors are approximately 0.050 and 0.049.
Because the generating coefficient is fixed across replications, the
standard deviation of `bias` equals that of `estimate` for each term.
[`scenario_grid()`](https://mohsaqr.github.io/simulab/reference/scenario_grid.md)
constructs designs that vary several arguments, and
[`simulate_scenarios()`](https://mohsaqr.github.io/simulab/reference/simulate_scenarios.md)
applies a simulator to the resulting conditions.

## Part II: Specifying a mechanism

### Variables as distributions

[`define_variables()`](https://mohsaqr.github.io/simulab/reference/define_variables.md)
specifies variables through named distribution calls. Distribution
parameters may depend on variables defined earlier in the specification.
This permits conditional models with explicit links between variables.

In the following example, age is normally distributed. Treatment uptake
follows a logistic model of age, visit counts follow a Poisson model
with a log link, and the outcome mean depends on age and treatment.
[`simulate_study()`](https://mohsaqr.github.io/simulab/reference/simulate_study.md)
generates observations from the specification.

``` r

specification <- define_variables(
  age     = normal(mean = 50, sd = 10),
  treated = binary(prob = plogis(-2 + 0.04 * age)),
  visits  = poisson(lambda = exp(0.5 + 0.02 * age)),
  outcome = normal(mean = 10 + 0.2 * age + 2 * treated, sd = 2)
)

study <- simulate_study(n = 1000, specification = specification, seed = 42)
head(study)
#> <simulab_sim:study> 6 rows x 5 columns
#>   id      age treated visits  outcome
#> 1  1 63.70958       0      4 23.24307
#> 2  2 44.35302       0      7 18.31476
#> 3  3 53.63128       0      4 17.27679
#> 4  4 56.32863       0      5 17.25232
#> 5  5 54.04268       0      3 18.22492
#> 6  6 48.93875       1      5 22.51943
as.data.frame(study, what = "definitions")
#>   variable distribution parameter                        value
#> 1      age       normal      mean                           50
#> 2      age       normal        sd                           10
#> 3  treated       binary      prob      plogis(-2 + 0.04 * age)
#> 4   visits      poisson    lambda        exp(0.5 + 0.02 * age)
#> 5  outcome       normal      mean 10 + 0.2 * age + 2 * treated
#> 6  outcome       normal        sd                            2
```

The `definitions` component records the supplied parameter expressions.
The following models estimate the coefficients used to generate
treatment uptake and visit counts.

``` r

coef(glm(treated ~ age, family = binomial, data = study))
#> (Intercept)         age 
#> -1.78449485  0.03678837
coef(glm(visits ~ age, family = poisson, data = study))
#> (Intercept)         age 
#>  0.48526262  0.02077051
```

The estimated age coefficient is approximately 0.037 for treatment
uptake, compared with the generating value 0.04. The estimated
log-linear coefficient for visits is 0.021, compared with 0.02. These
differences reflect sampling variation in this dataset.

[`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
lists the available distributions and their parameters, including the
parameter order used in positional calls.

``` r

head(list_distributions())
#>    distribution            parameters n_parameters copula
#> 1        anglit       location, scale            2   TRUE
#> 2       arcsine              min, max            2   TRUE
#> 3        benini shape1, shape2, scale            3   TRUE
#> 4          beta        shape1, shape2            2   TRUE
#> 5 beta_binomial  size, shape1, shape2            3  FALSE
#> 6    beta_prime        shape1, shape2            2   TRUE
```

### Missing data

Missingness is classified by its dependence on the data. Under missing
completely at random (MCAR), missingness is independent of data values.
Under missing at random (MAR), missingness can depend on observed values
but is conditionally independent of missing values given the observed
data. Missing not at random (MNAR) allows dependence on values that are
unobserved.

[`inject_missingness()`](https://mohsaqr.github.io/simulab/reference/inject_missingness.md)
replaces selected values with `NA` under these mechanisms. For its MAR
option, a fully observed `predictor` determines missingness
probabilities through its ranked values. The probabilities are
calibrated to average `proportion`; the realized proportion varies
because removal is stochastic.

``` r

incomplete <- inject_missingness(
  study,
  mechanism = "MAR",
  proportion = 0.3,
  variables = "outcome",
  predictor = "age",
  seed = 7
)
as.data.frame(incomplete, what = "missingness_summary")
#>   variable realized_proportion target_proportion
#> 1  outcome               0.308               0.3
summarize_simulations(study, variables = "outcome")
#>   variable observations     mean       sd  minimum  maximum
#> 1  outcome         1000 20.96394 3.111055 10.46787 30.26189
summarize_simulations(incomplete, variables = "outcome")
#>   variable observations    mean       sd  minimum  maximum
#> 1  outcome          692 20.3551 3.077688 10.46787 29.75574
```

The realized missing proportion is 30.8%, compared with the target of
30%. Older participants have higher missingness probabilities, and age
is positively associated with the generated outcome. The mean among
observed outcomes is consequently lower in this sample: 20.36 compared
with 20.96 before removal. This example illustrates how an unadjusted
observed-data mean can be biased under MAR; MAR alone does not make
every complete-case analysis unbiased.

The `missingness` component records each targeted cell’s probability and
missingness indicator. `missingness_summary` reports target and realized
proportions.
[`define_missingness()`](https://mohsaqr.github.io/simulab/reference/define_missingness.md)
and
[`missingness_matrix()`](https://mohsaqr.github.io/simulab/reference/missingness_matrix.md)
support specifications expressed through formulas.

### Treatment assignment

[`assign_treatment()`](https://mohsaqr.github.io/simulab/reference/assign_treatment.md)
randomly allocates observations to treatment groups, optionally within
strata. Random allocation controls the assignment mechanism; finite
samples can still differ in their covariate distributions.

``` r

trial <- assign_treatment(study, groups = 2, strata = "treated", name = "arm", seed = 3)
as.data.frame(trial, what = "allocation")
#>   stratum treatment observations
#> 1       0         0          245
#> 2       1         0          256
#> 3       0         1          244
#> 4       1         1          255
```

With the default balanced allocation and equal group ratios,
observations are divided as evenly as possible within each `treated`
stratum. The new assignment is stored in `arm`, and the `allocation`
component records the allocation.

[`observe_treatment()`](https://mohsaqr.github.io/simulab/reference/observe_treatment.md)
generates exposure from specified probabilities. With `link = "logit"`,
the supplied expression defines log odds. Here, exposure becomes more
likely with increasing age.

``` r

observed <- observe_treatment(
  study,
  formulas = "-3 + 0.05 * age",
  link = "logit",
  name = "exposed",
  seed = 3
)
summarize_simulations(observed, by = "exposed", variables = "age")
#>   exposed variable observations     mean        sd  minimum  maximum
#> 1       0      age          613 48.03767  9.494049 19.82067 76.23495
#> 2       1      age          387 52.44100 10.260949 16.28261 84.95304
```

Exposed participants have mean age 52.4 years, compared with 48.0 among
unexposed participants. This covariate imbalance is relevant when age
also predicts the outcome, as it does in `study`. The `probabilities`
component retains the generating exposure probabilities for evaluating
propensity-score estimation. Adding `exposed` does not regenerate the
existing outcome or introduce an exposure effect into it.

## Part III: Group comparisons and correlated data

### Group designs

[`simulate_ttest()`](https://mohsaqr.github.io/simulab/reference/simulate_ttest.md)
and
[`simulate_anova()`](https://mohsaqr.github.io/simulab/reference/simulate_anova.md)
generate normal outcomes for groups with specified sample sizes, means,
and standard deviations. Their component tables record the group
parameters and derived effect summaries.

``` r

groups <- simulate_anova(
  n = c(40, 40, 40),
  means = c(10, 11, 12.5),
  sds = 2,
  labels = c("control", "low", "high"),
  seed = 1
)
as.data.frame(groups, what = "effects")
#>   grand_mean between_sum_squares within_sum_squares eta_squared
#> 1   11.16667            126.6667                468   0.2130045
summary(aov(outcome ~ group, data = groups))
#>              Df Sum Sq Mean Sq F value   Pr(>F)    
#> group         2  131.3   65.64   20.77 1.91e-08 ***
#> Residuals   117  369.8    3.16                     
#> ---
#> Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

For this design, `effects` reports `eta_squared = 0.213`. The package
calculates this quantity from the specified group sizes and parameters
as $`B/(B+W)`$, where $`B = \sum_g n_g(\mu_g-\bar\mu)^2`$ and
$`W = \sum_g(n_g-1)\sigma_g^2`$. Here, $`B`$ is approximately 126.7 and
$`W`$ is 468. This is the function’s design-based effect summary; its
use of $`n_g-1`$ distinguishes it from a population variance ratio
weighted by group proportions.

The fitted ANOVA gives sample sums of squares of approximately 131.3
between groups and 369.8 within groups. Their ratio gives sample
$`\eta^2 \approx 0.262`$.

### Correlation structures

[`simulate_correlated()`](https://mohsaqr.github.io/simulab/reference/simulate_correlated.md)
generates multivariate normal observations with specified means,
standard deviations, and correlation structure. With
`structure = "ar1"`, correlations follow $`\rho^{|i-j|}`$, decreasing
with the separation between variable positions when $`0 < \rho < 1`$.

``` r

correlated <- simulate_correlated(
  n = 2000,
  means = c(t1 = 0, t2 = 0, t3 = 0, t4 = 0),
  rho = 0.6,
  structure = "ar1",
  seed = 1
)
round(cor(subset(correlated, select = -id)), 2)
#>      t1   t2   t3   t4
#> t1 1.00 0.61 0.34 0.18
#> t2 0.61 1.00 0.55 0.33
#> t3 0.34 0.55 1.00 0.59
#> t4 0.18 0.33 0.59 1.00
```

With $`\rho = 0.6`$, generating correlations are 0.6, 0.36, and 0.216 at
separations of one, two, and three positions. Sample correlations range
from 0.55 to 0.61 at separation one, are 0.33 and 0.34 at separation
two, and are 0.18 at separation three.
`as.data.frame(correlated, what = "correlation")` extracts the
generating correlation matrix in tidy format.

### Non-normal margins with a Gaussian copula

A copula represents dependence separately from marginal distributions.
[`simulate_copula()`](https://mohsaqr.github.io/simulab/reference/simulate_copula.md)
generates latent normal variables
$`\mathbf{z} \sim N(\mathbf{0}, \mathbf{R})`$, transforms them to
uniform variables using the standard normal distribution function
$`\Phi`$, and applies each specified marginal quantile function.

``` r

copula <- simulate_copula(
  n = 2000,
  specification = define_variables(
    score  = normal(mean = 10, sd = 2),
    visits = poisson(lambda = 4),
    rate   = beta(shape1 = 2, shape2 = 5)
  ),
  rho = 0.6,
  seed = 1
)
head(copula, 3)
#> <simulab_sim:copula> 3 rows x 4 columns
#>   id    score visits       rate
#> 1  1 7.706109      2 0.07629022
#> 2  2 9.679819      1 0.30106191
#> 3  3 9.711422      7 0.40336193
round(cor(subset(copula, select = -id), method = "spearman"), 2)
#>        score visits rate
#> score   1.00   0.58 0.57
#> visits  0.58   1.00 0.52
#> rate    0.57   0.52 1.00
```

`rho = 0.6` specifies correlation between the latent normal variables.
The `latent_correlation` component records this matrix. Correlations
among the generated variables depend on their marginal distributions and
need not equal the latent correlations.

For continuous margins, latent normal correlation 0.6 implies Spearman
correlation $`(6/\pi)\arcsin(0.3) \approx 0.58`$. The sample correlation
between the normal and beta variables is 0.57. Correlations involving
the Poisson variable are 0.58 and 0.52. Because the Poisson margin is
discrete, ties affect rank correlation and the continuous-margin formula
does not apply directly.

### Ordinal variables

[`simulate_ordinal()`](https://mohsaqr.github.io/simulab/reference/simulate_ordinal.md)
generates correlated latent normal variables and divides their values
into categories using thresholds determined by the requested category
probabilities. This corresponds to the latent-variable model used for
polychoric correlation.

``` r

ordinal <- simulate_ordinal(
  n = 2000,
  probabilities = c(0.2, 0.3, 0.3, 0.2),
  n_variables = 2,
  rho = 0.7,
  seed = 1
)
head(ordinal, 3)
#> <simulab_sim:ordinal> 3 rows x 3 columns
#>   id V1 V2
#> 1  1  1  1
#> 2  2  2  1
#> 3  3  2  4
cor(subset(ordinal, select = -id))
#>           V1        V2
#> V1 1.0000000 0.6583364
#> V2 0.6583364 1.0000000
```

The generating latent correlation is 0.7, while the sample Pearson
correlation of the category codes is 0.658. These correlations describe
different quantities: one concerns latent continuous variables, and the
other concerns their observed ordinal codes. A polychoric estimator
targets the latent correlation under the model’s assumptions.

## Part IV: Latent variable and measurement models

### Common factors

[`simulate_factors()`](https://mohsaqr.github.io/simulab/reference/simulate_factors.md)
generates observations from the common factor model

``` math
\mathbf{x} = \boldsymbol\tau + \boldsymbol\Lambda\boldsymbol\eta + \boldsymbol\varepsilon.
```

Factors have unit variance and correlation matrix $`\boldsymbol\Phi`$.
With independent measurement errors having covariance matrix
$`\boldsymbol\Psi`$, the implied observation covariance is
$`\boldsymbol\Lambda\boldsymbol\Phi\boldsymbol\Lambda^\top + \boldsymbol\Psi`$.

By default, the function sets each uniqueness to
$`1-\sum_k\lambda_{jk}^2`$. This gives unit indicator variances in the
simple structure below, where each indicator loads on only one factor.
It does not generally produce unit variances when an indicator loads on
multiple correlated factors.

``` r

loadings <- matrix(
  c(0.8, 0.7, 0.6, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.7, 0.6, 0.5),
  ncol = 2,
  dimnames = list(paste0("item_", 1:6), c("verbal", "numeric"))
)
factor_data <- simulate_factors(
  n = 1000,
  loadings = loadings,
  factor_correlation = matrix(c(1, 0.3, 0.3, 1), 2),
  seed = 1
)
head(as.data.frame(factor_data, what = "parameters"), 4)
#>   variable factor loading uniqueness intercept
#> 1   item_1 verbal     0.8       0.36         0
#> 2   item_2 verbal     0.7       0.51         0
#> 3   item_3 verbal     0.6       0.64         0
#> 4   item_4 verbal     0.0       0.51         0
```

The `parameters` component records loadings, uniquenesses, and
intercepts. Maximum-likelihood factor analysis with an oblique rotation
can then be used to examine recovery of the loading pattern.

``` r

fit <- factanal(subset(factor_data, select = -id), factors = 2, rotation = "promax")
round(unclass(loadings(fit)), 2)
#>        Factor1 Factor2
#> item_1    0.78    0.01
#> item_2    0.75   -0.03
#> item_3    0.58    0.00
#> item_4   -0.02    0.72
#> item_5    0.00    0.61
#> item_6    0.03    0.47
```

Estimated primary loadings are approximately 0.78, 0.75, and 0.58 on the
first factor and 0.72, 0.61, and 0.47 on the second. The generating
values are 0.8, 0.7, and 0.6, and 0.7, 0.6, and 0.5, respectively.
Estimated cross-loadings are within 0.03 of zero. Comparisons of factor
solutions should account for arbitrary factor ordering and signs.

### Item response theory

[`simulate_irt()`](https://mohsaqr.github.io/simulab/reference/simulate_irt.md)
generates latent abilities and item responses. In the unidimensional
two-parameter logistic model, $`\theta \sim N(0,1)`$ and the probability
of a correct response to item $`j`$ is

``` math
P(Y_j=1\mid\theta)=\operatorname{logit}^{-1}\{a_j(\theta-b_j)\},
```

where $`b_j`$ is item difficulty and $`a_j`$ is discrimination.
`model = "rasch"` fixes discrimination at 1, `"3pl"` adds a guessing
parameter, and `"graded"` generates ordered responses using the graded
response model.

``` r

irt <- simulate_irt(
  n = 2000,
  discrimination = c(0.8, 1.2, 1.5, 1, 2),
  difficulty = c(-1.5, -0.5, 0, 0.5, 1.5),
  seed = 1
)
as.data.frame(irt, what = "parameters")
#>     item  parameter category value discrimination guessing
#> 1 item_1 difficulty       NA  -1.5            0.8        0
#> 2 item_2 difficulty       NA  -0.5            1.2        0
#> 3 item_3 difficulty       NA   0.0            1.5        0
#> 4 item_4 difficulty       NA   0.5            1.0        0
#> 5 item_5 difficulty       NA   1.5            2.0        0
summarize_simulations(subset(irt, select = -id))
#>   variable observations   mean        sd minimum maximum
#> 1   item_1         2000 0.7185 0.4498432       0       1
#> 2   item_2         2000 0.6160 0.4864795       0       1
#> 3   item_3         2000 0.5120 0.4999810       0       1
#> 4   item_4         2000 0.3905 0.4879844       0       1
#> 5   item_5         2000 0.1320 0.3385754       0       1
```

Across these items, the sample proportion correct decreases from
approximately 0.72 to 0.13 as difficulty increases. For the item with
difficulty 0, symmetry of the ability distribution gives marginal
response probability 0.5 under this two-parameter model. The sample
proportion is 0.512. The `parameters` component records item parameters,
and `abilities` contains the generated latent abilities.

### Latent profiles

[`simulate_lpa()`](https://mohsaqr.github.io/simulab/reference/simulate_lpa.md)
generates a finite mixture of multivariate normal distributions. Each
observation is assigned to a profile according to its probability, and
its indicators are generated using that profile’s means, standard
deviations, and correlations. Profile means can be supplied in tidy
format using `profile`, `variable`, and `mean`.

``` r

means <- data.frame(
  profile  = rep(c("low", "average", "high"), each = 3),
  variable = rep(c("effort", "planning", "reflection"), times = 3),
  mean     = c(-1, -1, -0.5,  0, 0, 0,  1.2, 1, 1.5)
)
profiles <- simulate_lpa(n = 600, means = means, proportions = c(0.25, 0.5, 0.25), seed = 1)
head(profiles, 3)
#> <simulab_sim:lpa> 3 rows x 5 columns
#>   id profile    effort  planning reflection
#> 1  1 average 1.1948510 -1.010465  -1.113169
#> 2  2 average 0.4955447  2.401222  -1.405505
#> 3  3    high 1.1180083  1.207912   1.170042
summarize_simulations(profiles, by = "profile", variables = "effort")
#>   profile variable observations         mean       sd   minimum   maximum
#> 1 average   effort          314  0.001224158 1.056226 -2.996949 3.0557424
#> 2    high   effort          140  1.155264445 1.131875 -1.349107 4.3539714
#> 3     low   effort          146 -0.979527540 1.015811 -4.008049 0.9713374
```

The result includes the generated `profile` membership, which provides a
reference for evaluating classification by a fitted mixture model. Mean
effort is approximately −0.98, 0.00, and 1.16 in the three profiles,
compared with generating means −1, 0, and 1.2. Estimated class labels
must be aligned with generating labels before classification is
compared.

### Latent classes

[`simulate_lca()`](https://mohsaqr.github.io/simulab/reference/simulate_lca.md)
generates categorical indicators from a latent class model.
Class-specific response probabilities determine each indicator’s
distribution. Indicators are conditionally independent given class
membership, the local-independence assumption.

``` r

item_probabilities <- data.frame(
  class       = rep(c("engaged", "disengaged"), each = 6),
  indicator   = rep(rep(c("attends", "submits", "posts"), each = 2), times = 2),
  category    = rep(c("no", "yes"), times = 6),
  probability = c(0.1, 0.9,  0.2, 0.8,  0.4, 0.6,
                  0.6, 0.4,  0.7, 0.3,  0.9, 0.1)
)
classes <- simulate_lca(n = 500, probabilities = item_probabilities,
                        proportions = c(0.6, 0.4), seed = 1)
head(classes, 3)
#> <simulab_sim:lca> 3 rows x 5 columns
#>   id latent_class attends submits posts
#> 1  1      engaged     yes     yes   yes
#> 2  2      engaged     yes     yes    no
#> 3  3      engaged     yes     yes   yes
xtabs(~ latent_class + attends, data = classes)
#>             attends
#> latent_class  no yes
#>   disengaged 102  86
#>   engaged     36 276
```

The generating probability of attendance is 0.9 in the engaged class and
0.4 in the disengaged class. In this sample, 276 of 312 engaged
participants attend, approximately 0.88, compared with 86 of 188
disengaged participants, approximately 0.46. The supplied class
proportions describe sampling probabilities, so realized class sizes can
vary.

### Two-level latent profiles

[`simulate_ml_lpa()`](https://mohsaqr.github.io/simulab/reference/simulate_ml_lpa.md)
generates individuals nested within clusters. Each cluster is assigned a
latent cluster class, which determines the probabilities of individual
profile membership. Profiles share a common measurement model across
cluster classes, while their prevalence varies.

``` r

nested <- simulate_ml_lpa(
  clusters = 40,
  cluster_size = 25,
  means = means,
  profile_probabilities = data.frame(
    cluster_class = rep(c("mostly_low", "mostly_high"), each = 3),
    profile       = rep(c("low", "average", "high"), times = 2),
    probability   = c(0.6, 0.3, 0.1,  0.1, 0.3, 0.6)
  ),
  seed = 1
)
head(nested, 3)
#> <simulab_sim:ml_lpa> 3 rows x 7 columns
#>   id cluster cluster_class profile   effort planning reflection
#> 1  1       1   mostly_high    high 1.760049 1.234904  3.3405227
#> 2  2       1   mostly_high    high 1.342451 1.701258 -0.4621991
#> 3  3       1   mostly_high    high 3.029672 2.326598  0.4338980
xtabs(~ cluster_class + profile, data = nested)
#>              profile
#> cluster_class average high low
#>   mostly_high     154  314  57
#>   mostly_low      129   58 288
```

The `mostly_low` cluster class assigns profile probabilities 0.6, 0.3,
and 0.1 to `low`, `average`, and `high`. The `mostly_high` class uses
0.1, 0.3, and 0.6. The cross-tabulation reports realized memberships
among the forty clusters of 25 individuals. The `clusters` component
records each cluster’s generated class.

## Part V: Multilevel and longitudinal data

### Random intercepts

[`simulate_multilevel()`](https://mohsaqr.github.io/simulab/reference/simulate_multilevel.md)
generates clustered outcomes with fixed effects, random intercepts, and
optional random slopes. For the random-intercept model used here,

``` math
y_{ij}=\gamma_0+\gamma_1x_{ij}+u_j+e_{ij},
```

where $`u_j\sim N(0,\tau^2)`$ and $`e_{ij}\sim N(0,\sigma^2)`$.
Conditional on the fixed predictors, the intraclass correlation is
$`\tau^2/(\tau^2+\sigma^2)`$. It measures the correlation attributable
to shared cluster membership under this model.

[`calibrate_icc()`](https://mohsaqr.github.io/simulab/reference/calibrate_icc.md)
calculates the random-intercept variance needed for a specified ICC and
within-cluster variance.

``` r

calibrate_icc(icc = 0.2, distribution = "normal", within_variance = 1)
#>   icc distribution random_effect_variance
#> 1 0.2       normal                   0.25
```

With target ICC 0.2 and within-cluster variance 1, the required
random-intercept variance is 0.25, corresponding to standard deviation
0.5.

``` r

multilevel <- simulate_multilevel(
  clusters = 50,
  cluster_size = 20,
  intercept = 50,
  slopes = c(hours = 2),
  random_intercept_sd = 0.5,
  residual_sd = 1,
  seed = 1
)
head(multilevel, 3)
#> <simulab_sim:multilevel> 3 rows x 4 columns
#>   id cluster       hours  outcome
#> 1  1       1 -0.62036668 48.68794
#> 2  2       1  0.04211587 48.63825
#> 3  3       1 -0.91092165 49.35484
as.data.frame(multilevel, what = "variance_components")
#>          component variance
#> 1 random_intercept     0.25
#> 2     random_slope     0.00
#> 3         residual     1.00
```

The example generates fifty clusters with twenty observations each.
`variance_components` records the generating variances, and
`random_effects` contains the realized cluster effects. The ICC
describes residual clustering after accounting for the fixed predictor;
variation explained by `hours` is not included in its denominator.

### Growth curves

[`simulate_growth()`](https://mohsaqr.github.io/simulab/reference/simulate_growth.md)
generates repeated outcomes around individual trajectories. With a
linear trajectory,

``` math
y_{ti}=(\beta_0+b_{0i})+(\beta_1+b_{1i})t+e_{ti},
```

where $`b_{0i}`$ and $`b_{1i}`$ are normal random effects. An optional
quadratic term allows curvature in the mean trajectory.

``` r

growth <- simulate_growth(
  n = 200,
  times = 0:4,
  intercept = 10,
  slope = 1.5,
  random_sd = c(2, 0.5),
  seed = 1
)
aggregate(outcome ~ time, data = growth, FUN = mean)
#>   time  outcome
#> 1    0 10.02925
#> 2    1 11.49174
#> 3    2 13.11879
#> 4    3 14.55091
#> 5    4 16.18706
```

The generating mean trajectory is $`10+1.5t`$. Sample means increase
from approximately 10.03 at time 0 to 16.19 at time 4, compared with
generating means 10 and 16. Individual trajectories vary around this
mean according to their random effects and residual variation.

### Vector autoregression

[`simulate_longitudinal()`](https://mohsaqr.github.io/simulab/reference/simulate_longitudinal.md)
generates intensive longitudinal data from a first-order vector
autoregression. With the default zero intercept, the process is

``` math
\mathbf{y}_{it}=\boldsymbol\mu_i+\mathbf{A}(\mathbf{y}_{i,t-1}-\boldsymbol\mu_i)+\boldsymbol\varepsilon_{it},
```

where person means $`\boldsymbol\mu_i`$ may vary according to the
specified between-person covariance. `transition` supplies the lagged
coefficients. In tidy input, `from` identifies the predictor at the
previous occasion and `to` identifies the outcome at the current
occasion.

``` r

lagged_effects <- data.frame(
  from        = c("mood", "mood", "stress", "stress"),
  to          = c("mood", "stress", "mood", "stress"),
  coefficient = c(0.5, 0, -0.2, 0.4)
)
experience <- simulate_longitudinal(
  n = 50,
  occasions = 40,
  transition = lagged_effects,
  seed = 1
)
head(experience, 3)
#> <simulab_sim:longitudinal_var> 3 rows x 4 columns
#>   id occasion       mood     stress
#> 1  1        1 -1.3004499  0.7078784
#> 2  1        2 -0.4608929  1.8697398
#> 3  1        3 -3.1020560 -1.5373396
as.data.frame(experience, what = "transition")
#>      row column coefficient
#> 1   mood   mood         0.5
#> 2 stress   mood         0.0
#> 3   mood stress        -0.2
#> 4 stress stress         0.4
```

Mood has an autoregressive coefficient of 0.5, and stress has an
autoregressive coefficient of 0.4. Previous stress predicts current mood
with coefficient −0.2, while the reverse cross-lagged coefficient is
zero.

In the extracted `transition` component, matrix rows identify predicted
variables and columns identify lagged predictors, consistent with
$`\mathbf{A}`$. The `wide` component stores repeated measurements by
person. Setting `beeps_per_day` adds day and beep identifiers and
restarts the within-day process at day boundaries, so it also changes
how observations are generated across days.

## Part VI: Survival data

### Proportional hazards

[`simulate_proportional_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_proportional_survival.md)
generates event times from

``` math
h(t\mid\mathbf{x})=h_0(t)\exp(\mathbf{x}^\top\boldsymbol\beta).
```

For a Weibull baseline with cumulative hazard $`H_0(t)=\lambda t^k`$,
inverse transformation gives

``` math
T=\left\{\frac{-\log U}{\lambda\exp(\mathbf{x}^\top\boldsymbol\beta)}\right\}^{1/k},\qquad U\sim U(0,1).
```

The function draws exponential censoring times. Their rate is calibrated
so that the mean censoring probability across the generated event times
equals `censoring`; the realized censored proportion can differ from
this target.

``` r

survival_data <- simulate_proportional_survival(
  n = 2000,
  coefficients = c(treatment = -0.5, age = 0.3),
  baseline = "weibull",
  rate = 0.05,
  shape = 1.5,
  censoring = 0.3,
  seed = 1
)
head(survival_data, 3)
#> <simulab_sim:proportional_survival> 3 rows x 5 columns
#>   id      time status  treatment        age
#> 1  1 11.534176      1 -0.6264538 -0.8861496
#> 2  2  6.293952      0  0.1836433 -1.9222549
#> 3  3  1.606610      1 -0.8356286  1.6197007
as.data.frame(survival_data, what = "parameters")
#>             term       value
#> 1      treatment -0.50000000
#> 2            age  0.30000000
#> 3  baseline_rate  0.05000000
#> 4          shape  1.50000000
#> 5 censoring_rate  0.05612131
as.data.frame(survival_data, what = "diagnostics")
#>   target_censoring realized_censoring baseline
#> 1              0.3             0.3115  weibull
```

The coefficients are log hazard ratios. Covariates are standard normal
by default, including the variable named `treatment` in this example.
Its name does not make it binary; `covariate_distribution = "binary"`
selects binary covariates.

The realized censored proportion is 31.2%, compared with the target of
30%. `parameters` records the coefficients and hazard parameters, and
`diagnostics` reports target and realized censoring. A Cox model
estimates the covariate coefficients from the observed times and event
indicators.

``` r

coef(survival::coxph(survival::Surv(time, status) ~ treatment + age, data = survival_data))
#>  treatment        age 
#> -0.4636587  0.3135970
```

The estimates are approximately −0.464 and 0.314, compared with
generating values −0.5 and 0.3. They describe changes in log hazard for
a one-unit increase in the corresponding covariate.

### Competing risks

[`define_survivals()`](https://mohsaqr.github.io/simulab/reference/define_survivals.md)
specifies cause-specific event-time models, and
[`simulate_survival()`](https://mohsaqr.github.io/simulab/reference/simulate_survival.md)
generates their latent event times.
[`combine_competing_risks()`](https://mohsaqr.github.io/simulab/reference/combine_competing_risks.md)
selects the earliest time and its event type. An event named in `censor`
is treated as censoring.

``` r

latent_times <- simulate_survival(
  n = 500,
  specification = define_survivals(
    relapse = hazard(log_rate = -3 + 0.5 * treatment),
    dropout = hazard(log_rate = -3.5)
  ),
  covariates = data.frame(id = 1:500, treatment = rep(0:1, each = 250)),
  seed = 1
)
observed_times <- combine_competing_risks(latent_times, events = c("relapse", "dropout"),
                                          censor = "dropout")
head(observed_times, 3)
#> <simulab_sim:competing_risks> 3 rows x 5 columns
#>   id treatment      time event event_type
#> 1  1         0 11.855911     1    relapse
#> 2  2         0  7.503283     1    relapse
#> 3  3         0  8.405052     1    relapse
as.data.frame(observed_times, what = "events")
#>   event_type event_code censoring
#> 1    dropout          0      TRUE
#> 2    relapse          1     FALSE
xtabs(~ treatment + event_type, data = observed_times)
#>          event_type
#> treatment dropout relapse
#>         0      97     153
#>         1      67     183
```

The `events` component maps dropout to code 0 and relapse to code 1.
Because dropout is designated as censoring, this example yields a
relapse outcome subject to dropout censoring. The generating treatment
coefficient 0.5 multiplies the relapse hazard by $`e^{0.5}\approx1.65`$.
Relapse occurs first for 183 of 250 treated participants and 153 of 250
untreated participants in this sample.

## Part VII: Sequences and transition networks

### Markov chains

[`simulate_markov()`](https://mohsaqr.github.io/simulab/reference/simulate_markov.md)
generates sequences from a first-order Markov model, in which the next
state depends on the current state through
$`P(X_t=j\mid X_{t-1}=i)=p_{ij}`$. The transition probabilities may be
supplied in tidy format using `from`, `to`, and `probability`.

``` r

regulation <- data.frame(
  from        = rep(c("plan", "execute", "monitor"), each = 3),
  to          = rep(c("plan", "execute", "monitor"), times = 3),
  probability = c(0.2, 0.7, 0.1,  0.1, 0.5, 0.4,  0.4, 0.3, 0.3)
)
sequences <- simulate_markov(n = 500, transition = regulation, chain_length = 20,
                             initial = "plan", seed = 1)
head(sequences, 3)
#> <simulab_sim:markov> 3 rows x 3 columns
#>   id period   state
#> 1  1      1    plan
#> 2  1      2 execute
#> 3  1      3 monitor
summarize_transitions(sequences)
#>      from      to count probability
#> 1 execute execute  2253  0.50155833
#> 2 execute monitor  1759  0.39158504
#> 3 execute    plan   480  0.10685663
#> 4 monitor execute   787  0.30386100
#> 5 monitor monitor   758  0.29266409
#> 6 monitor    plan  1045  0.40347490
#> 7    plan execute  1696  0.70140612
#> 8    plan monitor   221  0.09139785
#> 9    plan    plan   501  0.20719603
```

[`summarize_transitions()`](https://mohsaqr.github.io/simulab/reference/summarize_transitions.md)
counts observed transitions and divides each count by the total leaving
its source state. For a first-order model, these proportions are
maximum-likelihood estimates of the transition probabilities when the
source state has observed transitions.

In this example, estimates are within approximately 0.01 of their
generating values, including 0.70 for `plan` to `execute`, 0.50 for
`execute` to itself, and 0.40 for `monitor` to `plan`. The `wide`
component stores each sequence across successive columns.

### Hidden Markov models

[`simulate_hmm()`](https://mohsaqr.github.io/simulab/reference/simulate_hmm.md)
generates a latent Markov sequence and an observed categorical response
at each occasion. The latent state evolves according to `transition`,
and its response distribution is specified by `emission`. The result
includes both the generated `state` and the emitted `observation`.

``` r

hidden <- simulate_hmm(
  n = 200,
  chain_length = 30,
  transition = data.frame(
    from = c("engaged", "engaged", "stuck", "stuck"),
    to   = c("engaged", "stuck", "engaged", "stuck"),
    probability = c(0.9, 0.1, 0.3, 0.7)
  ),
  emission = data.frame(
    state       = rep(c("engaged", "stuck"), each = 3),
    observation = rep(c("submit", "view", "idle"), times = 2),
    probability = c(0.6, 0.3, 0.1,  0.1, 0.3, 0.6)
  ),
  initial = c(engaged = 0.5, stuck = 0.5),
  seed = 1
)
head(hidden, 3)
#> <simulab_sim:hmm> 3 rows x 4 columns
#>   id occasion state observation
#> 1  1        1 stuck        idle
#> 2  1        2 stuck        idle
#> 3  1        3 stuck        idle
xtabs(~ state + observation, data = hidden)
#>          observation
#> state     idle submit view
#>   engaged  439   2632 1264
#>   stuck   1015    178  472
```

An engaged state emits `submit` with probability 0.6, while a stuck
state emits `idle` with probability 0.6. The cross-tabulation summarizes
the realized emissions by state. Retaining the latent sequence permits
evaluation of state reconstruction by a fitted model after aligning its
state labels with the generating labels.

### Groups, mixtures and event logs

[`simulate_group_sequences()`](https://mohsaqr.github.io/simulab/reference/simulate_group_sequences.md)
generates sequences for known groups with group-specific transition
matrices.
[`simulate_sequence_clusters()`](https://mohsaqr.github.io/simulab/reference/simulate_sequence_clusters.md)
generates a mixture of transition processes and records the generated
latent membership in `sequence_cluster`.

[`simulate_event_log()`](https://mohsaqr.github.io/simulab/reference/simulate_event_log.md)
generates educational event data with group, actor, course, achievement,
and timestamp information. Its state labels come from the catalogue
provided by
[`learning_states()`](https://mohsaqr.github.io/simulab/reference/learning_states.md).

``` r

event_log <- simulate_event_log(groups = 2, actors = 3, n_states = 4,
                                sequence_length = c(5, 8), seed = 1)
head(event_log, 4)
#> <simulab_sim:event_log> 4 rows x 7 columns
#>     group    id   course achievement period     state           timestamp
#> 1 Group 1 G1_A1 Course 1      medium      1 Encourage 2020-01-01 00:00:00
#> 2 Group 1 G1_A1 Course 1      medium      2 Encourage 2020-01-01 00:01:10
#> 3 Group 1 G1_A1 Course 1      medium      3     Doubt 2020-01-01 00:05:15
#> 4 Group 1 G1_A1 Course 1      medium      4  Complete 2020-01-01 00:06:32
```

The example generates two groups with three actors per group, four
states, and sequence lengths sampled between five and eight events. The
printed records show the resulting event structure.

### Transition network analysis

Transition network analysis represents transitions between states as a
weighted directed network.
[`fit_tna()`](https://mohsaqr.github.io/simulab/reference/fit_tna.md)
fits a transition network using the `tna` package and returns its edges.
For the default first-order model, weights are transition counts
normalized by source state.

``` r

fit_tna(sequences)
#> <simulab_sim:tna_model> 9 rows x 3 columns
#>      from      to     weight
#> 1 execute execute 0.50155833
#> 2 monitor execute 0.30386100
#> 3    plan execute 0.70140612
#> 4 execute monitor 0.39158504
#> 5 monitor monitor 0.29266409
#> 6    plan monitor 0.09139785
#> 7 execute    plan 0.10685663
#> 8 monitor    plan 0.40347490
#> 9    plan    plan 0.20719603
```

[`simulate_group_tna()`](https://mohsaqr.github.io/simulab/reference/simulate_group_tna.md)
generates grouped sequences and fits a network for each group.
[`evaluate_tna_estimation()`](https://mohsaqr.github.io/simulab/reference/evaluate_tna_estimation.md)
compares estimated and generating transition systems across repeated
samples.

## Part VIII: Networks

### Random graphs and blocks

[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
generates networks under several models. In the Bernoulli model, each
eligible vertex pair is connected independently with probability $`p`$.
Pairs are ordered in directed networks and unordered in undirected
networks; self-links are excluded by default. A matrix of probabilities
indexed by vertex type gives a stochastic block model in which
connection probabilities depend on the types of both endpoints.

``` r

node_types <- rep(c("teacher", "student"), times = c(3, 12))
tie_probability <- matrix(
  c(0.1, 0.5,
    0.5, 0.15),
  nrow = 2,
  dimnames = list(c("teacher", "student"), c("teacher", "student"))
)
classroom <- simulate_network(
  nodes = 15,
  probability = tie_probability,
  node_type = node_types,
  directed = FALSE,
  seed = 1
)
head(classroom, 3)
#> <simulab_sim:network> 3 rows x 3 columns
#>   from to weight
#> 1    1  4      1
#> 2    3  4      1
#> 3    1  5      1
as.data.frame(classroom, what = "settings")
#>       model directed loops weight nodes edges
#> 1 bernoulli    FALSE FALSE binary    15    26
```

This undirected example contains three teachers and twelve students.
Connection probabilities are 0.1 between teachers, 0.15 between
students, and 0.5 between teachers and students. The generated data are
a tidy edge list. `nodes` records vertex types, `adjacency` provides the
adjacency matrix in tidy format, and `settings` reports the realized
edge count, here 26.

### Preferential attachment and small worlds

[`simulate_network()`](https://mohsaqr.github.io/simulab/reference/simulate_network.md)
also supports preferential-attachment and small-world models through
`igraph`. Preferential attachment favors connections to vertices with
higher degree as the network grows. Small-world construction combines
local connections with rewiring.

[`network_centrality()`](https://mohsaqr.github.io/simulab/reference/network_centrality.md)
returns vertex centrality measures in tidy format.

``` r

scale_free <- simulate_network(nodes = 200, model = "barabasi_albert",
                               attachment = 2, directed = FALSE, seed = 1)
degree <- network_centrality(scale_free, measures = "degree")
summarize_simulations(degree, variables = "value")
#>   variable observations mean       sd minimum maximum
#> 1    value          200 3.97 3.471217       2      21
```

With `attachment = 2`, new vertices form connections to existing
vertices according to the attachment mechanism. In this realization,
minimum degree is 2, mean degree is 3.97, and maximum degree is 21.
These values describe unequal connectivity in the generated network;
they do not by themselves establish a particular degree-distribution
form.

### Temporal, bipartite and multiplex networks

[`simulate_temporal_network()`](https://mohsaqr.github.io/simulab/reference/simulate_temporal_network.md)
generates a discrete-time process in which each eligible pair switches
between inactive and active states. `initial_probability` determines
initial activity, `formation_probability` governs activation of inactive
pairs, and `dissolution_probability` governs termination of active
connections at subsequent periods.

``` r

temporal <- simulate_temporal_network(
  nodes = 10,
  periods = 12,
  initial_probability = 0.1,
  formation_probability = 0.05,
  dissolution_probability = 0.3,
  seed = 1
)
head(temporal, 4)
#> <simulab_sim:temporal_network> 4 rows x 6 columns
#>     from     to onset terminus weight censored
#> 1 Node 2 Node 1     5        7      1    FALSE
#> 2 Node 5 Node 1     1        3      1    FALSE
#> 3 Node 5 Node 1     7       10      1    FALSE
#> 4 Node 8 Node 1     1        3      1    FALSE
components(temporal)
#>       table rows columns
#> 1      data   49       6
#> 2    events   83       5
#> 3 snapshots  128       4
#> 4     nodes   10       2
#> 5  settings    1       7
```

The primary result contains relational spells with endpoints `from` and
`to` and boundaries `onset` and `terminus`. A spell is active from
`onset` through `terminus - 1`. Spells active in the final period have
`terminus = periods + 1` and are marked `censored = TRUE`. The `events`
component records formations and dissolutions, while `snapshots` records
connected pairs at each period.

[`simulate_bipartite_network()`](https://mohsaqr.github.io/simulab/reference/simulate_bipartite_network.md)
generates connections between two disjoint vertex sets, such as students
and attended events.
[`simulate_multiplex_network()`](https://mohsaqr.github.io/simulab/reference/simulate_multiplex_network.md)
generates separate layers over a shared vertex set, using the specified
layer-specific connection probabilities.

``` r

layers <- simulate_multiplex_network(
  nodes = 10,
  layers = c("advice", "friendship"),
  probability = c(0.15, 0.3),
  seed = 1
)
as.data.frame(layers, what = "layers")
#>        layer probability
#> 1     advice        0.15
#> 2 friendship        0.30
xtabs(~ layer, data = layers)
#> layer
#>     advice friendship 
#>         12         30
```

The example uses ten vertices in two directed layers, with self-links
excluded. Each layer has ninety possible ordered pairs, giving expected
edge counts of $`90\times0.15=13.5`$ for advice and $`90\times0.3=27`$
for friendship. The realized counts are twelve and thirty. The `layers`
component records the layer settings, while the cross-tabulation counts
generated edges by layer.
