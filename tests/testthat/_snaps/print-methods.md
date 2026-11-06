# captured console boxes (snapshot)

    Code
      cat(format(a, width = 72, tier = 2), sep = "\n")
    Output
      <postrank_analysis>  3 entities in 2 grades (sizes 1 / 2)
        2 criteria: need_A, need_B.
        Posterior loss: 0.3708.
        Disclosed 2 of 3 pairs (66.7%); withheld 1.
        Expected error among disclosed pairs: need_A 0.125; need_B 0.891.
        Solver: Optimal within solver tolerances.
        Optimization gap: 0; requested absolute gap 1e-08.
        Prepared: report card, fragility.
        Grade 1 has highest priority; a shared grade withholds the comparison.
        grade 1 (1): 001
        grade 2 (2): site-B, site C
        i summary(x) explains the loss, settings and bounds; get_grades(x)
          returns all grades.

---

    Code
      cat(format(a$fit, width = 72, tier = 2), sep = "\n")
    Output
      <postrank_fit>  3 entities in 2 grades (sizes 1 / 2)
        2 criteria: need_A, need_B.
        Posterior loss: 0.3708.
        Disclosed 2 of 3 pairs (66.7%); withheld 1.
        Expected error among disclosed pairs: need_A 0.125; need_B 0.891.
        Solver: Optimal within solver tolerances.
        Optimization gap: 0.
        Grade 1 has highest priority; a shared grade withholds the comparison.
        grade 1 (1): 001
        grade 2 (2): site-B, site C
        i summary(x) explains the loss, settings and bounds; get_grades(x)
          returns all grades.

---

    Code
      cat(format(a$report_card, width = 72, tier = 2), sep = "\n")
    Output
      <postrank_report_card>  3 entities with grades and marginal intervals
        90.0% central intervals; summaries of the declared posterior.
         Entity Grade Above Below Withheld
         001    1     2     0     0
         site-B 2     0     1     1
         site C 2     0     1     1
        Above and below count disclosed relations; withheld counts entities
          sharing the grade.
        i as.data.frame(x) includes every criterion's mean, interval and
          expected rank.

---

    Code
      cat(format(postrank_toy, width = 72, tier = 2), sep = "\n")
    Output
      <postrank_draws>  3 entities with posterior input
        2 criteria: need_A, need_B.
        32 retained IID draws; each draw contains all entities and criteria.
        The input structure has been checked. The declared sampling history
          and statistical model have not been independently verified.
        i summary(x) describes the targets; details = TRUE adds source
          records.

---

    Code
      cat(format(b, width = 72, tier = 2), sep = "\n")
    Output
      <postrank_analysis>  No validated grades
        3 entities. 2 criteria: need_A, need_B.
        No validated grades are available. Loss, grade sizes and disclosed
          comparisons are unavailable.
        Solver: Time limit reached.
        Optimization gap: NA; no usable lower bound is available.
        No optional result tables or checks are available; see summary(x)
          for reasons.
        i summary(x) explains the loss, settings and bounds; get_grades(x)
          returns all grades.

