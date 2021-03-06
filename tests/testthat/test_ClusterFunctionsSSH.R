context("cf ssh")

test_that("cf ssh", {
  skip_on_os("windows")
  skip_on_travis()
  skip_on_cran()

  reg = makeTestRegistry()
  if (reg$cluster.functions$name == "Interactive") {
    workers = list(Worker$new("localhost", ncpus = 2, max.load = 9999))
    reg$cluster.functions = makeClusterFunctionsSSH(workers)
    saveRegistry(reg)
    fun = function(x) { Sys.sleep(x); is(x, "numeric") }
    ids = batchMap(fun, x = c(5, 5), reg = reg)
    silent({
      submitJobs(1:2, reg = reg)
      Sys.sleep(0.2)
      expect_equal(findOnSystem(reg = reg), findJobs(reg = reg))
      expect_true(killJobs(2, reg = reg)$killed)
      expect_true(
        waitForJobs(1, sleep = 0.5, reg = reg)
      )
    })
    expect_equal(findDone(reg = reg), findJobs(ids = 1, reg = reg))
    expect_equal(findNotDone(reg = reg), findJobs(ids = 2, reg = reg))
    expect_true(loadResult(1, reg = reg))
  }
})

if (FALSE) {
  reg = makeTestRegistry()
  workers = list(Worker$new("129.217.207.53"), Worker$new("localhost", ncpus = 1))

  reg$cluster.functions = makeClusterFunctionsSSH(workers)
  expect_string(workers[[1L]]$script)
  expect_string(workers[[2L]]$script)
  expect_equal(workers[[1L]]$ncpus, 4L)
  expect_equal(workers[[2L]]$ncpus, 1L)
  fun = function(x) { Sys.sleep(x); is(x, "numeric") }
  ids = batchMap(fun, x = 20 * c(1, 1), reg = reg)
  submitJobs(1:2, reg = reg)
  expect_equal(findOnSystem(reg = reg), findJobs(reg = reg))
  expect_true(killJobs(2, reg = reg)$killed)
  expect_true(waitForJobs(1, reg = reg, sleep = 1))
  expect_equal(findDone(reg = reg), findJobs(ids = 1, reg = reg))
  expect_equal(findNotDone(reg = reg), findJobs(ids = 2, reg = reg))
  expect_true(loadResult(1, reg = reg))
}
