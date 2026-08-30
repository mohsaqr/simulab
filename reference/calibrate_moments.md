# Solve a distribution's parameters from a target mean and variance

`calibrate_moments()` inverts the moments of a distribution into the
parameters that attain them, so a target mean and variance can be stated
directly and turned into a distribution call. A one-parameter family
takes `mean` alone, because its mean already fixes its variance; the
reported `variance` is then the one those parameters imply.

## Usage

``` r
calibrate_moments(distribution = NULL, mean = NULL, variance = NULL)
```

## Arguments

- distribution:

  Distribution name. `calibrate_moments()` with no arguments reports the
  distributions it can invert.

- mean:

  Target mean, or a vector of target means.

- variance:

  Target variance, for a two-parameter family. Omitted for a
  one-parameter family, whose variance its mean determines.

## Value

A base `data.frame` with one row per target and parameter, and columns
`distribution`, `mean`, `variance`, `parameter` and `value`. The
`parameter` names are those
[`list_distributions()`](https://mohsaqr.github.io/simulab/reference/list_distributions.md)
reports, so the result states a distribution call.

## Details

Most inversions are closed form. For a scale family whose shape is fixed
by the coefficient of variation alone – Weibull, log-logistic, Frechet,
Nakagami – the shape is found by root finding and the scale then follows
exactly. Some families cannot reach every pair: a Nakagami squared
coefficient of variation is at most `pi / 2 - 1`, a Lomax with a finite
variance always has one above 1, and a beta variance is below
`mean * (1 - mean)`. Those are refused rather than approximated.

## Conditions

`simulab_unattainable_moments` when no member of the family has the
requested moments, such as a beta variance at or above
`mean * (1 - mean)`; `simulab_no_moment_solution` when the distribution
has no implemented inversion; `simulab_incompatible_lengths` when `mean`
and `variance` are vectors of different, non-recyclable lengths.

## Examples

``` r
# The 36 distributions that can be inverted, and the targets each takes.
calibrate_moments()
#>              distribution       parameters        targets
#> 1                  anglit  location, scale mean, variance
#> 2                 arcsine         min, max mean, variance
#> 3                    beta   shape1, shape2 mean, variance
#> 4              beta_prime   shape1, shape2 mean, variance
#> 5                  binary             prob           mean
#> 6                     chi               df           mean
#> 7                   chisq               df           mean
#> 8             exponential             rate           mean
#> 9                 frechet     shape, scale mean, variance
#> 10                  gamma      shape, rate mean, variance
#> 11              geometric             prob           mean
#> 12                 gumbel  location, scale mean, variance
#> 13          half_logistic            scale           mean
#> 14            half_normal               sd           mean
#> 15      hyperbolic_secant  location, scale mean, variance
#> 16              inv_gamma      shape, rate mean, variance
#> 17       inverse_gaussian      mean, shape mean, variance
#> 18                laplace  location, scale mean, variance
#> 19           log_logistic     shape, scale mean, variance
#> 20               logistic  location, scale mean, variance
#> 21              lognormal   meanlog, sdlog mean, variance
#> 22                  lomax     shape, scale mean, variance
#> 23                maxwell            scale           mean
#> 24                  moyal  location, scale mean, variance
#> 25               nakagami    shape, spread mean, variance
#> 26      negative_binomial       size, prob mean, variance
#> 27                 normal         mean, sd mean, variance
#> 28                 pareto     shape, scale mean, variance
#> 29                poisson           lambda           mean
#> 30                  power     shape, scale mean, variance
#> 31               rayleigh            scale           mean
#> 32           semicircular  location, scale mean, variance
#> 33                skellam lambda1, lambda2 mean, variance
#> 34                uniform         min, max mean, variance
#> 35                weibull     shape, scale mean, variance
#> 36 zero_truncated_poisson           lambda           mean

# A lognormal with mean 10 and variance 25.
calibrate_moments("lognormal", mean = 10, variance = 25)
#>   distribution mean variance parameter     value
#> 1    lognormal   10       25   meanlog 2.1910133
#> 2    lognormal   10       25     sdlog 0.4723807

# A one-parameter family takes the mean alone and reports the variance
# that follows from it.
calibrate_moments("poisson", mean = 4)
#>   distribution mean variance parameter value
#> 1      poisson    4        4    lambda     4

# Targets recycle, so a sweep is one call.
calibrate_moments("gamma", mean = c(5, 10, 20), variance = 9)
#>   distribution mean variance parameter      value
#> 1        gamma    5        9     shape  2.7777778
#> 2        gamma    5        9      rate  0.5555556
#> 3        gamma   10        9     shape 11.1111111
#> 4        gamma   10        9      rate  1.1111111
#> 5        gamma   20        9     shape 44.4444444
#> 6        gamma   20        9      rate  2.2222222
```
