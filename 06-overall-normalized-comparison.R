#' ---
#' title: "Overall Lists (normalized)"
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

#+ data, cache=TRUE

# Read in the documents into a data frame
list.files("source-docs", pattern=".*txt$", full.names=TRUE) %>%
  map_df(~{
    data_frame(
      doc = tools::file_path_sans_ext(tools::file_path_sans_ext(basename(.x))),
      text = read_lines(.x) %>% paste0(collapse=" ") %>% stri_trans_tolower()
    )
  }) %>%
  mutate(text = stri_replace_all_regex(text, "[[:punct:]]", "")) %>%
  mutate(doc_id = substr(doc, 1, 30)) -> corpus

# Get rid of words with numbers
unnest_tokens(corpus, word, text) %>%
  filter(!stri_detect_regex(word, "[[:digit:]]")) -> one_grams

count(one_grams, doc_id) %>%
  rename(total_words = n) -> total_words

list(
  explanatory = read_lines("lists/explanatory.csv"),
  retractors = read_lines("lists/retractors.csv"),
  sourcing = read_lines("lists/sourcing.csv"),
  uncertainty = read_lines("lists/uncertainty.csv")
) -> word_lists

map_df(names(word_lists), ~{

  map_df(word_lists[[.x]], ~{
    group_by(corpus, doc_id) %>%
      summarise(keyword = .x, ct = stri_count_regex(text, sprintf("\\W%s\\W", .x)))
  }) %>%
    mutate(doc_num = as.character(as.numeric(factor(doc_id)))) %>%
    mutate(ct = ifelse(ct == 0, NA, ct)) %>%
    count(doc_id, wt=ct) %>%
    mutate(doc_num = as.character(as.numeric(factor(doc_id)))) %>%
    left_join(total_words) %>%
    mutate(pct = n/total_words) %>%
    mutate(list = .x)
}) -> overall

#' ## ID to Doc Name mapping:

distinct(overall, doc_id, doc_num) %>%
  left_join(total_words) %>%
  kable()

#' ## Overall

#+ overall_heatmap
ggplot(overall, aes(doc_num, list, fill=pct)) +
  geom_tile(color="#2b2b2b", size=0.125) +
  scale_x_discrete(expand=c(0,0)) +
  scale_y_discrete(expand=c(0,0)) +
  viridis::scale_fill_viridis(direction=-1, na.value="white") +
  labs(x=NULL, y=NULL, title="Word List Usage Heatmap (normalized)") +
  theme_ipsum_rc(grid="")
