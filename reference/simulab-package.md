# simulab: Unified simulation of statistical and study data

`simulab` provides one consistent interface for declarative study
simulation, specialized statistical designs, correlated and longitudinal
data, latent-variable and measurement models, survival processes,
sequences, and networks.

## Details

Every simulator returns a data-frame-native `simulab_sim`. Primary data
can be passed directly to base-R and modeling functions. Use
[`components()`](https://mohsaqr.github.io/simulab/reference/components.md)
to discover ground-truth and design tables, then
`as.data.frame(x, what = ...)` to retrieve them.

## See also

Useful links:

- <https://github.com/mohsaqr/simulab>

- Report bugs at <https://github.com/mohsaqr/simulab/issues>

## Author

**Maintainer**: Mohammed Saqr <saqr@saqr.me>
