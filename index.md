# simulab

simulab generates a wide variety of data, in different shapes, sample
sizes, distributions and parameters. The parameters are either drawn at
random or set in advance, and in both cases they are stored with the
data, so they are known, recoverable and testable. The package is
designed for simulation, for the evaluation of statistical methods, for
training and testing models and software, and for learning and teaching.
Data generated from specified parameters describe no real persons, so
they can be shared, published and given to a class without the consent,
review and access agreements that real data about people require.

The generators cover declared variables with treatment assignment,
missing values and copula dependence; group comparisons, regression and
Gaussian clusters; latent profile, latent class, factor and item
response models; multilevel, growth and vector autoregressive
longitudinal data; survival times with censoring and competing risks;
sequences of states from Markov chains, hidden Markov models and
mixtures; behavioral event data; transition networks; and random,
bipartite, multiplex and temporal networks. The package is written in
base R and requires R 4.1.0 or later.

The documentation, with a methodological guide and the reference of
every function, is at <https://pak.dynasite.org/simulab/>.

## Installation

``` r

install.packages("simulab")
```

The development version is installed from r-universe or GitHub:

``` r

install.packages("simulab", repos = c("https://mohsaqr.r-universe.dev",
                                      "https://cloud.r-project.org"))
remotes::install_github("mohsaqr/simulab")
```

No suggested package is needed at run time. `tna` (1.2.3 or later) fits
the transition networks of
[`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md),
[`simulate_group_tna()`](https://pak.dynasite.org/simulab/reference/simulate_group_tna.md)
and
[`fit_tna()`](https://pak.dynasite.org/simulab/reference/fit_tna.md);
`igraph` (2.0.0 or later) supplies the preferential-attachment and
small-world generators and
[`as_igraph()`](https://pak.dynasite.org/simulab/reference/as_igraph.md);
`survival` fits the Cox model in the vignette; `simstudy` is an
equivalence oracle in the tests.

## Data with and without parameters

Called with no arguments, a generator draws its parameters and prints
them under the data as the truth. Here the intercept of a linear
regression is drawn from the standard normal distribution and two slopes
from the uniform distribution on \[−1, 1\].

``` r

library(simulab)
simulate_regression(seed = 1)
#> <simulab_sim:regression> 100 rows x 4 columns
#>    id         x1         x2     outcome
#> 1   1 -0.8356286 -0.9109216  0.08428839
#> 2   2  1.5952808  0.1580288 -0.59203209
#> 3   3  0.3295078 -0.6545846 -3.40256878
#> 4   4 -0.8204684  1.7672873  3.19376689
#> 5   5  0.4874291  0.7167075  0.69788065
#> 6   6  0.7383247  0.9101742  0.76841891
#> 7   7  0.5757814  0.3841854 -0.24200033
#> 8   8 -0.3053884  1.6821761  1.21368455
#> 9   9  1.5117812 -0.6357365 -1.08891255
#> 10 10  0.3898432 -0.4616447 -0.52937755
#> ... 90 more rows
#> 
#> Truth (coefficients):
#>          term coefficient
#> 1 (Intercept)       -0.63
#> 2          x1        0.15
#> 3          x2        0.82
#> 
#> Other tables: effects, predictor_correlation. Read one with as.data.frame(x, what = "effects").
```

Given parameters are printed in the same way.

``` r

known <- simulate_regression(
  n = 100,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1
)
known
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
#> 
#> Truth (coefficients):
#>          term coefficient
#> 1 (Intercept)         1.0
#> 2          x1         0.5
#> 3          x2        -0.3
#> 
#> Other tables: effects, predictor_correlation. Read one with as.data.frame(x, what = "effects").
```

## Recovery

A model fitted to the data estimates the parameters, and
[`validate_recovery()`](https://pak.dynasite.org/simulab/reference/validate_recovery.md)
sets each estimate against the value that generated it.

``` r

validate_recovery(lm(outcome ~ x1 + x2, data = known), known)
#>          term   estimate truth        bias absolute_error relative_error
#> 1 (Intercept)  1.0253534   1.0  0.02535343     0.02535343     0.02535343
#> 2          x1  0.5211102   0.5  0.02111017     0.02111017     0.04222033
#> 3          x2 -0.3534668  -0.3 -0.05346682     0.05346682     0.17822272
#>   recovered
#> 1      TRUE
#> 2      TRUE
#> 3      TRUE
```

## Batches

Every single-dataset generator takes `batch`. With `batch = 500`, a call
returns 500 data sets from the same model, each reproducible from its
own seed. In
[`apply_batch()`](https://pak.dynasite.org/simulab/reference/apply_batch.md),
a model is fitted to each data set, and
[`validate_recovery()`](https://pak.dynasite.org/simulab/reference/validate_recovery.md)
compares every estimate with the truth of its own data set.

``` r

datasets <- simulate_regression(
  n = 100,
  coefficients = c("(Intercept)" = 1, x1 = 0.5, x2 = -0.3),
  seed = 1,
  batch = 500
)
estimates <- apply_batch(datasets, lm, formula = outcome ~ x1 + x2)
recovery <- validate_recovery(estimates, datasets)
summarize_simulations(recovery, by = "term", variables = "bias")
#>          term variable observations         mean        sd    minimum   maximum
#> 1 (Intercept)     bias          500  0.004524666 0.1003488 -0.3130872 0.3106459
#> 2          x1     bias          500  0.001262413 0.1018302 -0.2850844 0.3985527
#> 3          x2     bias          500 -0.001266961 0.1003781 -0.2668912 0.3682355
```

The mean bias of each coefficient over the 500 data sets estimates the
bias of the estimator, and the standard deviation of the bias is its
empirical standard error.

## Transition networks

[`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md)
draws a transition matrix over learning states, generates sequences from
it, and fits one transition network with the `tna` package. The result
is a native `tna` model, so every `tna` function applies to it. Its
print shows the fitted network, then the matrix that generated the
sequences.

