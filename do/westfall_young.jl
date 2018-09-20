using DataFrames, GLM, CSV, Random, StatsBase

# df = CSV.read(
#     "./data/ready_analysis.csv", 
#     delim = ',',
#     rows_for_type_detect = 2000) |> DataFrame

## set covariates
ate_ctrls=
[:ageover60,
    :age40_60,
    :age20_40,
    :yrs_edu,
    :female,
    :stranger,
    :christian,
    :minority,
    :cashearn_imputedhst,
    :noland,
    :farm_sizehst,
    :houseoccupy_ec2,
    :houseclaim_ec2,
    :housepalavapostwar_ec2,
 #=   :farmclaim_ec2, =#
    :farmpalavapostwar_ec2]
ate_ctrls_leader=[
    :ageover60,
    :age40_60,
    :age20_40,
    :yrs_edu,
    :female,
    :stranger,
    :christian,
    :minority,
    :cashearn_imputedhst]
ate_ctrls_apsr=[
    :ageover60,
    :age40_60,
    :age20_40,
    :yrs_edu,
    :female,
    :stranger,
    :christian,
    :minority,
    :cashearn_imputedhst,
    :noland,
    :farm_sizehst,
    :land_sizehst,
    :housetake_dum,
    :lndtake_dum]

## Set outcomes 
land_conflict_paper = [ #=
    :anylndconf_u_ec2,
    :unrslv_lnd_conf_u_ec2,
    :conf_any_u_ec2,
        :conf_dam_violence_bin_u,
        :conf_threat_u_ec2,
        :conf_damage_u_ec2,
        :conf_viol_u_ec2, =#
    :conf_length_max_c_ec2,
    :forum_lastsuc_c_ec2  ,
    :conf_any_c_ec2        ,
        :conf_dam_violence_bin_c,
        :conf_threat_c_ec2,
        :conf_damage_c_ec2,
        :conf_viol_c_ec2,
        :conf_witch_c_ec2]

all_conflict_paper = [   
    :lmg_conf_u_ec2,
    :lmg_unrslv_conf_u_ec2,
    :lmg_conf_any_u_ec2,
    :lmg_forum_lastsuc_c_ec2,
        :lmg_forum_inf_suc_c_ec2,
    :lmg_conf_any_c_ec2,
        :lmg_conf_dam_violence_bin_c,
            :lmg_conf_threat_c_ec2,
            :lmg_conf_damage_c_ec2,
            :lmg_conf_viol_c_ec2]

conflict_adj_p = [
    :anylndconf_u_ec2,
    :unrslv_lnd_conf_u_ec2,
    :conf_any_u_ec2,
       :conf_dam_violence_bin_u,
       :conf_threat_u_ec2,
       :conf_damage_u_ec2,
       :conf_viol_u_ec2,
    :conf_length_max_c_ec2,
    :forum_lastsuc_c_ec2,
    :conf_any_c_ec2,
       :conf_dam_violence_bin_c,
       :conf_threat_c_ec2,
       :conf_damage_c_ec2,
       :conf_viol_c_ec2,
       :conf_witch_c_ec2,
    :lmg_conf_u_ec2,
    :lmg_unrslv_conf_u_ec2,
    :lmg_conf_any_u_ec2,
    :lmg_forum_lastsuc_c_ec2,
       :lmg_forum_inf_suc_c_ec2,
    :lmg_conf_any_c_ec2,
       :lmg_conf_dam_violence_bin_c,
           :lmg_conf_threat_c_ec2,
           :lmg_conf_damage_c_ec2,
           :lmg_conf_viol_c_e]
comm_ctrls = [
    :district1, :district2, :district3, :district4, :district5, :district6, :district7, 
    :district8, :district9, :district10, :district11, :district12, :district13, :district14, 
    :vsmall,
    :small,
    :small2,
    :small3,
    :quartdummy,
    :cedulevel_bc,
    :ctownhh_log_el2,
    :cwealthindex_bc,
    :cviol_experienced_bc,
    :clndtake_bc,
    :cviol_scale_bc,
    :clandconf_scale_bc,
    :cwitchcraft_scale_bc,
    :cpalaviol_imputed_bc,
    :cprog_ldr_beliefs_bc,
    :cattitudes_tribe_bc,
    :crelmarry_bc]


function formulaBuilder(
    y::Symbol, 
    treat::Symbol, 
    covariates::Vector{Symbol})

    function expandargs(x)
        :(+$(x...))
    end
    t = @eval @formula($y ~ $treat + $(expandargs(covariates)))
    return t 
end

function regress(
    df::DataFrame,
    y::Symbol, 
    treat::Symbol, 
    covariates::Vector{Symbol}, 
    weight::Symbol, 
    subset::Symbol)

    d = df[isequal.(df[subset], 1), [y;treat;covariates;weight]]
    dropmissing!(d)
    disallowmissing!(d)
    show(describe(d))
    formula = formulaBuilder(y, treat, covariates)
    #m = lm(formula, d, wts = d[weight])
    m = glm(formula, d, Normal(), IdentityLink(), wts = d[weight], allowrankdeficient = true)
    # simulated p-values 
    N = 10
    sim_ps = Vector{Float64}(undef, N)
    for i in 1:N 
        t = sample(1:nrow(d), nrow(d))
        p = d[t, :]
        try 
            sim_m = glm(formula, p, Normal(), IdentityLink(), wts = p[weight])
            sim_ps[i] =  coeftable(sim_m).cols[4][2].v

        catch 
            return p
        end
    end
    return Float64[
        coeftable(m).cols[1][2],
        coeftable(m).cols[2][2],
        coeftable(m).cols[3][2],
        coeftable(m).cols[4][2].v] 
end
results = DataFrame(
    variable = Symbol[], 
    beta = Float64[], 
    std_error = Float64[], 
    z_value = Float64[], 
    p_value = Float64[])

arr = 0
for y in land_conflict_paper
    global arr
    arr = regress(df, y, :assigned_ever, [ate_ctrls; comm_ctrls], :weight_e1_e2, :ENDLINE2_RESIDENT)
  #  push!(results, [y; arr])
end

##





