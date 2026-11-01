# simulab: Simulates a Wide Variety of Data Shapes, Sizes and Distributions

`simulab` generates data in different shapes, sample sizes,
distributions and parameters: declared study variables, statistical
designs, correlated and longitudinal data, latent-variable and
measurement models, survival processes, sequences of states, and
networks. The generating parameters are drawn at random or set in
advance, and in both cases they are stored with the data, so their
recovery can be tested.

## Details

Every generator returns a data-frame-native `simulab_sim`, except
[`simulate_tna()`](https://pak.dynasite.org/simulab/reference/simulate_tna.md),
which returns a native `tna` model of class `simulab_tna`. The primary
data can be passed directly to base-R and modeling functions.
[`components()`](https://pak.dynasite.org/simulab/reference/components.md)
lists the stored truth and design tables, and
`as.data.frame(x, what = ...)` returns each of them. Every
single-dataset generator takes `seed`, for reproducible output, and
`batch`, which returns a plain list of that many data sets, each
reproducible from its own seed.
[`list_simulators()`](https://pak.dynasite.org/simulab/reference/list_simulators.md)
catalogues the generators.

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
