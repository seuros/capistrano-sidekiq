# Changelog

## [2.3.0](https://github.com/seuros/capistrano-sidekiq/tree/2.3.0) (2022-05-17)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.2.0...2.3.0)

**Merged pull requests:**

- fix sidekiq processes naming when count is 1 [\#300](https://github.com/seuros/capistrano-sidekiq/pull/300) ([seuros](https://github.com/seuros))
- Support multiple processes in `sidekiq:install` [\#299](https://github.com/seuros/capistrano-sidekiq/pull/299) ([lloydwatkin](https://github.com/lloydwatkin))
- fix: monit config template [\#288](https://github.com/seuros/capistrano-sidekiq/pull/288) ([jpickwell](https://github.com/jpickwell))

## [v2.2.0](https://github.com/seuros/capistrano-sidekiq/tree/v2.2.0) (2022-05-16)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.1.0...v2.2.0)

**Merged pull requests:**

- Allow the definition of  service\_unit\_name [\#297](https://github.com/seuros/capistrano-sidekiq/pull/297) ([seuros](https://github.com/seuros))
- restore sidekiq unit env vars [\#295](https://github.com/seuros/capistrano-sidekiq/pull/295) ([tayagi-aim](https://github.com/tayagi-aim))
- Fix a typo in sidekiq:restart [\#294](https://github.com/seuros/capistrano-sidekiq/pull/294) ([hoppergee](https://github.com/hoppergee))

## [v2.1.0](https://github.com/seuros/capistrano-sidekiq/tree/v2.1.0) (2022-05-15)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0...v2.1.0)

**Merged pull requests:**

- Fix \#253: $HOME is unexpanded in service unit file [\#291](https://github.com/seuros/capistrano-sidekiq/pull/291) ([nikochiko](https://github.com/nikochiko))
- Update Readme [\#287](https://github.com/seuros/capistrano-sidekiq/pull/287) ([lesliepoolman](https://github.com/lesliepoolman))
- Fixed sidekiq.service autostart in --user mode [\#285](https://github.com/seuros/capistrano-sidekiq/pull/285) ([michaelkhabarov](https://github.com/michaelkhabarov))
- README: Add section about older Systemd versions logging [\#284](https://github.com/seuros/capistrano-sidekiq/pull/284) ([64kramsystem](https://github.com/64kramsystem))
- Avoid using present? [\#282](https://github.com/seuros/capistrano-sidekiq/pull/282) ([frederikspang](https://github.com/frederikspang))
- Various systemd improvements - Multiple Process Support, Per Process Config, Proper Restarts with timeout and more [\#279](https://github.com/seuros/capistrano-sidekiq/pull/279) ([jclusso](https://github.com/jclusso))
- Use File.join for systemd file path [\#278](https://github.com/seuros/capistrano-sidekiq/pull/278) ([AndrewSverdrup](https://github.com/AndrewSverdrup))
- Fix bug in switch\_user and dry up common methods to a helpers module [\#272](https://github.com/seuros/capistrano-sidekiq/pull/272) ([chriscz](https://github.com/chriscz))
- Update monit integration against Sidekiq 6.0 [\#271](https://github.com/seuros/capistrano-sidekiq/pull/271) ([7up4](https://github.com/7up4))
- Added sidekiq\_service\_templates\_path to manage custom systemd templates [\#265](https://github.com/seuros/capistrano-sidekiq/pull/265) ([farnsworth](https://github.com/farnsworth))
- Add sidekiq\_config, sidekiq\_concurrency, and sidekiq\_queue support to systemd [\#262](https://github.com/seuros/capistrano-sidekiq/pull/262) ([ayn](https://github.com/ayn))

## [v2.0.0](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0) (2020-12-19)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0.beta5...v2.0.0)

**Merged pull requests:**

- Upstart update [\#261](https://github.com/seuros/capistrano-sidekiq/pull/261) ([duhast](https://github.com/duhast))

## [v2.0.0.beta5](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0.beta5) (2020-06-25)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0.beta4...v2.0.0.beta5)

**Merged pull requests:**

- Minimal working Upstart plugin [\#255](https://github.com/seuros/capistrano-sidekiq/pull/255) ([duhast](https://github.com/duhast))
- Capistrano rbenv uses bundle instead of bundler [\#252](https://github.com/seuros/capistrano-sidekiq/pull/252) ([uxxman](https://github.com/uxxman))

## [v2.0.0.beta4](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0.beta4) (2020-06-08)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0.beta3...v2.0.0.beta4)

**Merged pull requests:**

- Fix undefined method  as error [\#249](https://github.com/seuros/capistrano-sidekiq/pull/249) ([kyoshidajp](https://github.com/kyoshidajp))

## [v2.0.0.beta3](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0.beta3) (2020-05-26)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0.beta2...v2.0.0.beta3)

**Merged pull requests:**

- Append logs [\#247](https://github.com/seuros/capistrano-sidekiq/pull/247) ([Paprikas](https://github.com/Paprikas))
- Add "loginctl enable-linger" command to sidekiq systemd install task [\#246](https://github.com/seuros/capistrano-sidekiq/pull/246) ([Paprikas](https://github.com/Paprikas))
- Setup error output for systemd [\#245](https://github.com/seuros/capistrano-sidekiq/pull/245) ([Paprikas](https://github.com/Paprikas))
- Use StandardOutput for logging [\#244](https://github.com/seuros/capistrano-sidekiq/pull/244) ([Paprikas](https://github.com/Paprikas))

## [v2.0.0.beta2](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0.beta2) (2020-05-25)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v2.0.0.beta1...v2.0.0.beta2)

**Merged pull requests:**

- Add sidekiq\_service\_unit\_env\_vars option to pass Environment variable… [\#243](https://github.com/seuros/capistrano-sidekiq/pull/243) ([Paprikas](https://github.com/Paprikas))

## [v2.0.0.beta1](https://github.com/seuros/capistrano-sidekiq/tree/v2.0.0.beta1) (2020-05-12)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v1.0.3...v2.0.0.beta1)

**Merged pull requests:**

- Release 2.0.0 [\#236](https://github.com/seuros/capistrano-sidekiq/pull/236) ([seuros](https://github.com/seuros))

## [v1.0.3](https://github.com/seuros/capistrano-sidekiq/tree/v1.0.3) (2019-09-02)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v1.0.2...v1.0.3)

**Merged pull requests:**

- Point readers towards enable lingering for systemd [\#230](https://github.com/seuros/capistrano-sidekiq/pull/230) ([creativetags](https://github.com/creativetags))
- Update README\#Multiple processes example [\#215](https://github.com/seuros/capistrano-sidekiq/pull/215) ([tamaloa](https://github.com/tamaloa))
- Add upstart support for start, stop, and quiet [\#208](https://github.com/seuros/capistrano-sidekiq/pull/208) ([tmiller](https://github.com/tmiller))
- Fix monit config file name missing application [\#205](https://github.com/seuros/capistrano-sidekiq/pull/205) ([xiewenwei](https://github.com/xiewenwei))

## [v1.0.2](https://github.com/seuros/capistrano-sidekiq/tree/v1.0.2) (2018-04-12)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v1.0.1...v1.0.2)

## [v1.0.1](https://github.com/seuros/capistrano-sidekiq/tree/v1.0.1) (2018-04-04)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v1.0.0...v1.0.1)

**Merged pull requests:**

- Fix accounting of pidfiles per process \(when using multiple processes\) [\#197](https://github.com/seuros/capistrano-sidekiq/pull/197) ([jsantos](https://github.com/jsantos))
- fix fail rolling restart task [\#196](https://github.com/seuros/capistrano-sidekiq/pull/196) ([idekeita](https://github.com/idekeita))
- README.md - simple edit, highlight known issue with cap 3 [\#192](https://github.com/seuros/capistrano-sidekiq/pull/192) ([westonplatter](https://github.com/westonplatter))
- Systemd integration [\#171](https://github.com/seuros/capistrano-sidekiq/pull/171) ([baierjan](https://github.com/baierjan))
- update README with instructions for prepending 'bundle exec' [\#143](https://github.com/seuros/capistrano-sidekiq/pull/143) ([mistidoi](https://github.com/mistidoi))
- Add deploy failure handling to cap v2 and v3. [\#135](https://github.com/seuros/capistrano-sidekiq/pull/135) ([phillbaker](https://github.com/phillbaker))
- Support custom monit filename [\#132](https://github.com/seuros/capistrano-sidekiq/pull/132) ([zocoi](https://github.com/zocoi))

## [v1.0.0](https://github.com/seuros/capistrano-sidekiq/tree/v1.0.0) (2018-01-24)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.20.0...v1.0.0)

**Merged pull requests:**

- Spring Cleanup [\#190](https://github.com/seuros/capistrano-sidekiq/pull/190) ([Tensho](https://github.com/Tensho))
- Convert CHANGELOG to Markdown + Add Unreleased Section [\#189](https://github.com/seuros/capistrano-sidekiq/pull/189) ([Tensho](https://github.com/Tensho))
- Prepend \_ Before Service Name Index [\#184](https://github.com/seuros/capistrano-sidekiq/pull/184) ([Tensho](https://github.com/Tensho))
- Christmas Eve Cleaning 🎅  [\#183](https://github.com/seuros/capistrano-sidekiq/pull/183) ([Tensho](https://github.com/Tensho))

## [v0.20.0](https://github.com/seuros/capistrano-sidekiq/tree/v0.20.0) (2017-08-01)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.10.0...v0.20.0)

**Merged pull requests:**

- Use new capistrano DSL for reenable tasks [\#177](https://github.com/seuros/capistrano-sidekiq/pull/177) ([Tensho](https://github.com/Tensho))

## [v0.10.0](https://github.com/seuros/capistrano-sidekiq/tree/v0.10.0) (2016-11-25)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.5.4...v0.10.0)

**Merged pull requests:**

- add documentation; add note to ensure shared/tmp/pids folder exists i… [\#168](https://github.com/seuros/capistrano-sidekiq/pull/168) ([elliotwesoff](https://github.com/elliotwesoff))
- Make sidekiq:stop task perpetually callable [\#164](https://github.com/seuros/capistrano-sidekiq/pull/164) ([williamn](https://github.com/williamn))
- Add missing monit default config options to README [\#155](https://github.com/seuros/capistrano-sidekiq/pull/155) ([kirrmann](https://github.com/kirrmann))
- Documenting sidekiq\_service\_name config option [\#153](https://github.com/seuros/capistrano-sidekiq/pull/153) ([bendilley](https://github.com/bendilley))
- Fixes identation and Increase documentation with info about :sidekiq\_config [\#131](https://github.com/seuros/capistrano-sidekiq/pull/131) ([ricardokdz](https://github.com/ricardokdz))
- Respect both local and global puma\_user setting everywhere [\#122](https://github.com/seuros/capistrano-sidekiq/pull/122) ([jhollinger](https://github.com/jhollinger))

## [v0.5.4](https://github.com/seuros/capistrano-sidekiq/tree/v0.5.4) (2015-10-27)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.5.3...v0.5.4)

**Merged pull requests:**

- Change pidfile handling, always add index to pidfile name [\#116](https://github.com/seuros/capistrano-sidekiq/pull/116) ([w1mvy](https://github.com/w1mvy))
- Move Contributors to separate file. [\#115](https://github.com/seuros/capistrano-sidekiq/pull/115) ([lpaulmp](https://github.com/lpaulmp))
- Monit configuration respects options\_per\_process [\#113](https://github.com/seuros/capistrano-sidekiq/pull/113) ([kazjote](https://github.com/kazjote))
- Capistrano 2 fixes [\#109](https://github.com/seuros/capistrano-sidekiq/pull/109) ([wingrunr21](https://github.com/wingrunr21))
- Use SSHKit command\_map [\#104](https://github.com/seuros/capistrano-sidekiq/pull/104) ([hbin](https://github.com/hbin))
- Add notice that the pty bug only applies to Capistrano 3. [\#101](https://github.com/seuros/capistrano-sidekiq/pull/101) ([nTraum](https://github.com/nTraum))
- Add support for different number of processes per host on monit.cap [\#100](https://github.com/seuros/capistrano-sidekiq/pull/100) ([okoriko](https://github.com/okoriko))
- intial support for sidekiq\_user [\#97](https://github.com/seuros/capistrano-sidekiq/pull/97) ([mcb](https://github.com/mcb))

## [v0.5.3](https://github.com/seuros/capistrano-sidekiq/tree/v0.5.3) (2015-06-25)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.5.2...v0.5.3)

**Merged pull requests:**

- Refactored template\_sidekiq method [\#90](https://github.com/seuros/capistrano-sidekiq/pull/90) ([rstrobl](https://github.com/rstrobl))
- added ability to operate without sudo [\#89](https://github.com/seuros/capistrano-sidekiq/pull/89) ([dreyks](https://github.com/dreyks))
- Revert "Add nohup when executing start\_sidekiq command, for a problem… [\#88](https://github.com/seuros/capistrano-sidekiq/pull/88) ([seuros](https://github.com/seuros))
- Add nohup when executing start\_sidekiq command, for a problem with pty. [\#76](https://github.com/seuros/capistrano-sidekiq/pull/76) ([maruware](https://github.com/maruware))
- implemented ability to split sidekiq\_roles by count of sidekiq-processes [\#45](https://github.com/seuros/capistrano-sidekiq/pull/45) ([alexyakubenko](https://github.com/alexyakubenko))

## [v0.5.2](https://github.com/seuros/capistrano-sidekiq/tree/v0.5.2) (2015-03-20)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.5.1...v0.5.2)

**Merged pull requests:**

- Set sidekiq\_concurrency default value for cap 2 \(improves pr \#72\). [\#74](https://github.com/seuros/capistrano-sidekiq/pull/74) ([derSascha](https://github.com/derSascha))

## [v0.5.1](https://github.com/seuros/capistrano-sidekiq/tree/v0.5.1) (2015-03-18)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.5.0...v0.5.1)

**Merged pull requests:**

- Support sidekiq\_concurrency option for capistrano 2 [\#72](https://github.com/seuros/capistrano-sidekiq/pull/72) ([mrsimo](https://github.com/mrsimo))

## [v0.5.0](https://github.com/seuros/capistrano-sidekiq/tree/v0.5.0) (2015-03-18)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.4.0...v0.5.0)

**Merged pull requests:**

- Options per process [\#70](https://github.com/seuros/capistrano-sidekiq/pull/70) ([mrsimo](https://github.com/mrsimo))
- Try execute on the monit.conf mv command [\#69](https://github.com/seuros/capistrano-sidekiq/pull/69) ([bencrouse](https://github.com/bencrouse))
- Update sidekiq.cap [\#68](https://github.com/seuros/capistrano-sidekiq/pull/68) ([raulbrito](https://github.com/raulbrito))
- bug fix for generator. [\#66](https://github.com/seuros/capistrano-sidekiq/pull/66) ([zshannon](https://github.com/zshannon))
- Fix Readme Issues [\#63](https://github.com/seuros/capistrano-sidekiq/pull/63) ([ChuckJHardy](https://github.com/ChuckJHardy))
- Set default option for sidekiq queue in capistrano 2 script [\#62](https://github.com/seuros/capistrano-sidekiq/pull/62) ([brain-geek](https://github.com/brain-geek))
- Update Cap2 Defaults to include config file [\#61](https://github.com/seuros/capistrano-sidekiq/pull/61) ([davidlesches](https://github.com/davidlesches))
- add customizing the monit templates for sidekiq [\#60](https://github.com/seuros/capistrano-sidekiq/pull/60) ([SammyLin](https://github.com/SammyLin))
- Add queues setup in capistrano2 task [\#57](https://github.com/seuros/capistrano-sidekiq/pull/57) ([brain-geek](https://github.com/brain-geek))

## [v0.4.0](https://github.com/seuros/capistrano-sidekiq/tree/v0.4.0) (2014-11-12)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.3.8...v0.4.0)

**Merged pull requests:**

- Test is Sidekiq actually running when starting with Capistrano 2 [\#54](https://github.com/seuros/capistrano-sidekiq/pull/54) ([Envek](https://github.com/Envek))
- use release\_path instead of current\_path [\#50](https://github.com/seuros/capistrano-sidekiq/pull/50) ([flyerhzm](https://github.com/flyerhzm))
- Typo [\#48](https://github.com/seuros/capistrano-sidekiq/pull/48) ([binyamindavid](https://github.com/binyamindavid))
- Fix descriptions of monit tasks [\#47](https://github.com/seuros/capistrano-sidekiq/pull/47) ([jgeiger](https://github.com/jgeiger))

## [v0.3.8](https://github.com/seuros/capistrano-sidekiq/tree/v0.3.8) (2014-09-22)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.3.7...v0.3.8)

**Merged pull requests:**

- Improve @bensie pull request + unmonitor monit while deploy [\#46](https://github.com/seuros/capistrano-sidekiq/pull/46) ([Saicheg](https://github.com/Saicheg))

## [v0.3.7](https://github.com/seuros/capistrano-sidekiq/tree/v0.3.7) (2014-09-01)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.3.6...v0.3.7)

**Merged pull requests:**

- Start Sidekiq as daemon from Monit [\#40](https://github.com/seuros/capistrano-sidekiq/pull/40) ([dpaluy](https://github.com/dpaluy))
- Sidekiq is properly restarted after a crash when deploying with Capsitrano2 [\#39](https://github.com/seuros/capistrano-sidekiq/pull/39) ([tribble](https://github.com/tribble))

## [v0.3.6](https://github.com/seuros/capistrano-sidekiq/tree/v0.3.6) (2014-08-08)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.3.5...v0.3.6)

**Merged pull requests:**

- If :sidekiq\_config is set, Monit template should use it to start the ser... [\#35](https://github.com/seuros/capistrano-sidekiq/pull/35) ([joshmyers](https://github.com/joshmyers))
- replace deploy:restart with deploy:publishing for capistrano 3.1 [\#34](https://github.com/seuros/capistrano-sidekiq/pull/34) ([flyerhzm](https://github.com/flyerhzm))
- Fix: test with spaces ignores within [\#33](https://github.com/seuros/capistrano-sidekiq/pull/33) ([rogercampos](https://github.com/rogercampos))
- Added \_cset for :sidekiq\_tag [\#32](https://github.com/seuros/capistrano-sidekiq/pull/32) ([OscarBarrett](https://github.com/OscarBarrett))

## [v0.3.5](https://github.com/seuros/capistrano-sidekiq/tree/v0.3.5) (2014-07-25)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.3.4...v0.3.5)

**Merged pull requests:**

- Allow use of sidekiq\_tag for capistrano2 [\#30](https://github.com/seuros/capistrano-sidekiq/pull/30) ([OscarBarrett](https://github.com/OscarBarrett))

## [v0.3.4](https://github.com/seuros/capistrano-sidekiq/tree/v0.3.4) (2014-07-09)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/v0.1.0...v0.3.4)

**Merged pull requests:**

- Added concurrency option [\#26](https://github.com/seuros/capistrano-sidekiq/pull/26) ([ungsophy](https://github.com/ungsophy))
- Fix bug with process index in monit task [\#21](https://github.com/seuros/capistrano-sidekiq/pull/21) ([0x616E676572](https://github.com/0x616E676572))
- You can now use signals to quiet/stop sidekiq, much faster. [\#18](https://github.com/seuros/capistrano-sidekiq/pull/18) ([penso](https://github.com/penso))
- Check that current\_path exists before stopping [\#16](https://github.com/seuros/capistrano-sidekiq/pull/16) ([alexdunae](https://github.com/alexdunae))
- search pid files in correct directory [\#12](https://github.com/seuros/capistrano-sidekiq/pull/12) ([levinalex](https://github.com/levinalex))
- Rolling restart [\#7](https://github.com/seuros/capistrano-sidekiq/pull/7) ([jlecour](https://github.com/jlecour))

## [v0.1.0](https://github.com/seuros/capistrano-sidekiq/tree/v0.1.0) (2014-03-24)

[Full Changelog](https://github.com/seuros/capistrano-sidekiq/compare/07b9d97f5bcf08af43baec0924bb088a6486f31c...v0.1.0)

**Merged pull requests:**

- Cleaner version checking [\#6](https://github.com/seuros/capistrano-sidekiq/pull/6) ([ghost](https://github.com/ghost))
- More robust version checking [\#4](https://github.com/seuros/capistrano-sidekiq/pull/4) ([jlecour](https://github.com/jlecour))
- More explicit start command [\#3](https://github.com/seuros/capistrano-sidekiq/pull/3) ([jlecour](https://github.com/jlecour))
- Improve pid and log files settings [\#1](https://github.com/seuros/capistrano-sidekiq/pull/1) ([jlecour](https://github.com/jlecour))



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
