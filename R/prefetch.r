Cache = function(file.dir) {
  force(file.dir)
  cache = new.env(parent = emptyenv())

  function(id, uri = id) {
    if (is.null(cache[[id]]) || cache[[id]]$uri != uri) {
      fn = file.path(file.dir, sprintf("%s.rds", uri))
      cache[[id]] = list(uri = uri, obj = if (file.exists(fn)) readRDS(fn) else NULL)
    }
    return(cache[[id]]$obj)
  }
}

prefetch = function(jd, cache) {
  UseMethod("prefetch")
}

prefetch.JobDescription = function(jd, cache) {
  cache("user.fun")
  cache("more.args")
  invisible(TRUE)
}

prefetch.ExperimentDescription = function(jd, cache) {
  problems = unique(vcapply(jd$defs$pars, "[[", "prob.name"))
  if (length(problems) == 1L)
    cache("prob/problem", file.path("problems", problems))
  algorithms = unique(vcapply(jd$defs$pars, "[[", "algo.name"))
  Map(cache, id = paste0("algo/", algorithms), uri = file.path("algorithms", algorithms))
  invisible(TRUE)
}
