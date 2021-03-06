context("Seeds")

test_that("with_seed", {
  set.seed(1)
  x.1 = runif(5)
  set.seed(42)
  x.42 = runif(5)
  x.next = runif(5)

  set.seed(42)
  y.1 = withr::with_seed(1, runif(5))
  y.42 = runif(5)
  y.next = runif(5)

  expect_identical(x.1, y.1)
  expect_identical(x.42, y.42)
  expect_identical(x.next, y.next)
  expect_error(withr::with_seed(1, print(state)))
})

test_that("Problem and Algorithm seed", {
  reg = makeTestExperimentRegistry(seed = 42)
  addProblem(reg = reg, "p1", data = iris, fun = function(job, data, ...) runif(1), seed = 1L)
  addProblem(reg = reg, "p2", data = iris, fun = function(job, data, ...) runif(1))
  addAlgorithm(reg = reg, "a1", fun = function(job, data, instance, ...) list(instance = instance, res = runif(1)))
  addAlgorithm(reg = reg, "a2", fun = function(job, data, instance, ...) list(instance = instance, res = runif(1)))
  prob.designs = list(p1 = data.table(), p2 = data.table())
  algo.designs = list(a1 = data.table(), a2 = data.table())
  repls = 3
  ids = addExperiments(prob.designs, algo.designs, repls = repls, reg = reg)

  submitAndWait(reg, ids)

  set.seed(1); p1 = runif(1)
  set.seed(2); p2 = runif(1)
  set.seed(3); p3 = runif(1)
  set.seed(43); a1 = runif(1)
  set.seed(44); a2 = runif(1)
  set.seed(45); a3 = runif(1)
  silent({
    ids = findExperiments(algo.name = "a1", prob.name = "p1", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == c(p1, p2, p3)))
  expect_true(all(results$res == c(a1, a2, a3)))

  silent({
    ids = findExperiments(prob.name = "p1", repl = 2, reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == p2))

  silent({
    ids = findExperiments(prob.name = "p2", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_numeric(results$instance, unique = TRUE)
  expect_numeric(results$res, unique = TRUE)
})

test_that("Problem and Algorithm fix seed", {
  reg = makeTestExperimentRegistry(seed = 42, fix.seed = TRUE)
  addProblem(reg = reg, "p1", data = iris, fun = function(job, data, ...) runif(1), seed = 1L)
  addProblem(reg = reg, "p2", data = iris, fun = function(job, data, ...) runif(1), fix.seed = TRUE)
  addProblem(reg = reg, "p3", data = iris, fun = function(job, data, ...) runif(1), seed = 24, fix.seed = TRUE)
  addProblem(reg = reg, "p4", data = iris, fun = function(job, data, ...) runif(1))
  addAlgorithm(reg = reg, "a1", fun = function(job, data, instance, ...) list(instance = instance, res = runif(1)))
  addAlgorithm(reg = reg, "a2", fun = function(job, data, instance, ...) list(instance = instance, res = runif(1)))
  prob.designs = list(p1 = data.table(), p2 = data.table(), p3 = data.table(), p4 = data.table())
  algo.designs = list(a1 = data.table(), a2 = data.table())
  repls = 3
  ids = addExperiments(prob.designs, algo.designs, repls = repls, reg = reg)
  
  submitAndWait(reg, ids)
  
  set.seed(1); p1 = runif(1)
  set.seed(2); p2 = runif(1)
  set.seed(3); p3 = runif(1)
  set.seed(24); p4 = runif(1);
  set.seed(42); a = runif(1)
  silent({
    ids = findExperiments(algo.name = "a1", prob.name = "p1", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == c(p1, p2, p3)))
  expect_true(all(results$res == rep.int(a, repls)))
  
  silent({
    ids = findExperiments(prob.name = "p2", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == rep.int(a, repls * 2)))
  expect_true(all(results$res == rep.int(a, repls * 2)))
  
  silent({
    ids = findExperiments(prob.name = "p3", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == rep.int(p4, repls * 2)))
  
  silent({
    ids1 = findExperiments(algo.name = "a1", prob.name = "p4", reg = reg)
    results1 = rbindlist(reduceResultsList(ids1, reg = reg), use.names = TRUE)
  })
  silent({
    ids2 = findExperiments(algo.name = "a2", prob.name = "p4", reg = reg)
    results2 = rbindlist(reduceResultsList(ids2, reg = reg), use.names = TRUE)
  })
  expect_true(all(results1$instance == results2$instance))
  
  
  reg = makeTestExperimentRegistry(seed = 42)
  addProblem(reg = reg, "p1", data = iris, fun = function(job, data, ...) runif(1), seed = 1L, fix.seed = TRUE)
  addAlgorithm(reg = reg, "a1", fun = function(job, data, instance, ...) list(instance = instance, res = runif(1)))
  prob.designs = list(p1 = data.table())
  algo.designs = list(a1 = data.table())
  repls = 3
  ids = addExperiments(prob.designs, algo.designs, repls = repls, reg = reg)
  
  submitAndWait(reg, ids)
  
  silent({
    ids = findExperiments(prob.name = "p1", reg = reg)
    results = rbindlist(reduceResultsList(ids, reg = reg), use.names = TRUE)
  })
  expect_true(all(results$instance == rep.int(p1, repls)))
})

test_that("Seed is correctly reported (#203)", {
  reg = makeTestRegistry(seed = 1)
  batchMap(function(x, .job) list(seed = .job$seed), x = 1:3, reg = reg)
  submitAndWait(reg)
  res = unwrap(reduceResultsDataTable(reg = reg))
  expect_data_table(res, nrow = 3, ncol = 2)
  expect_identical(res$seed, 2:4)

  expect_true(any(stri_detect_fixed(getLog(1, reg = reg), "Setting seed to 2")))
  expect_true(any(stri_detect_fixed(getLog(2, reg = reg), "Setting seed to 3")))
  expect_true(any(stri_detect_fixed(getLog(3, reg = reg), "Setting seed to 4")))


  reg = makeTestExperimentRegistry(seed = 1)
  addProblem(reg = reg, "p1", fun = function(job, ...) job$seed, seed = 100L)
  addAlgorithm(reg = reg, "a1", fun = function(job, instance, ...) list(instance = instance, seed = job$seed))
  ids = addExperiments(repls = 2, reg = reg)
  getStatus(reg = reg)
  submitAndWait(reg)

  res = unwrap(reduceResultsDataTable(reg = reg))
  expect_data_table(res, nrow = 2, ncol = 3)
  expect_identical(res$instance, 2:3)
  expect_identical(res$seed, 2:3)

  expect_true(any(stri_detect_fixed(getLog(1, reg = reg), "seed = 2")))
  expect_true(any(stri_detect_fixed(getLog(2, reg = reg), "seed = 3")))
  
  
  reg = makeTestRegistry(seed = 1, fix.seed = TRUE)
  batchMap(function(x, .job) list(seed = .job$seed), x = 1:3, reg = reg)
  submitAndWait(reg)
  res = unwrap(reduceResultsDataTable(reg = reg))
  expect_data_table(res, nrow = 3, ncol = 2)
  expect_identical(res$seed, rep.int(1L, 3))
  
  expect_true(any(stri_detect_fixed(getLog(1, reg = reg), "Setting seed to 1")))
  expect_true(any(stri_detect_fixed(getLog(2, reg = reg), "Setting seed to 1")))
  expect_true(any(stri_detect_fixed(getLog(3, reg = reg), "Setting seed to 1")))
  
  
  reg = makeTestExperimentRegistry(seed = 1, fix.seed = TRUE)
  addProblem(reg = reg, "p1", fun = function(job, ...) job$seed, seed = 100L)
  addAlgorithm(reg = reg, "a1", fun = function(job, instance, ...) list(instance = instance, seed = job$seed))
  ids = addExperiments(repls = 2, reg = reg)
  getStatus(reg = reg)
  submitAndWait(reg)
  
  res = unwrap(reduceResultsDataTable(reg = reg))
  expect_data_table(res, nrow = 2, ncol = 3)
  expect_identical(res$instance, rep.int(1L, 2))
  expect_identical(res$seed, rep.int(1L, 2))
  
  expect_true(any(stri_detect_fixed(getLog(1, reg = reg), "seed = 1")))
  expect_true(any(stri_detect_fixed(getLog(2, reg = reg), "seed = 1")))
  
})
