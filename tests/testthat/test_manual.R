context("manual expensive tests")

test_that("rscimark", {
  skip("manual test")

  reg = makeTestRegistry(package = "rscimark")
  reg$cluster.functions = makeClusterFunctionsMulticore(4)
  batchMap(rscimark, minimum.time = rep(1, 5), reg = reg)
  submitJobs(reg = reg)
  waitForJobs(reg = reg, sleep = 1)
  tab = getJobTable(reg = reg)
  expect_true(tab$started[5] >= min(tab$done[1:4]))

  reg = makeTestRegistry()
  reg$cluster.functions = makeClusterFunctionsMulticore(4)
  batchMap(Sys.sleep, rep(3, 4), reg = reg)
  submitJobs(reg = reg)
  waitForJobs(reg = reg, sleep = 1)
  tab = getJobTable(reg = reg)
  expect_true(all(as.numeric(diff(range(tab$started))) <= 2))
  expect_true(all(as.numeric(diff(range(tab$done))) <= 2))
})
