#' ---
#' title: "Sourcing"
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
unnest_tokens(corpus, word, text,) %>%
  filter(!stri_detect_regex(word, "[[:digit:]]")) -> one_grams

count(one_grams, doc_id) %>%
  rename(total_words = n) -> total_words

word_list <- read_lines("lists/sourcing.csv")

map_df(word_list, ~{
   group_by(corpus, doc_id) %>%
    summarise(keyword = .x, ct = stri_count_regex(text, sprintf("\\W%s\\W", .x)))
}) %>%
  mutate(doc_num = as.character(as.numeric(factor(doc_id)))) %>%
  mutate(ct = ifelse(ct == 0, NA, ct)) -> sourcing_df

#' ## ID to Doc Name mapping:

distinct(sourcing_df, doc_id, doc_num) %>%
  left_join(total_words) %>%
  kable()

#' ## Overall sourcing word frequency per document

#+ overall_sourcing_freq_summary
count(sourcing_df, doc_id, wt=ct) %>%
  mutate(doc_num = as.character(as.numeric(factor(doc_id)))) %>%
  left_join(total_words) %>%
  mutate(pct = n/total_words) %>%
  ggplot(aes(doc_num, pct)) +
  geom_segment(aes(xend=doc_num, yend=0), size=5, color="lightslategray") +
  scale_y_percent() +
  labs(
    x="Document #", y=NULL,
    title="Percent of 'sourcing' words of total words in document corpus"
  ) +
  theme_ipsum_rc(grid="Y")

#' ## General frequency per document

#+ sourcing_frequency, fig.height=8
ggplot(sourcing_df, aes(doc_num, keyword, fill=ct)) +
  geom_tile(color="#2b2b2b", size=0.125) +
  scale_x_discrete(expand=c(0,0)) +
  scale_y_discrete(expand=c(0,0)) +
  viridis::scale_fill_viridis(direction=-1, na.value="white") +
  labs(x=NULL, y=NULL, title='"Sourcing" Frequency') +
  theme_ipsum_rc(grid="")

#' ## Normalized frequency per document

#+ sourcing_normalized, fig.height=8
left_join(sourcing_df, total_words) %>%
  mutate(pct = ct/total_words) %>%
  ggplot(aes(doc_num, keyword, fill=pct)) +
  geom_tile(color="#2b2b2b", size=0.125) +
  scale_x_discrete(expand=c(0,0)) +
  scale_y_discrete(expand=c(0,0)) +
  viridis::scale_fill_viridis(direction=-1, na.value="white") +
  labs(x=NULL, y=NULL, title='"Sourcing" Frequency (normalized)') +
  theme_ipsum_rc(grid="")




