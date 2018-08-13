
# helper function for purrr map: downloads and scrapes session webpage given a link, gets names of authors and papers in that session
get_talks <- function(link, message) {

    print(str_c("scraping url ", message, ": ", link))

    readLines("scrape.js") %>%
        # `[`(-3) %>%
        # append(str_c("var url ='", link ,"';"), after = 2) %>%
        str_replace(pattern = "var url ='[[a-zA-Z0-9?=&:/._-]]+';", replacement = str_c("var url ='", link ,"';")) %>%
        writeLines("scrape.js")

    system("phantomjs scrape.js")

    list.talks <-
        read_html("1.html") %>%
        html_nodes("#paperData") %>%
        html_table()

    if (!is_empty(list.talks)) {
        list.talks %>%
            `[[`(1) %>%
            as_tibble() %>%
            mutate(X1 = str_replace_all(X1, "  ", " "),
                   separator = X1 == "",
                   talk = cumsum(separator) + 1) %>%
            filter(!separator) %>%
            select(-separator) %>%
            group_by(talk) %>%
            mutate(entry = case_when(row_number() == 1 ~ "talk.title",
                                     row_number() >  1 ~ str_c("author", row_number() - 1))) %>%
            ungroup() %>%
            spread(entry, X1) %>%
            gather(author, authorinfo, starts_with("author")) %>%
            filter(!is.na(authorinfo)) %>%
            select(talk, authorinfo, talk.title) %>%
            arrange(talk, authorinfo) %>%
            separate(authorinfo, into = c("author", "affiliation"), sep = ", ", extra = "merge")
    }
}


# first download and scrape SEA conference webpage with a list of all sessions, afterwards get their id numbers, construct links from those ids
link <- "https://www.southerneconomic.org/current-year-program/?conferenceId=4"

waittime <- 2500

readLines("scrape.js") %>%
    # `[`(-3) %>%
    # append(str_c("var url ='", link ,"';"), after = 2) %>%
    str_replace(pattern = "var url ='[[a-zA-Z0-9?=&:/._-]]+';", replacement = str_c("var url ='", link ,"';")) %>%
    str_replace(pattern = "var waittime = [[0-9]]+;", replacement = str_c("var waittime = ", waittime ,";")) %>%
    writeLines("scrape.js")

system("phantomjs scrape.js")

# sea.2018.sessions.names <-
#     read_html("1.html") %>%
#     html_table(fill = TRUE) %>%
#     `[`(-1) %>%
#     bind_rows() %>%
#     as_tibble() %>%
#     mutate(X1 = str_replace(X1, "Session ", "")) %>%
#     rename(session.code = X1,
#            session.name = X2)
#
# sea.2018.sessions.links <-
#     read_html("1.html") %>%
#     str_extract_all(pattern = 'id=\"session-' %R% dgt(4)) %>%
#     unlist() %>%
#     str_replace(pattern = 'id=\"session-', "https://www.southerneconomic.org/session-details/?conferenceId=4&eventId=")

# use helper function to get authors and papers in every session
print(str_c("Scraping webpages for ", nrow(tbl.sea.2018.sessions), " sessions"))

tbl.sea.2018.sessions <-
    read_html("1.html") %>%
    str_match_all(pattern = "Session " %R%
                      capture(DGT %R% DOT %R% UPPER %R% DOT %R% one_or_more(DGT)) %R%
                      fixed('</strong></td>') %R% NEWLINE %R% fixed('<td class="width-70 vertical-align session-') %R%
                      capture(dgt(4)) %R% fixed('">') %R% optional(SPC) %R%
                      fixed('<a class="navigation-cursor session-detail" id="session-') %R% dgt(4) %R% '">' %R%
                      capture(one_or_more(WRD %R% optional(PUNCT) %R% optional(SPC))) %R% "</a>") %>%
    `[[`(1) %>%
    as_tibble() %>%
    mutate(session.code = V2,
           session.url = str_c("https://www.southerneconomic.org/session-details/?conferenceId=4&eventId=", V3),
           session.name = V4) %>%
    mutate(message = str_c(row_number(), " out of ", n())) %>%
    mutate(session.talks = map2(session.url, message, ~get_talks(.x, .y))) %>%
    select(session.code, session.url, session.name, session.talks)

beep()