``` r

network <- simulate_tna(seed = 1)
network
#> State Labels : 
#> 
#>    Analyze, Elaborate, Learn, Plan, Reflect 
#> 
#> Transition Probability Matrix :
#> 
#>              Analyze  Elaborate      Learn      Plan    Reflect
#> Analyze   0.56750572 0.12356979 0.02288330 0.2013730 0.08466819
#> Elaborate 0.05590062 0.10869565 0.13664596 0.3881988 0.31055901
#> Learn     0.04237288 0.44067797 0.04237288 0.2627119 0.21186441
#> Plan      0.22473868 0.04181185 0.07665505 0.3745645 0.28222997
#> Reflect   0.13363029 0.32962138 0.01781737 0.3006682 0.21826281
#> 
#> Initial Probabilities : 
#> 
#>   Analyze Elaborate     Learn      Plan   Reflect 
#>      0.02      0.31      0.09      0.12      0.46 
#> 
#> Generating Transition Probability Matrix (truth) :
#> 
#>           Analyze Elaborate Learn  Plan Reflect
#> Analyze     0.553     0.122 0.024 0.194   0.108
#> Elaborate   0.078     0.070 0.150 0.386   0.317
#> Learn       0.036     0.381 0.038 0.246   0.298
#> Plan        0.221     0.034 0.082 0.358   0.305
#> Reflect     0.113     0.316 0.025 0.327   0.219
#> 
#> Generating Initial Probabilities (truth) :
#> 
#>   Analyze Elaborate     Learn      Plan   Reflect 
#>     0.045     0.334     0.134     0.079     0.407 
#> 
#> Other tables: edges, sequences, wide, model_info. Read one with as.data.frame(x, what = "edges").
```

## Generators

