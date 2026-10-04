# print output is stable

    Code
      print(simulate_regression(n = 3, seed = 1))
    Output
      <simulab_sim:regression> 3 rows x 4 columns
        id         x1         x2    outcome
      1  1 -0.8356286 -0.8204684 -0.8523470
      2  2  1.5952808  0.4874291 -0.2964044
      3  3  0.3295078  0.7383247  1.5366336
      
      Truth (coefficients):
               term coefficient
      1 (Intercept)       -0.63
      2          x1        0.15
      3          x2        0.82
      
      Other tables: effects, predictor_correlation. Read one with as.data.frame(x, what = "effects").

