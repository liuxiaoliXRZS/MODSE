-- This code is used to extracted the cohort of our study for MODSE
-- By Xiaoli Liu
-- 2018.06.14


-- This study's cohort :
--      1. mods >= 2; 2. age >= 65; 3. first_hospital + icu; 4. not bad data; 5. intime >= admittime
--      6. study icu time > 24h; 7. exist heart rate, sbp, dbp, respiratory, spo2, temp, gcs
DROP MATERIALIZED VIEW IF EXISTS study_cohort_modse CASCADE;
CREATE MATERIALIZED VIEW study_cohort_modse as

with mods_initial as (
  select icustay_id
  from pivoted_mods
  where mods_24hours >= 2
  group by icustay_id
)

, mods_initial_1 as (
  select icud.subject_id
  , icud.hadm_id
  , icud.icustay_id
  , icud.gender
  , case 
  when icud.age > 89 then 91.4 else icud.age end as age 
  , icud.admittime
  , icud.dischtime
  , icud.intime
  , icud.outtime
  , icud.los_hospital
  , icud.los_icu
  , case 
       when icud.ethnicity in (
        'ASIAN'
      , 'ASIAN - ASIAN INDIAN'
      , 'ASIAN - CAMBODIAN'
      , 'ASIAN - CHINESE'
      , 'ASIAN - FILIPINO'
      , 'ASIAN - JAPANESE'
      , 'ASIAN - KOREAN'
      , 'ASIAN - OTHER'
      , 'ASIAN - THAI'
      , 'ASIAN - VIETNAMESE'  
        ) then 'ASIAN'
       when icud.ethnicity in (
      'BLACK/AFRICAN'
      , 'BLACK/AFRICAN AMERICAN'
      , 'BLACK/CAPE VERDEAN'
      , 'BLACK/HAITIAN'
      , 'CARIBBEAN ISLAND'
        ) then 'BLACK'
       when icud.ethnicity in (
      'HISPANIC OR LATINO'
      , 'HISPANIC/LATINO - CENTRAL AMERICAN (OTHER)'
      , 'HISPANIC/LATINO - COLOMBIAN'
      , 'HISPANIC/LATINO - CUBAN'
      , 'HISPANIC/LATINO - DOMINICAN'
      , 'HISPANIC/LATINO - GUATEMALAN'
      , 'HISPANIC/LATINO - HONDURAN'
      , 'HISPANIC/LATINO - MEXICAN'
      , 'HISPANIC/LATINO - PUERTO RICAN'
      , 'HISPANIC/LATINO - SALVADORAN'
        ) then 'HISPANIC'
       when icud.ethnicity in (
      'WHITE'
      , 'WHITE - BRAZILIAN'
      , 'WHITE - EASTERN EUROPEAN'
      , 'WHITE - OTHER EUROPEAN'
      , 'WHITE - RUSSIAN'
        ) then 'WHITE'
       when icud.ethnicity not in (
      'ASIAN'
      , 'ASIAN - ASIAN INDIAN'
      , 'ASIAN - CAMBODIAN'
      , 'ASIAN - CHINESE'
      , 'ASIAN - FILIPINO'
      , 'ASIAN - JAPANESE'
      , 'ASIAN - KOREAN'
      , 'ASIAN - OTHER'
      , 'ASIAN - THAI'
      , 'ASIAN - VIETNAMESE'     
      , 'BLACK/AFRICAN'
      , 'BLACK/AFRICAN AMERICAN'
      , 'BLACK/CAPE VERDEAN'
      , 'BLACK/HAITIAN'
      , 'CARIBBEAN ISLAND'     
      , 'HISPANIC OR LATINO'
      , 'HISPANIC/LATINO - CENTRAL AMERICAN (OTHER)'
      , 'HISPANIC/LATINO - COLOMBIAN'
      , 'HISPANIC/LATINO - CUBAN'
      , 'HISPANIC/LATINO - DOMINICAN'
      , 'HISPANIC/LATINO - GUATEMALAN'
      , 'HISPANIC/LATINO - HONDURAN'
      , 'HISPANIC/LATINO - MEXICAN'
      , 'HISPANIC/LATINO - PUERTO RICAN'
      , 'HISPANIC/LATINO - SALVADORAN'
      , 'WHITE'
      , 'WHITE - BRAZILIAN'
      , 'WHITE - EASTERN EUROPEAN'
      , 'WHITE - OTHER EUROPEAN'
      , 'WHITE - RUSSIAN'
        ) then 'OTHER'
       else null end as ethnicity
  , icud.admission_type
  , case 
  when ad.deathtime <= ad.dischtime then 1
  else 0 end as death_hosp
  , case 
  when EXTRACT(EPOCH FROM (ad.deathtime - ad.dischtime))/60.0/60.0/24 <= 28 then 1
  else 0 end as death_28_day
  , case 
  when EXTRACT(EPOCH FROM (ad.deathtime - ad.dischtime))/60.0/60.0/24 <= 90 then 1
  else 0 end as death_90_day
  , ie.first_careunit   
  from icustay_detail icud 
  inner join icustays ie 
  on icud.icustay_id = ie.icustay_id
  inner join mods_initial mi 
  on icud.icustay_id = mi.icustay_id
  inner join admissions ad 
  on icud.subject_id = ad.subject_id
  and icud.hadm_id = ad.hadm_id 
  and ad.HAS_CHARTEVENTS_DATA = 1
  where icud.age >= 65
  and icud.first_hosp_stay = 'Y'
  and icud.first_icu_stay = 'Y'
  and icud.intime >= icud.admittime
  and EXTRACT(EPOCH FROM (icud.outtime - icud.intime))/60.0/60.0 > 24
  -- order by icud.icustay_id
)

, gcs as (
  select gcsp.icustay_id
  from pivoted_gcs gcsp
  inner join mods_initial_1 mi 
  on gcsp.icustay_id = mi.icustay_id
  WHERE gcsp.gcs > 0
  and gcsp.charttime between mi.intime and mi.intime + interval '1' day
  group by gcsp.icustay_id
)


select mi.*
from vitalsfirstday vs 
inner join mods_initial_1 mi 
on vs.icustay_id = mi.icustay_id
inner join gcs 
on vs.icustay_id = gcs.icustay_id
where vs.heartrate_min is not null
and vs.sysbp_min is not null 
and vs.diasbp_min is not null 
and vs.resprate_min is not null
and vs.spo2_min is not null
and vs.tempc_min is not null
order by mi.icustay_id