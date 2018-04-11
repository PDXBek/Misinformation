#' ---
#' title: "Basic exploratoratory analysis (not based on lists)"
#' author: "Rebekah Brown / Bob Rudis"
#' date: ""
#' output:
#'   html_document:
#'     keep_md: true
#'     theme: simplex
#'     highlight: monochrome
#' ---
#+ init, include=FALSE
knitr::opts_chunk$set(message = FALSE, warning = FALSE, echo = FALSE,
                      dev="png", fig.retina = 2, fig.width = 10, fig.height = 6)

#+ libs
library(stringi)
library(ggalt)
library(knitr)
library(viridis)
library(tidytext) # devtools::install_github("juliasilge/tidytext")
library(hrbrthemes)
library(tidyverse)

#+ data
list.files("source-docs", pattern=".*txt$", full.names=TRUE) %>%
  map_df(~{
    data_frame(
      doc = tools::file_path_sans_ext(tools::file_path_sans_ext(basename(.x))),
      text = read_lines(.x) %>% paste0(collapse=" ")
    )
  }) %>%
  mutate(doc_id = substr(doc, 1, 30)) -> corpus

unnest_tokens(corpus, word, text,) %>%
  anti_join(stop_words) %>%
  filter(!stri_detect_regex(word, "[[:digit:],\\._]")) -> one_grams

count(one_grams, doc_id, word) %>%
  rename(freq = n) -> report_words

count(one_grams, doc_id) %>%
  rename(total_words = n) -> total_words

report_words <- left_join(report_words, total_words)

#' ## Take a look at general term frequency distribution by document

#+ general_term_freq, fig.height=10, cache=TRUE
ggplot(report_words, aes(freq/total_words)) +
  geom_density(aes(fill=doc_id)) +
  scale_y_comma(name=NULL) +
  facet_wrap(~doc_id, scales="free_y") +
  labs(x="Term frequency", title="Term frequency distribution") +
  theme_ipsum_rc(grid="XY") +
  theme(legend.position="none")

#' ## TF-IDF / Top 10 per doc
report_words %>%
  bind_tf_idf(word, doc_id, freq) %>%
  select(-total_words) %>%
  arrange(desc(tf_idf)) -> report_words

group_by(report_words, doc_id) %>%
  arrange(desc(tf_idf)) %>%
  slice(1:10) %>%
  ungroup() -> top_10_tf_idf

#+ tfidf_tables, results="asis"
select(top_10_tf_idf, doc_id, word) %>%
  DT::datatable()
