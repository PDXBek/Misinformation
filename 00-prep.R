# This is the R equivalent of the shell script (below) that ws run to
# pre-process the MS Word documents for analysis.
#
# for f in *.docx ; do pandoc -t plain "$f" -o "$f.txt"; done

library(processx)
library(tidyverse)

pandoc <- Sys.which("pandoc")

list.files("source-docs", pattern=".*docx$", full.names=TRUE) %>%
  walk(~{
    message(sprintf("Working on %s ...", basename(.x)))
    processx::run(pandoc, c("--to=plain", .x, "--wrap=none", sprintf("--output=%s.txt", .x)))
  })

