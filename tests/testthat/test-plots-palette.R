# T-fig-03 / T-fig-04: the grade ramp and named scales.
test_that("grade palettes have strictly increasing luminance and contrast >= 3 on white (n = 1..64)", {
  for (n in 1:64) {
    p <- postrank_palette(n)
    expect_identical(names(p), as.character(seq_len(n)))
    L <- vapply(p, .pr_rel_luminance, 1)
    if (n > 1) expect_true(all(diff(L) > 0), info = n)
    expect_true(all(vapply(p, .pr_contrast, 1, b = "#FFFFFF") >= 3), info = n)
    best_text <- vapply(p, function(h) max(.pr_contrast(h, "#000000"), .pr_contrast(h, "#FFFFFF")), 1)
    expect_true(all(best_text >= 4.5), info = n)
  }
  expect_identical(unname(postrank_palette(1)), "#153653"); expect_identical(unname(postrank_palette(2)), c("#153653", "#4F879E"))
  e <- tryCatch(postrank_palette(65), error = identity); expect_identical(e$code, "invalid_palette_size")
  expect_identical(names(postrank_palette(which = "relation")), c("above", "withheld", "below"))
  expect_identical(names(postrank_palette(which = "change")), c("unchanged", "newly disclosed", "newly withheld", "reversed"))
})

test_that("a missing middle grade keeps each grade's own colour (T-fig-03)", {
  d <- data.frame(x = 1:2, y = 1:2, g = factor(c("1", "3"), levels = c("1", "2", "3")))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point() + scale_colour_grade(3)
  b <- ggplot2::layer_data(p)
  expect_identical(b$colour, unname(postrank_palette(3)[c("1", "3")]))
  q <- ggplot2::ggplot(d, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_point() + scale_color_grade(3)
  expect_identical(ggplot2::layer_data(q)$colour, b$colour)   # the American-spelling alias draws the same colors
  expect_s3_class(scale_fill_grade(4), "ScaleDiscrete")
})
