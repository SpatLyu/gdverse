## Resubmission

This is a resubmission. In this submission I have:

* Add Rd-tags `\value` for pipe.Rd.

* Update package description details in `DESCRIPTION` file.

* Remove unnecessary use of `\dontrun{}` in package examples and only retain `\dontrun{}`   where `robust_disc`, `rgd`, `rid` (requires configuration of python dependencies) and    `loess_optscale`, `sesu_opgd`, `sesu_gozh` (takes a long time to run). We also add the   necessary prompts for the examples which using `\dontrun{}`

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.