# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [Unreleased]

- Add a Leaderboard for competitive play
- More specialised missions for specific aircraft
- Time speed-up is disabled when holding a job

## [0.4.1] - 2024-01-18

### Fixed

- Checks that current airport is same as the offer departure airport before allowing the pending offer to be accepted 
- Checks that the aircraft is not moving before allowing pending offer to be accepted

## [0.4.0] - 2024-01-11

### Added

- Add long-haul type freight jobs
- Users can now choose between short-haul and long-haul delivery jobs
- Check if crashed on landing before rewarding - this feature only works for certain aircraft (such as the default C172p)
- Limit user interface functionality when the aircraft is in motion (aircraft must be stationary get or result jobs)
- Add HighAirTrader Logo

## Changed

- Complete re-working of the GUI

## [0.3.0] - 2024-01-05

### Added

- Performance summary now includes a description of the players current 'reputation level'
- Add config menu so players can alter how money units are displayed (i.e. with a GBP, US Dollar or Euro symbol)
- Disable addon functionality for the super fast fictional craft (UFO, Bluebird)
- Update the CHANGELOG

## [0.2.1] - 2024-01-04

### Fixed

- Fix typo that causes the addon to not work at all
- Fix formatting (in the ReadMe etc)
- Fix issue that could cause the Performance Summary not to work
- Update the CHANGELOG

## [0.2.0] - 2023-11-19

### Changed

- Edit list the list of goods that can be transported
- Refactored nasal scripts
- Spell checked and tidy up comments in the nasal scripts

## [0.1.0] - 2023-11-19

### Changed

- Edit list of goods that can be transported
- Test on Flightgear Version 2020.3.6 on Linux

### Added

- Add documentation to nasal scripts

## [0.0.2] - 2023-11-17

### Fixed

- Initial selection of Get Next Job in the menu no longer freezes game for few seconds

## [0.0.1] - 2023-11-15

### Added

- Initial working version tested on Flightgear Version 2019.1.1 on Linux