| Family | Generators |
|----|----|
| General | [`simulate_study()`](https://pak.dynasite.org/simulab/reference/simulate_study.md), [`simulate_correlation()`](https://pak.dynasite.org/simulab/reference/simulate_correlation.md), [`simulate_correlated()`](https://pak.dynasite.org/simulab/reference/simulate_correlated.md), [`simulate_copula()`](https://pak.dynasite.org/simulab/reference/simulate_copula.md), [`simulate_ordinal()`](https://pak.dynasite.org/simulab/reference/simulate_ordinal.md) |
| Statistical | [`simulate_ttest()`](https://pak.dynasite.org/simulab/reference/simulate_ttest.md), [`simulate_anova()`](https://pak.dynasite.org/simulab/reference/simulate_anova.md), [`simulate_regression()`](https://pak.dynasite.org/simulab/reference/simulate_regression.md), [`simulate_prediction()`](https://pak.dynasite.org/simulab/reference/simulate_prediction.md), [`simulate_clusters()`](https://pak.dynasite.org/simulab/reference/simulate_clusters.md) |
| Latent and measurement | [`simulate_lpa()`](https://pak.dynasite.org/simulab/reference/simulate_lpa.md), [`simulate_ml_lpa()`](https://pak.dynasite.org/simulab/reference/simulate_ml_lpa.md), [`simulate_lca()`](https://pak.dynasite.org/simulab/reference/simulate_lca.md), [`simulate_factors()`](https://pak.dynasite.org/simulab/reference/simulate_factors.md), [`simulate_irt()`](https://pak.dynasite.org/simulab/reference/simulate_irt.md) |
| Longitudinal | [`simulate_multilevel()`](https://pak.dynasite.org/simulab/reference/simulate_multilevel.md), [`simulate_growth()`](https://pak.dynasite.org/simulab/reference/simulate_growth.md), [`simulate_longitudinal()`](https://pak.dynasite.org/simulab/reference/simulate_longitudinal.md) |
| Survival | [`simulate_survival()`](https://pak.dynasite.org/simulab/reference/simulate_survival.md), [`simulate_proportional_survival()`](https://pak.dynasite.org/simulab/reference/simulate_proportional_survival.md) |
| Sequences | [`simulate_markov()`](https://pak.dynasite.org/simulab/reference/simulate_markov.md), [`generate_transition_system()`](https://pak.dynasite.org/simulab/reference/generate_transition_system.md), [`simulate_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_sequences.md), [`simulate_sequence_clusters()`](https://pak.dynasite.org/simulab/reference/simulate_sequence_clusters.md), [`simulate_hmm()`](https://pak.dynasite.org/simulab/reference/simulate_hmm.md), [`simulate_group_sequences()`](https://pak.dynasite.org/simulab/reference/simulate_group_sequences.md), [`simulate_event_log()`](https://pak.dynasite.org/simulab/reference/simulate_event_log.md), [`simulate_until_event()`](https://pak.dynasite.org/simulab/reference/simulate_until_event.md) |
| Transition networks | [`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md), [`simulate_group_tna()`](https://pak.dynasite.org/simulab/reference/simulate_group_tna.md), [`simulate_tna_network()`](https://pak.dynasite.org/simulab/reference/simulate_tna_network.md) |
| Networks | [`simulate_network()`](https://pak.dynasite.org/simulab/reference/simulate_network.md), [`simulate_edge_list()`](https://pak.dynasite.org/simulab/reference/simulate_edge_list.md), [`simulate_network_matrix()`](https://pak.dynasite.org/simulab/reference/simulate_network_matrix.md), [`simulate_temporal_network()`](https://pak.dynasite.org/simulab/reference/simulate_temporal_network.md), [`simulate_bipartite_network()`](https://pak.dynasite.org/simulab/reference/simulate_bipartite_network.md), [`simulate_multiplex_network()`](https://pak.dynasite.org/simulab/reference/simulate_multiplex_network.md) |
| Empirical and functional | [`simulate_synthetic()`](https://pak.dynasite.org/simulab/reference/simulate_synthetic.md), [`simulate_density()`](https://pak.dynasite.org/simulab/reference/simulate_density.md), [`simulate_spline()`](https://pak.dynasite.org/simulab/reference/simulate_spline.md) |
| Replication | [`simulate_sequence_batches()`](https://pak.dynasite.org/simulab/reference/simulate_sequence_batches.md), [`simulate_tna_batches()`](https://pak.dynasite.org/simulab/reference/simulate_tna_batches.md), [`simulate_network_batches()`](https://pak.dynasite.org/simulab/reference/simulate_network_batches.md), [`simulate_scenarios()`](https://pak.dynasite.org/simulab/reference/simulate_scenarios.md), [`simulate_data()`](https://pak.dynasite.org/simulab/reference/simulate_data.md) |

The vignette describes the data each generator produces, and
[`list_simulators()`](https://pak.dynasite.org/simulab/reference/list_simulators.md)
lists them with the shape of their results.

## Citation

``` R
Saqr M, López-Pernas S (2026). _simulab: Simulates a Wide Variety of
Data Shapes, Sizes and Distributions_. R package version 0.4.10,
<https://pak.dynasite.org/simulab/>.
```

## License

MIT © Mohammed Saqr, Sonsoles López-Pernas
