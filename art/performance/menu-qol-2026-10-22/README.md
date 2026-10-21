# R43 menu and loading checks

See [menu design and playtest](../../../docs/menu-qol.md). Screenshots are native
source UI, with an isolated stationary railway fixture for dispatch. The loading
screenshot illustrates the station phase; startup.log is the real ERS load.

All source integration checks pass, including production menu return after draining
GPU-backed streaming while the render loop is alive. Unit suite: 773/773. No simulation/prepared
data changes, full-day reruns, distribution gameplay or target-PC benchmark.

Startup timing was collected on the development Radeon 780M PC while other verification/packaging work
was active. It demonstrates successful worker/attachment completion with
a stationary clock, and is not a controlled performance comparison.
