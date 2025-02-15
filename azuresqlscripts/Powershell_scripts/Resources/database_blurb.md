Affected Databases:

Potentially all of them if they are using server admin for anything.

When we change their server admin secret it might affect something we haven't seen

The only connections I've actually identified using admin are:

To ModCop coming from several R apps
To AFC-DSE-HUB-DB from one R app
To the 3 Griffin databases (dev, test, prod) on AI2C server from "run-plumber-api-57xds-46phw" (likely container process) and "CAZVW0FVAA1-154" (AVD)

Other than that, only one database has an "admin" user that probably should have and 8570 validation: Maxine Drake is a principal in the master database on FCC server


