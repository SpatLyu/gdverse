# Pre-compiled vignettes that need parallel computation.
# reference: https://ropensci.org/blog/2019/12/08/precompute-vignettes/
# Must manually move image files from `gdverse/` to `gdverse/vignettes/` after knit.

devtools::load_all()

knitr::knit("vignettes/GD.Rmd.orig",
            "vignettes/GD.Rmd")

knitr::knit("vignettes/OPGD.Rmd.orig",
            "vignettes/OPGD.Rmd")

knitr::knit("vignettes/SESU.Rmd.orig",
            "vignettes/SESU.Rmd")

knitr::knit("vignettes/SHEGD.Rmd.orig",
            "vignettes/SHEGD.Rmd")

knitr::knit("vignettes/SPADE.Rmd.orig",
            "vignettes/SPADE.Rmd")

knitr::knit("vignettes/IDSA.Rmd.orig",
            "vignettes/IDSA.Rmd")

knitr::knit("vignettes/RGDRID.Rmd.orig",
            "vignettes/RGDRID.Rmd")
