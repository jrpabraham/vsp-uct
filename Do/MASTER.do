version 13.1
clear all
clear matrix
clear mata
cap log close
set matsize 5000
set maxvar 20000
set more off
set seed 479316908

global root "/Users/Justin/Repos/vsp-uct"
global ado_dir "$root/Ado"
global data_dir "$root/Data"
global output_dir "$root/Tables"
global figs_dir "$root/Figs"
global do_dir "$root/Do"

sysdir set PERSONAL "${ado_dir}"

// Set iterations for FWER p-values
global stepdowniternow = 5

// Set PPP Rate
global ppprate = 0.01601537

********************************************************************************
******************************* DEFINE OUTCOMES ********************************
********************************************************************************

global regvars ""

*** MAIN PAPER OUTCOMES  ***
//Indexes: Main Paper Tables 1, 2 and 3
global indices_ppp "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"
global indices_weighted "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index psy_index_z ih_overall_index_z"

//Psychological Wellbeing - Main Paper Table 4
global psyvars "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"
global psyvars_weighted "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"
global psyvars_weighted2 "psy_lncort_mean psy_lncort_mean_clean psy_cesdscore psy_worries_z psy_stressscore_z psy_hap_z psy_sat_z psy_trust_z psy_locus_z psy_scheierscore_z psy_rosenbergscore_z psy_index_z"

//Consumption - Main Paper Table 5
global cons_final "cons_allfood_ppp_m cons_cereals_ppp_m cons_meatfish_ppp_m cons_alcohol_ppp_m cons_tobacco_ppp_m cons_social_ppp_m cons_med_total_ppp_m  cons_ed_ppp_m cons_nondurable_ppp"

//Combined Assets and Enterprise - Main Paper Table 6
global assets_short "asset_total_ppp asset_livestock_ppp asset_durable_ppp asset_savings_ppp asset_land_owned_total asset_niceroof"
global ent_short "ent_wagelabor ent_ownfarm ent_nonagbusiness ent_total_rev_ppp ent_total_cost_ppp ent_total_profit_ppp"

*** APPENDIX OUTCOMES ***
// Indexes in Logs
global indicesln "asset_lntotal_ppp cons_lnnondurable_ppp ent_lntotal_rev_ppp"

// households only
global indices_ppphh "asset_total_ppp cons_nondurable_ppp ent_total_rev_ppp fs_hhfoodindexnew med_hh_healthindex ed_index"

// Detailed Consumption: 1) Levels; 2) Logs
global consvarsnew_ppp_m "cons_allfood_ppp_m cons_ownfood_ppp_m cons_boughtfood_ppp_m cons_cereals_ppp_m cons_meatfish_ppp_m cons_fruitveg_ppp_m cons_dairy_ppp_m cons_fats_ppp_m cons_sugars_ppp_m cons_otherfood_ppp_m cons_alcohol_ppp_m cons_tobacco_ppp_m cons_med_total_ppp_m cons_med_children_ppp_m cons_ed_ppp_m cons_social_ppp_m cons_other_ppp cons_nondurable_ppp"
global consvarsln_ppp_m "cons_lnallfood_ppp_m cons_lnownfood_ppp_m cons_lnboughtfood_ppp_m cons_lncereals_ppp_m cons_lnmeatfish_ppp_m cons_lnfruitveg_ppp_m cons_lndairy_ppp_m cons_lnfats_ppp_m cons_lnsugars_ppp_m cons_lnotherfood_ppp_m cons_lnalcohol_ppp_m cons_lntobacco_ppp_m cons_lnmed_total_ppp_m cons_lnmed_children_ppp_m cons_lned_ppp_m cons_lnsocial_ppp_m cons_lnother_ppp cons_lnnondurable_ppp"

// Detailed Assets: 1) Levels; 2) Logs; (3) Levels with no metal roof variable
global assetvarsshort_ppp "asset_total_noroof_ppp asset_livestock_ppp asset_cows_ppp asset_smalllivestock_ppp asset_birds_ppp  asset_durable_ppp asset_furniture_ppp asset_ag_ppp asset_radiotv_ppp asset_trans_ppp asset_appliance_ppp asset_phone_ppp asset_savings_ppp asset_land_owned_total asset_niceroof"
global assetvarsln_ppp "asset_lntotal_noroof_ppp asset_lnlivestock_ppp asset_lncows_ppp asset_lnsmallstock_ppp asset_lnbirds_ppp asset_lndurable_ppp asset_lnfurniture_ppp asset_lnag_ppp asset_lnradiotv_ppp asset_lntrans_ppp asset_lnappliance_ppp asset_lnphone_ppp asset_lnsavings_ppp"
global assetvarsnoroof_ppp "asset_total_noroof_ppp asset_livestock_ppp asset_cows_ppp asset_smalllivestock_ppp asset_birds_ppp  asset_durable_ppp asset_furniture_ppp asset_ag_ppp asset_radiotv_ppp asset_trans_ppp asset_appliance_ppp asset_phone_ppp asset_savings_ppp asset_land_owned_total"

