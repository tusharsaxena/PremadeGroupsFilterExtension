local _, NS = ...
-- modules/EnvInject.lua — the PGF env post-hook body: region and pgfe_* variables.
--
-- Stub: publishes its namespace table so the TOC load order and the suite list are wired before
-- the module is written (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 6).

NS.EnvInject = NS.EnvInject or {}
