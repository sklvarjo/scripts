# OC Cheatsheet

# Resource Quotas
Samat tiedot kuin mitä on consolen Administration -> ResourceQuotas saa komennolla

`oc get AppliedClusterResourceQuota`

ja sitten

`oc describe <name>`

tai jos haluaa kaikki kerralla

`oc describe AppliedClusterResourceQuota`

**NOTE:** ock-klusterilla projekti voidaan irroittaa presonal quotasta ja antaa projekti kohtainen quota. -SPartio


