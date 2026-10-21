# R43 menu and loading checks

See [menu design and playtest](../../../docs/menu-qol.md). Screenshots are native
source UI, with an isolated stationary railway fixture for dispatch. The loading
screenshot illustrates the station phase; startup.log is the real ERS load.

All source integration checks pass. Unit suite: 773/773. No simulation/prepared
data changes, full-day reruns, distribution gameplay or target-PC benchmark.

Startup timing was collected on the development Radeon 780M PC while unit checks
were also running. It demonstrates successful worker/attachment completion with
a stationary clock, and is not a controlled performance comparison.
