# simulab: Unified simulation of statistical and study data

`simulab` provides one consistent interface for declarative study
simulation, specialized statistical designs, correlated and longitudinal
data, latent-variable and measurement models, survival processes,
sequences, and networks.

## Details

Every simulator returns a data-frame-native `simulab_sim`. Primary data
can be passed directly to base-R and modeling functions. Use
[`components()`](https://pak.dynasite.org/simulab/reference/components.md)
to discover ground-truth and design tables, then
`as.data.frame(x, what = ...)` to retrieve them.

## See also

Useful links:

- <https://pak.dynasite.org/simulab/>

- <https://github.com/mohsaqr/simulab>

- Report bugs at <https://github.com/mohsaqr/simulab/issues>

## Author

**Maintainer**: Mohammed Saqr <saqr@saqr.me>
([ORCID](https://orcid.org/0000-0001-5881-3109)) \[copyright holder\]

Authors:

- Sonsoles López-Pernas <sonsoles.lopez@uef.fi>
  ([ORCID](https://orcid.org/0000-0002-9621-1392)) \[copyright holder\]
