# Combine competing event times

Reduces several latent event times to the one observed first: the
observed time is their row-wise minimum and the event code says which
process won. Naming one of them in `censor` turns that process into
censoring, so its code is `0` and the remaining processes are coded
`1, 2, ...` in the order they appear in `events`. Without `censor` every
row is an event and no code is `0`. Ties are broken in favour of the
earlier entry of `events`.

## Usage

``` r
combine_competing_risks(
  data,
  events,
  censor = NULL,
  time = "time",
  event = "event",
  type = "event_type",
  keep_events = FALSE
)
```

## Arguments

- data:

  Base `data.frame`, or a `simulab_sim`, containing the event-time
  variables, with at least one row.

- events:

  Event-time variable names. A character vector of at least two names,
  all present in `data`, holding complete numeric times.

- censor:

  Optional name of the one entry of `events` that represents censoring
  rather than an event. A single string, or `NULL` (the default) when
  every process is an event.

- time:

  Name of the observed-time variable. A single string, defaulting to
  `"time"`.

- event:

  Name of the integer event-code variable. A single string, defaulting
  to `"event"`. The code is `0` for the process named in `censor` and
  `1, 2, ...` for the other entries of `events`, in their given order.

- type:

  Name of the character event-type variable, holding the winning process
  name. A single string, defaulting to `"event_type"`.

- keep_events:

  Retain the component event-time variables. A single flag, defaulting
  to `FALSE`, which drops them.

## Value

A `simulab_sim` base `data.frame` with one row per input row: the
columns of `data` (without the entries of `events` unless `keep_events`
is `TRUE`) followed by `time`, `event` and `type` under the names given
by those arguments. The component `events`, reached with
`as.data.frame(x, what = "events")`, is the codebook, one row per
process with columns `event_type`, `event_code` and the logical
`censoring`.

## Examples

``` r
data <- data.frame(id = 1:100, treatment = rep(0:1, each = 50))
data <- augment_survival(
  data,
  specification = define_survivals(
    define_survival("time_relapse", formula = -8, shape = 0.3),
    define_survival("time_death", formula = -9, shape = 0.3)
  ),
  seed = 1
)

result <- combine_competing_risks(
  data, events = c("time_relapse", "time_death")
)
head(result)
#> <simulab_sim:competing_risks> 6 rows x 5 columns
#>   id treatment      time event   event_type
#> 1  1         0 11.499102     2   time_death
#> 2  2         0 10.985087     1 time_relapse
#> 3  3         0  9.248955     1 time_relapse
#> 4  4         0  3.406859     2   time_death
#> 5  5         0 11.760588     2   time_death
#> 6  6         0  5.640350     1 time_relapse
```
