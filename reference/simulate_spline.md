# Add a spline-generated variable

Add a spline-generated variable

## Usage

``` r
simulate_spline(
  data,
  predictor,
  variable,
  coefficients,
  knots = c(0.25, 0.5, 0.75),
  degree = 3L,
  output_range = NULL,
  noise_variance = 0,
  seed = NULL,
  batch = NULL
)
```

## Arguments

- data:

  Base `data.frame`.

- predictor:

  Predictor variable.

- variable:

  Name of the generated variable.

- coefficients:

  Spline coefficients.

- knots:

  Quantile probabilities for interior knots.

- degree:

  Polynomial degree.

- output_range:

  Optional numeric pair. The spline value `v` is rescaled to
  `output_range[1] + v * diff(output_range)`, which maps `[0, 1]` onto
  the pair. Values outside `[0, 1]` are rescaled the same way, not
  clipped.

- noise_variance:

  Non-negative Gaussian noise variance; the noise added to each value
  has standard deviation `sqrt(noise_variance)`.

- seed:

  Optional random seed. A single number makes the call reproducible and
  restores the session's random-number state afterwards; `NULL` (the
  default) draws from the session's stream and advances it.

- batch:

  Optional single positive whole number. When given, the simulator runs
  `batch` times and returns a plain `list` of `batch` results, each
  exactly what the same call without `batch` returns. With a `seed`,
  every dataset gets its own seed drawn from `seed`, so the whole batch
  is reproducible; without one the datasets are consecutive draws from
  the session's random-number stream. The default `NULL` returns a
  single result.

## Value

A `simulab_sim` base `data.frame` holding `data` with the spline
variable added. `as.data.frame(x, what = "basis")` gives the tidy basis
table, one row per observation/basis combination, and
`as.data.frame(x, what = "parameters")` gives one row per basis
coefficient.

## Examples

``` r
set.seed(1)
data <- data.frame(id = 1:100, x = stats::runif(100))
result <- simulate_spline(
  data, predictor = "x", variable = "y",
  coefficients = c(0.1, 0.2, 0.5, 0.4, 0.7, 0.6, 0.9),
  knots = c(0.25, 0.5, 0.75), seed = 1
)
head(result)
#> <simulab_sim:spline> 6 rows x 3 columns
#>   id         x         y
#> 1  1 0.2655087 0.3996209
#> 2  2 0.3721239 0.4470323
#> 3  3 0.5728534 0.4945659
#> 4  4 0.9082078 0.6870369
#> 5  5 0.2016819 0.3323789
#> 6  6 0.8983897 0.6749814
#> 
#> Truth (parameters):
#>     basis coefficient
#> 1 basis_1         0.1
#> 2 basis_2         0.2
#> 3 basis_3         0.5
#> 4 basis_4         0.4
#> 5 basis_5         0.7
#> 6 basis_6         0.6
#> 7 basis_7         0.9
#> 
#> Other tables: basis. Read one with as.data.frame(x, what = "basis").
```
