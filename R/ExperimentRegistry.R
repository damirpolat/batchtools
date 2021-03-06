#' @title ExperimentRegistry Constructor
#'
#' @description
#' \code{makeExperimentRegistry} constructs a special \code{\link{Registry}} which
#' is suitable for the definition of large scale computer experiments.
#'
#' Each experiments consists of a \code{\link{Problem}} and an \code{\link{Algorithm}}.
#' These can be parametrized with \code{\link{addExperiments}} to actually define computational
#' jobs.
#'
#' @inheritParams makeRegistry
#' @aliases ExperimentRegistry
#' @return [\code{ExperimentRegistry}].
#' @export
#' @family Registry Experiment
#' @examples
#' \dontshow{ batchtools:::example_push_temp(1) }
#' tmp = makeExperimentRegistry(file.dir = NA, make.default = FALSE)
#'
#' # Definde one problem, two algorithms and add them with some parameters:
#' addProblem(reg = tmp, "p1",
#'   fun = function(job, data, n, mean, sd, ...) rnorm(n, mean = mean, sd = sd))
#' addAlgorithm(reg = tmp, "a1", fun = function(job, data, instance, ...) mean(instance))
#' addAlgorithm(reg = tmp, "a2", fun = function(job, data, instance, ...) median(instance))
#' ids = addExperiments(reg = tmp, list(p1 = data.table::CJ(n = c(50, 100), mean = -2:2, sd = 1:4)))
#'
#' # Overview over defined experiments:
#' tmp$problems
#' tmp$algorithms
#' summarizeExperiments(reg = tmp)
#' summarizeExperiments(reg = tmp, by = c("problem", "algorithm", "n"))
#' ids = findExperiments(prob.pars = (n == 50), reg = tmp)
#' print(unwrap(getJobPars(ids, reg = tmp)))
#'
#' # Submit jobs
#' submitJobs(reg = tmp)
#' waitForJobs(reg = tmp)
#'
#' # Reduce the results of algorithm a1
#' ids.mean = findExperiments(algo.name = "a1", reg = tmp)
#' reduceResults(ids.mean, fun = function(aggr, res, ...) c(aggr, res), reg = tmp)
#'
#' # Join info table with all results and calculate mean of results
#' # grouped by n and algorithm
#' ids = findDone(reg = tmp)
#' pars = unwrap(getJobPars(ids, reg = tmp))
#' results = unwrap(reduceResultsDataTable(ids, fun = function(res) list(res = res), reg = tmp))
#' tab = ljoin(pars, results)
#' tab[, list(mres = mean(res)), by = c("n", "algorithm")]
makeExperimentRegistry = function(file.dir = "registry", work.dir = getwd(), conf.file = findConfFile(), packages = character(0L), namespaces = character(0L),
  source = character(0L), load = character(0L), seed = NULL, fix.seed = FALSE, make.default = TRUE) {

  reg = makeRegistry(file.dir = file.dir, work.dir = work.dir, conf.file = conf.file,
    packages = packages, namespaces = namespaces, source = source, load = load, seed = seed, fix.seed = fix.seed, make.default = make.default)

  fs::dir_create(fs::path(reg$file.dir, c("problems", "algorithms")))

  reg$problems       = character(0L)
  reg$algorithms     = character(0L)
  reg$status$repl    = integer(0L)
  reg$defs$problem   = character(0L)
  reg$defs$algorithm = character(0L)
  reg$defs$job.pars  = NULL
  reg$defs$prob.pars = list()
  reg$defs$algo.pars = list()
  reg$defs$pars.hash = character(0L)
  class(reg) = c("ExperimentRegistry", "Registry")

  saveRegistry(reg)
  return(reg)
}

#' @export
print.ExperimentRegistry = function(x, ...) {
  cat("Experiment Registry\n")
  catf("  Backend   : %s", x$cluster.functions$name)
  catf("  File dir  : %s", x$file.dir)
  catf("  Work dir  : %s", x$work.dir)
  catf("  Jobs      : %i", nrow(x$status))
  catf("  Problems  : %i", length(x$problems))
  catf("  Algorithms: %i", length(x$algorithms))
  catf("  Seed      : %i", x$seed)
  catf("  Writeable : %s", x$writeable)
}
