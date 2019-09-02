# Changelog

## 1.0.3
- Add upstart support
- Fix monit service name

## 1.0.2
- Fix deployment flow hooks

## 1.0.1
- Add deploy failure handling @phillbaker
- Support custom monit filename @zocoi
- Systemd Integration @baierjan
- Fix regression in sidekiq_roles variable
- Fixed pidfile accounting per process @jsantos
- Rubocop corrections for main task @jsantos

## 1.0.0

- Prepend underscore before service name index @Tensho
- Convert CHANGELOG to Markdown @Tensho
- Drop support for capistrano 2.0 @Tensho
- *BREAKING CHANGE* If people used custom monit template, they should adjust it to use pid_files variable instead of processes_pids. @Tensho
- *BREAKING CHANGE* `:sidekiq_role` has been renamed to its plural form, `:sidekiq_roles`

## 0.20.0

- Use new capistrano DSL for reenable tasks @Tensho

## 0.10.0

- Fix Monit tasks
- `sidekiq:stop` task perpertually callable @Tensho

## 0.5.4

 - Add support for custom count of processes per host in monit task @okoriko

## 0.5.3

 - Custom count of processes per each host

## 0.5.0

 - Multiple processes @mrsimo

## 0.3.9

 - Restore daemon flag from Monit template

## 0.3.8

- Update monit template: use su instead of sudo / permit all Sidekiq options @bensie
- Unmonitor monit while deploy @Saicheg

## 0.3.7

- Fix capistrano2 task @tribble
- Run Sidekiq as daemon from Monit @dpaluy

## 0.3.5

- Added `:sidekiq_tag` for capistrano 2 @OscarBarrett

## 0.3.4

- Fix bug in `sidekiq:start` for capistrano 2 task

## 0.3.3

- `sidekiq:restart` after `deploy:restart` added to default hooks

## 0.3.2

- `:sidekiq_queue` accept an array

## 0.3.1

- Fix logs @rottman
- Add concurrency option support @ungsophy

## 0.3.0

- Fix monit task @andreygerasimchuk

## 0.2.9

- Check if current directory exist @alexdunae

## 0.2.8

- Added `:sidekiq_queue` & `:sidekiq_config`

## 0.2.7

- Signal usage @penso

## 0.2.6

- `sidekiq:start` check if sidekiq is running

## 0.2.5

- Bug fixes

## 0.2.4

- Fast deploy with `:sidekiq_run_in_background`

## 0.2.3

- Added monit tasks (alpha)

## 0.2.0

- Added `sidekiq:rolling_restart` @jlecour