// Detailed Enterprise: 1) Levels; 2) Logs; 3) Conditional on Business Ownership
global entvars_ppp "ent_wagelabor ent_ownfarm ent_business ent_nonagbusiness ent_employees ent_nonag_revenue_ppp ent_nonag_flowcost_ppp ent_nonag_profit_ppp ent_nonag_profit_self_ppp ent_nonag_durables_ppp ent_farmrevenue_ppp ent_farmexpenses_ppp ent_farmprofit_ppp ent_animalflowrev_ppp ent_animalflowcost_ppp ent_animalflowprofit_ppp ent_animalstockrev_ppp ent_total_rev_ppp ent_total_cost_ppp ent_total_profit_ppp"
global entvarsln_ppp "ent_lnnonag_revenue_ppp ent_lnnonag_flowcost_ppp ent_lnnonag_profit_ppp ent_lnnonag_pro_slf_ppp ent_lnnonag_durables_ppp ent_lnfarmrevenue_ppp ent_lnfarmexpenses_ppp ent_lnfarmprofit_ppp ent_lnanimalflowrev_ppp ent_lnanimalflowcost_ppp ent_lnanimalflowprofit_ppp ent_lnanimalstockrev_ppp ent_lntotal_rev_ppp ent_lntotal_cost_ppp ent_lntotal_profit_ppp"
global entvars_cond_ppp "ent_nonag_revenue_ppp ent_nonag_flowcost_ppp ent_nonag_profit_ppp ent_nonag_profit_self_ppp ent_nonag_durables_ppp"

// Food Security
global fsvars "fs_adskipm_often fs_adwholed_often fs_chskipm_often fs_chwholed_often fs_hhcheapf_often fs_hhfriendf_often fs_foodcred_often fs_wildf_often fs_hhbeg_often fs_2meals fs_eatcont fs_meat fs_enoughtom fs_sleephun fs_selfprotein fs_hhfracprotein fs_childfracprotein  fs_childfoodindexnew fs_hhfoodindexnew"

// Health
global medvars_ppp "med_expenses_hh_ppp_ep med_expenses_sp_ppp_ep med_expenses_child_ppp_ep med_portion_sickinjured med_port_sick_child med_afford_port med_sickdays_hhave med_healthconsult med_vacc_newborns med_child_check med_u5_deaths bmitoage_HH_z heighttoage_HH_z weighttoage_HH_z armcirctoage_HH_z med_child_healthindex med_hh_healthindex"

// Education
global edvars_ppp "ed_expenses_ppp ed_expenses_perkid_ppp ed_schoolattend ed_sch_missedpc ed_work_act_pc ed_index"

// Household Finances
global finvars_ppp "fin_loansout_ppp fin_loan_norepay fin_remittances_sent_ppp fin_remittances_rec_ppp fin_remittances_net_ppp"

// Labor Variables
global laborvars "hh_propsalaried hh_propcasual hh_workactivities labor_primary wage_expenditures"

// Durable and Nondurable Investment
global investvars "durable_investment nondurable_investment"

*** CONTROL VARIABLES ***
// Main Effect Controls
global baselinecontrols "b_age b_married b_edu b_children b_hhsize asset_total_ppp0 cons_total_ppp0 ent_wagelabor0 ent_ownfarm0 ent_business0 ent_nonagbusiness0"

// Controls for Spillover analysis
global spillovercontrols "b_age b_married b_children b_hhsize b_edu"

// Controls for Unmatched HH analysis
global unmatched_vars "b_age b_married b_edu b_children b_hhsize ent_wagelabor0 ent_ownfarm0 ent_nonagbusiness0"

// Timing Controls
global timecontrols "endline_timing"

// MPESA ANALYSIS
global mpesavars "given_mpesa amount_given_mpesa received_mpesa amount_received_mpesa net_mpesa saved_mpesa amount_saved_mpesa"

********************************************************************************
********************************* CHECK DATA ***********************************
********************************************************************************

use "$data_dir/UCT_FINAL_CLEAN.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_MetalRoofHHs.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_UNMATCHED.dta", clear
datasignature confirm, strict

use "$data_dir/UCT_Village_Collapsed.dta", clear
datasignature confirm, strict

***********************************************************************************
******************************* Spillover effects *********************************
***********************************************************************************

global regvars ""indices_ppp""
do "$do_dir/UCT_SqDev_Regs.do"
do "$do_dir/UCT_AbsDev_Regs.do"


/* Notes

NB: more spillovers with households that look the same?
JH: more SUTVA violations with households that look the same?
JA: interact eq 10 with dummy for looking the same
    dummy calculated as deviations from the mean?
    using what characteristics?
    can't do this for control group because no baseline
Anyway
    Find treatment village mean of the demovar
    Calculate some distance from spillover household demovar
    Dichotomize or leave as is
    Can do treatment effects for other treatment arms
Potential dimensions of similarity
    the dependent variable*
    all dependent variables
    whatever is in the baseline balance table
    everything
    some ML criteria
