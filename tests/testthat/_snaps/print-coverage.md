# 30 x 3 boxes are stable at width 72 (T-ux-04)

    Code
      cat(format(pr_cached(key), width = 72L), sep = "\n")
    Output
      <postrank_analysis>  30 entities in 4 grades (sizes 2 / 14 / 12 / 2)
        3 criteria: poverty, frl, snap.
        Posterior loss: 0.3226.
        Disclosed 276 of 435 pairs (63.4%); withheld 159.
        Expected error among disclosed pairs: poverty 0.136; frl 0.172;
          snap 0.784.
        Solver: Optimal within solver tolerances.
        Optimization gap: 5.55e-17; requested absolute gap 1e-08.
        Prepared: report card, fragility.
        Grade 1 has highest priority; a shared grade withholds the comparison.
        grade 1 (2): site003, site010
        grade 2 (14): site005, site008, site011, site012, site014, site017,
          site019, site021, site023, site025, site027, site028 +2 more
        grade 3 (12): site001, site002, site004, site006, site013, site015,
          site016, site018, site020, site022, site024, site026
        grade 4 (2): site007, site009
        i summary(x) explains the loss, settings and bounds; get_grades(x)
          returns all grades.

---

    Code
      cat(format(pr_cached(key), width = 72L), sep = "\n")
    Output
      <postrank_analysis>  30 entities in 1 grade; all comparisons withheld
        3 criteria: poverty, frl, snap.
        Posterior loss: 0.2500.
        Disclosed 0 of 435 pairs (0.0%); withheld 435.
        Expected error among disclosed pairs: NA (N = 0); no pairs were
          disclosed.
        A single shared grade withholds every comparison; it is not an
          error-free ranking.
        Solver: Optimal within solver tolerances.
        Optimization gap: 0; requested absolute gap 1e-08.
        Prepared: report card, fragility.
        Grade 1 has highest priority; a shared grade withholds the comparison.
        grade 1 (30): site001, site002, site003, site004, site005, site006,
          site007, site008, site009, site010, site011, site012 +18 more
        i summary(x) explains the loss, settings and bounds; get_grades(x)
          returns all grades.

---

    Code
      cat(format(pr_cached(key), width = 72L), sep = "\n")
    Output
      <postrank_comparison>  3 methods on one posterior and loss
        Reference method: joint. The weights and withholding cost are held
          fixed.
        Method: joint
          Loss: 0.3226
          Disclosed: 63.4%
          Grades: 4
          Status: Optimal within solver tolerances
          Constraints: within
        Method: expected_rank
          Loss: 0.3226
          Disclosed: 63.4%
          Grades: 4
          Status: Optimal within solver tolerances
          Constraints: within
        Method: composite
          Loss: 0.3226
          Disclosed: 63.4%
          Grades: 4
          Status: Optimal within solver tolerances
          Constraints: within
        expected_rank: 100.0% of pair relations agree with joint; 0 changed.
        composite: 100.0% of pair relations agree with joint; 0 changed.
        A score-order baseline searches only partitions of its declared
          order. Rows outside the constraints are not eligible solutions.
        i x$table retains bounds, constraints and reasons; x$relations
          retains pair counts.

---

    Code
      cat(format(pr_cached(key), width = 72L), sep = "\n")
    Output
      <postrank_frontier>  8 choices of withholding cost
         Tau  Loss   Disclosed Grades Gap
         0.1  0.1000 0.0%      1      0
         0.15 0.1500 0.0%      1      0
         0.2  0.2000 0.0%      1      0
         0.25 0.2500 0.0%      1      0
         0.3  0.2942 30.1%     3      0
         0.35 0.3226 63.4%     4      5.55e-17
         0.4  0.3381 70.1%     4      1.11e-16
         0.45 0.3524 71.7%     4      1.11e-16
        Changing tau changes the loss. Compare grades and disclosure across
          rows; do not rank methods by losses computed at different tau
          values.
        Solver gaps limit comparisons; missing bounds or grades leave the
          corresponding conclusions unavailable.
        i x$table retains each status, criterion loss and error among
          disclosed pairs.

---

    Code
      cat(format(pr_cached(key), width = 72L), sep = "\n")
    Output
      <postrank_commonality_cost>  3 criteria sharing one grade assignment
        Each criterion's separate calculation uses the same withholding
          cost and grade limit.
        Criterion error limits in separate calculations: removed.
         Criterion Common loss Own loss Cost lower Cost upper
         poverty   0.2142      0.1903   0.0239     0.0239
         frl       0.2368      0.2038   0.0330     0.0330
         snap      0.6251      0.1795   0.4455     0.4455
        Own loss is the best validated separate action. Cost limits use its
          solver lower bound, so an unfinished solve can leave a range or NA.
        i x$table also records solver status, disclosure and agreement for
          each separate calculation.

---

    Code
      cat(format(pr_cached("analysis_30x3_tau35")$report_card, width = 72L),
      sep = "\n")
    Output
      <postrank_report_card>  30 entities with grades and marginal intervals
        90.0% central intervals; summaries of the declared posterior.
         Entity  Grade Above Below Withheld
         site003 1     28    0      1
         site010 1     28    0      1
         site029 2     14    2     13
         site028 2     14    2     13
         site027 2     14    2     13
         site019 2     14    2     13
         site017 2     14    2     13
         site012 2     14    2     13
         site008 2     14    2     13
         site025 2     14    2     13
        Showing 10 of 30 rows; the full table is retained in the object.
        Above and below count disclosed relations; withheld counts entities
          sharing the grade.
        i as.data.frame(x) includes every criterion's mean, interval and
          expected rank.

