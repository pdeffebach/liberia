# power calculations
library(tidyverse)
library(haven)
library(ICC)
library(knitr)
library(kableExtra)

df <- haven::read_dta("data/power_calcs.dta")
vars_to_power <- c(
    "anylndconf_u_ec2",
    "unrslv_lnd_conf_u_ec2",
    "conf_any_u_ec2",
    "lmg_conf_u_ec2",
    "lmg_unrslv_conf_u_ec2",
    "lmg_conf_any_u_ec2") 

# hard coded for now, so dont change the list above!
control_means <- c(
    0.087,
    0.024,
    0.041,
    0.306,
    0.064,
    0.101
    )

treatment_effects <- c(
    .008,
    .002,
    -.012,
    .012,
    -.004,
    -.015
    ) 

treatment_ses <- c(
    0.011,
    0.005,
    0.006,
    0.017,
    0.009,
    0.010) 

makeVlist <- function(dta) { 
     labels <- sapply(dta, function(x) attr(x, "label"))
      tibble(variable = names(labels),
             label = labels)
}
labels = makeVlist(df[,vars_to_power])

effect_sizes = vector()
for(var in vars_to_power) {
    # get the intra-class correlation
    icc = ICCbare(df$commcode, df[[var]])
    # get the within-group variance
    model = anova(lm(df[[var]] ~ factor(df[["commcode"]])))
    varw = model[["Mean Sq"]][1]
    effect_size = crtpwr.2mean(
        alpha = .05, 
        power = .08, 
        m = 102, 
        n = 20, 
        cv = 0, 
        d = NA, 
        icc = icc, 
        varw = varw)
    effect_sizes <- c(effect_sizes, effect_size)
}
powers = tibble(
    variable = vars_to_power, 
    mde = effect_sizes, 
    treatment_effect = treatment_effects, 
    control_mean = control_means,
    treatment_se = treatment_ses)

powers <- powers %>%     
    inner_join(labels, by = "variable") %>% 
    mutate(standardized_treatment_effect = treatment_effect / treatment_se) %>%
    mutate(effect_as_pct_mde = abs(standardized_treatment_effect) / mde) 


out <- powers %>% select(label, standardized_treatment_effect, mde, effect_as_pct_mde)

table = kable(
    out, 
    format = "html",
    col.names = c("", "(1)", "(2)", "(3)"),
    escape = FALSE,
     digits = 3,
     align = c("l", "c", "c", "c"), 
     booktabs = T) %>%
add_header_above(c("Dependent variable", "at Endline 2", "able effect", "as % of MDE")) %>%
add_header_above(c("", "Treatment effect", "Minimum detect-", "Treatment effect")) %>% 
cat(., file = "out/tables/power_calcs.html")

###

