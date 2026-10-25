# WWW::Bund

**Perl CLI client and library for German federal APIs** ([bund.dev](https://bund.dev))

[![CPAN Version](https://img.shields.io/cpan/v/WWW-Bund.svg)](https://metacpan.org/pod/WWW::Bund)
[![Tests](https://img.shields.io/badge/tests-2444%20passing-success)](t/)
[![APIs](https://img.shields.io/badge/APIs-20%2F31-blue)](#api-roadmap)
[![Languages](https://img.shields.io/badge/languages-7-green)](#supported-languages)
[![POD](https://img.shields.io/badge/POD-100%25-success)](#)

---

## 🚗 Live examples

### Traffic jams on the A3

```bash
$ bund autobahn roadworks A3
TITEL                                     UNTERTITEL                    GESPERRT
--------------------------------------------------------------------------------
A3 | Rottal-West - Neuhaus am Inn        Passau -> Linz                nein
A3 | Manzing - Isarblick                 Passau -> Nürnberg            nein
A3 | Nürnberg - Brunn                    Halle/Leipzig -> Nürnberg     nein
A3 | Neumarkt-Ost - Deusmauerer Moor     Nürnberg -> Passau            nein
A3 | Wolfstein - Neumarkt-Ost            Nürnberg -> Passau            nein
...
```

### 💧 Water levels

```bash
$ bund pegel stations
STATION                    GEWAESSER  KM
----------------------------------------------
CELLE                      ALLER      1.74
MARKLENDORF                ALLER      38.47
AHLDEN                     ALLER      58.71
RETHEM                     ALLER      82.32
EITZE                      ALLER      107.75
...
```

### 📰 Tagesschau news

```bash
$ bund tagesschau homepage
SCHLAGZEILE                     TITEL                                    DATUM
-----------------------------------------------------------------------------------------
US-Einschätzung zu Treibhausga  Trump kippt zentrale Vorgabe für Klim... 2026-02-13T04:46
Nach zehn Wochen                ICE-Einsatz in Minnesota wird beendet    2026-02-12T20:29
EU-Gipfel zu Lage der Wirtscha  Gemeinsamer Weg - aber auch gemeinsam.. 2026-02-12T20:36
Klöckner im Gazastreifen        Große Kritik nach kleinem Besuch         2026-02-12T14:04
...
```

### 🏛️ Bundestag plenary sessions

```bash
$ bund bundestag conferences
DATUM       NR  SITZUNG
-----------------------------------------------------
28.01.2026  55  55. Sitzung des Deutschen Bundestages
29.01.2026  56  56. Sitzung des Deutschen Bundestages
30.01.2026  57  57. Sitzung des Deutschen Bundestages
25.02.2026  58  58. Sitzung des Deutschen Bundestages
...
```

### 🌡️ DWD weather warnings

```bash
$ bund dwd municipality-warnings
WARNUNG                                   EREIGNIS            STUFE  BESCHREIBUNG
------------------------------------------------------------------------------------------------------
Amtliche WARNUNG vor STURMBÖEN            STURMBÖEN           3      Es treten oberhalb 800 m Sturm..
Amtliche WARNUNG vor SCHWEREN STURMBÖEN   SCHWERE STURMBÖEN   3      Es treten oberhalb 1000 m schw..
...
```

### 📅 German public holidays 2026

```bash
$ bund feiertage list
---
NATIONAL:
  Neujahr:
    datum: 2026-01-01
  Karfreitag:
    datum: 2026-04-03
  Ostermontag:
    datum: 2026-04-06
  Tag der Arbeit:
    datum: 2026-05-01
  Christi Himmelfahrt:
    datum: 2026-05-14
  1. Weihnachtstag:
    datum: 2026-12-25
  2. Weihnachtstag:
    datum: 2026-12-26
```

### 🚨 NINA disaster warnings

```bash
$ bund nina mapdata-katwarn
Keine Warnungen.

$ bund nina warnings 091620000000
# (Shows current warnings for the district with AGS code 091620000000)
```

### ✈️ Travel warnings

```bash
$ bund travelwarning warnings
---
'199124':
  countryCode: PL
  countryName: Polen
  effective: 1768485600
  iso3CountryCode: POL
  title: 'Polen: Reise- und Sicherheitshinweise'
  warning: 0
'200382':
  countryCode: BE
  countryName: Belgien
  effective: 1764837900
  iso3CountryCode: BEL
  title: 'Belgien: Reise- und Sicherheitshinweise'
  warning: 0
...
```

### 🏛️ Bundesrat members

```bash
$ bund bundesrat mitglieder renderXml
---
list:
  employee:
  - firstname: Winfried
    name: Kretschmann
    party: BÜNDNIS 90/DIE GRÜNEN
    state: Baden-Württemberg
    brmitglied: 'true'
  - firstname: Thomas
    name: Strobl
    party: CDU
    state: Baden-Württemberg
    brmitglied: 'true'
...
```

### 📊 Dashboard Deutschland

```bash
$ bund dashboarddeutschland get
NAME             BESCHREIBUNG
--------------------------------------------------------------
Arbeitsmarkt     Indikatoren zur Erwerbstätigkeit, Kurzarbeit...
Energie          Preisentwicklung verschiedener Energieträger...
Außenhandel      Aktuelle Veränderungen im Außenhandel...
Branchen         Entwicklungen aus Dienstleistungs- und Industrie...
...
```

### 🚴 Bicycle counters (Eco Visio)

```bash
$ bund -o json ecovisio counters 4586
[
   {
      "idPdc" : 100044994,
      "nom" : "Long Beach (US)",
      "nomOrganisme" : "Bike Count Display Interactive Map",
      "lat" : 33.75895,
      "lon" : -118.14846,
      ...
   }
]
```

### 💊 Medical aids directory (GKV)

```bash
$ bund -o json hilfsmittel tree 1
[
   {
      "displayValue" : "01 - Absauggeräte",
      "xSteller" : "01",
      "id" : "835f127b-8355-4ac4-90f8-e3b7ff80ba80"
   },
   {
      "displayValue" : "02 - Adaptionshilfen",
      "xSteller" : "02",
      "id" : "339cc855-29fa-4f9e-b822-e024ed90637b"
   },
   ...
]
```

### 🌫️ Air quality (Umweltbundesamt)

```bash
$ bund luftqualitaet stations
STATION                    STADT                NETZWERK
----------------------------------------------------------
Berlin-Charlottenburg      Berlin               UBA
Dresden-Bergstraße         Dresden              UBA
Hamburg-Sternschanze       Hamburg              UBA
München-Landshuter Allee   München              UBA
...

$ bund luftqualitaet components
KOMPONENTE     BESCHREIBUNG
-------------------------------------------------
PM10          Feinstaub (PM10)
NO2           Stickstoffdioxid
O3            Ozon
...
```

### 🌍 Market master data (energy installations)

```bash
$ bund marktstammdaten strom-erzeugung
---
data:
  - EinheitMastrNummer: SEE900000000001
    EinheitSystemstatus: Aktiv
    EinheitBetriebsstatus: InBetrieb
    Nettonennleistung: 1500
    Energietraeger: Solare Strahlungsenergie
  - EinheitMastrNummer: SEE900000000002
    EinheitSystemstatus: Aktiv
    Nettonennleistung: 850
    Energietraeger: Wind
...
```

### 📚 Deutsche Digitale Bibliothek

```bash
$ bund ddb search Goethe
---
numberOfResults: 125847
results:
  - title: 'Faust. Eine Tragödie'
    subtitle: 'von Johann Wolfgang von Goethe'
    thumbnail: 'https://...'
  ...
```

---

## 🌍 Supported Languages

**7 languages with complete translations:**

🇩🇪 Deutsch • 🇬🇧 English • 🇫🇷 Français • 🇪🇸 Español • 🇮🇹 Italiano • 🇳🇱 Nederlands • 🇵🇱 Polski

**Dedicated commands per language:**

```bash
bund   autobahn roads   # 🇩🇪 Deutsch (default)
bunden autobahn roads   # 🇬🇧 English
bundfr autobahn roads   # 🇫🇷 Français
bundes autobahn roads   # 🇪🇸 Español
bundit autobahn roads   # 🇮🇹 Italiano
bundnl autobahn roads   # 🇳🇱 Nederlands
bundpl autobahn roads   # 🇵🇱 Polski
```

**Or with the --lang flag:**

```bash
bund --lang en autobahn roads     # English
bund --lang fr nina warnings 123  # French
```

---

## 📦 Installation

```bash
cpanm WWW::Bund
```

Or from the repository:

```bash
git clone https://github.com/Getty/p5-www-bund.git
cd p5-www-bund
cpanm --installdeps .
perl -Ilib bin/bund
```

---

## 🚀 Quick Start

### Show an overview

```bash
bund                    # Shows all available APIs
bund list               # Detailed API list
bund info autobahn      # Details on one API
bund autobahn           # Available commands for autobahn
```

### API calls

```bash
# Autobahn API
bund autobahn roads                    # All motorways
bund autobahn roadworks A3             # Roadworks on the A3
bund autobahn warnings A7              # Warnings on the A7
bund autobahn webcams A9               # Webcams on the A9

# Pegel-Online (water level data)
bund pegel stations                    # All gauging stations
bund pegel station WUERZBURG           # Details for one station
bund pegel measurements WUERZBURG W    # Water level measurements

# Tagesschau
bund tagesschau homepage               # Front page
bund tagesschau search Ukraine         # Search news

# NINA (disaster warnings)
bund nina warnings 091620000000        # Warnings for a district (AGS code)
bund nina mapdata-katwarn              # KATWARN map data

# DWD (German Weather Service)
bund dwd municipality-warnings         # Municipality warnings
bund dwd warnings-nowcast              # Nowcast warnings

# Bundestag
bund bundestag conferences              # Plenary sessions
bund bundestag mdb-index               # Members of parliament

# Bundesrat
bund bundesrat startlist               # Start list
bund bundesrat aktuelles               # Current news

# Public holidays
bund feiertage list                    # All public holidays (current year)

# SMARD (electricity market data)
bund smard indices 1 DE hour           # Electricity market indices

# Travel warnings
bund travelwarning warnings            # All travel warnings

# Dashboard Deutschland
bund dashboarddeutschland get          # Dashboard data

# More...
bund bundestaglobbyregister search     # Lobby register search
bund ecovisio counters 4586            # Bicycle counters
bund hilfsmittel tree 1                # Medical aids directory
```

---

## 🎨 Output formats

### Template-based (default)

Formatted tables, lists and records based on YAML templates:

```bash
bund pegel stations
# STATION              GEWAESSER       GEWTYPE  LAT      LON
# WUERZBURG            Main            river    49.7994  9.9292
# BAMBERG              Regnitz         river    49.8901  10.8903
# ...
```

An endpoint's template lives in `share/templates/{language}/{endpoint}.yml`.
If there is no `.yml` file, a `.yaml` file with the same name is used; a
template given with `-t` takes precedence. An endpoint without a template
shows the response as it is.

### JSON

```bash
bund -o json pegel stations
{
  "stations": [
    {
      "shortname": "WUERZBURG",
      "water": {"shortname": "Main", "type": "river"},
      ...
    }
  ]
}
```

### YAML

```bash
bund -o yaml pegel stations
---
stations:
  - shortname: WUERZBURG
    water:
      shortname: Main
      type: river
```

### Custom templates

```bash
bund -t my_template.yml pegel stations
```

**Template example** (`my_template.yml`):

```yaml
type: table
columns:
  - field: shortname
    header: STATION
    width: 20
  - field: water.shortname
    header: WATER
    width: 15
```

---

## 📊 API Roadmap

### ✅ Fully implemented (19 APIs, 114 endpoints)

| API | Endpoints | Description | Auth |
|-----|-----------|-------------|------|
| **autobahn** | 7 | Roadworks, closures, webcams, warnings, charging stations, truck parking | ❌ |
| **pegel_online** | 5 | Water levels, stations, waters, time series, measurements | ❌ |
| **tagesschau** | 4 | News, search, channels, homepage | ❌ |
| **nina** | 14 | Disaster warnings, map data (6 sources), version, logos, FAQs, emergency tips | ❌ |
| **bundestag** | 8 | Speakers, sessions, committees, members, articles, videos | ❌ |
| **dwd** | 5 | Weather warnings (municipality/coast/nowcast), station data, crowd reports | ❌ |
| **feiertage** | 1 | German public holidays by state/year | ❌ |
| **smard** | 3 | Electricity market data (indices, time series, tables) | ❌ |
| **bundeshaushalt** | 1 | Federal budget data | ❌ |
| **bundesrat** | 10 | Start list, news, dates, plenary, members, presidium | ❌ |
| **bundestag_lobbyregister** | 1 | Lobby register search | ❌ |
| **dashboard_deutschland** | 3 | Dashboard data, indicators, GeoJSON | ❌ |
| **travelwarning** | 6 | Travel warnings, missions, country info, health | ❌ |
| **eco_visio** | 2 | Bicycle counters, count data | ❌ |
| **hilfsmittel** | 7 | GKV medical aids directory (tree, products, groups) | ❌ |
| **luftqualitaet** | 13 | Air quality (components, measurements, stations, metadata) | ❌ |
| **marktstammdaten** | 8 | Market master data register (electricity/gas filters + data) | ❌ |
| **pflanzenschutzmittelzulassung** | 6 | Plant protection products (products, active substances, uses) | ❌ |
| **abfallnavi** | 10 | Waste collection calendar (places, streets, dates with region parameter) | ❌ |

**Total: 114 endpoints across 19 APIs**

**Note:** the Eco Visio API currently gives no renderable response: `counters` returns 404 Not Found for every published id, the variant without `plus` returns 200 with an empty result, `data` a 400 with a validation chain (measured on 2026-10-20). The CLI therefore shows the API's raw response.

### 🔄 In progress / limited (2 APIs)

| API | Endpoints | Status | Details |
|-----|-----------|--------|---------|
| **destatis** | 0 | In the registry | No endpoint and no command yet |
| **ladestationen** | 1 | Partial Auth Required | ArcGIS FeatureServer with GeoJSON defaults, optional LADESTATIONEN_TOKEN |

**Note:** the Bundesnetzagentur's charging station register removed the public GeoJSON file and switched to an authenticated ArcGIS FeatureServer.

### 🔐 Authentication required (not planned)

These APIs need API keys and are therefore not intended for the public CLI client:

- **ausbildungssuche** (BA API key)
- **bewerberboerse** (BA API key)
- **jobsuche** (BA API key)
- **lebensmittelwarnung** (API key)
- **dip_bundestag** (API key)

### 📋 Registry only (11 APIs)

These APIs are listed in `share/registry.yml`, but have no endpoint yet and
therefore no command (destatis is listed with 0 endpoints in the table above):

- **ausbildungssuche**
- **bewerberboerse**
- **ddb**
- **destatis**
- **deutschlandatlas**
- **dip_bundestag**
- **handelsregister**
- **jobsuche**
- **lebensmittelwarnung**
- **mudab**
- **regionalatlas**

---

## 🗂️ Cache

API responses are cached automatically:

```
$XDG_CACHE_HOME/www-bund/responses/
# Fallback: ~/.cache/www-bund/responses/
```

**Cache TTLs** (automatic per endpoint):

| TTL | Type | Examples |
|-----|-----|-----------|
| **120s** | Emergencies | NINA warnings, DWD weather warnings, Autobahn warnings |
| **300s** | Real time | Tagesschau, Pegel measurements, roadworks, Bundesrat news |
| **1800s** | Moderate | Webcams, search, electricity market time series, travel warnings |
| **86400s** | Static | Street lists, station lists, public holidays, metadata |

Clear the cache:

```bash
rm -rf ~/.cache/www-bund/
```

Or programmatically:

```perl
use WWW::Bund;
WWW::Bund->new->cache->clear;
```

---

## 🏗️ Architecture

### CLI (MooX::Cmd + MooX::Options)

```
bin/bund                              Deutsch (via ENV)
bin/bunden                            Englisch (via ENV)
bin/bundfr/bundes/bundit/bundnl/bundpl  Weitere Sprachen

lib/WWW/Bund/CLI.pm                   Root CLI (globale Options, Helper)
lib/WWW/Bund/CLI/Role/APICommand.pm   Shared role for API commands
lib/WWW/Bund/CLI/Cmd/*.pm             22 Klassen: 20 API-Commands, 2 Meta-Commands (~10 LOC each)
lib/WWW/Bund/CLI/Cmd/{List,Info}.pm   Meta-Commands
lib/WWW/Bund/CLI/Formatter.pm         Template-Rendering
lib/WWW/Bund/CLI/Strings.pm           i18n Strings
```

### Core Library

```
lib/WWW/Bund.pm                       Haupt-Client
lib/WWW/Bund/Registry.pm              API and endpoint registry
lib/WWW/Bund/Caller.pm                HTTP calls with auth/cache/rate limit
lib/WWW/Bund/Cache.pm                 Disk-Cache (XDG-konform)
lib/WWW/Bund/Auth.pm                  Auth-Header pro API
lib/WWW/Bund/RateLimit.pm             Rate-Limiting pro API
lib/WWW/Bund/LWPIO.pm                 LWP-basierter IO-Adapter
lib/WWW/Bund/HTTPRequest.pm           Request-Objekt
lib/WWW/Bund/HTTPResponse.pm          Response-Objekt
lib/WWW/Bund/Response::{JSON,XML,Raw}.pm  Response-Parser
lib/WWW/Bund/API/*.pm                 Typed API-Adapter (optional)
```

### Data Files

```
share/registry.yml                    31 API-Definitionen
share/endpoints.yml                   115 Endpoint-Definitionen
share/templates/{de,en,fr,es,it,nl,pl}/       777 Templates (111 pro Sprache)
share/strings/{de,en,fr,es,it,nl,pl}.yml      7 Strings-Dateien
```

The registry holds the 31 registered APIs from share/registry.yml. The
endpoint catalog in share/endpoints.yml defines 115 endpoints across 20 of these
APIs; the remaining 11 registered APIs have no endpoints yet.

---

## 🌐 Adding a new language

1. **Create the strings file:**

```bash
cp share/strings/en.yml share/strings/xx.yml
# Translate all values (do NOT change the keys)
```

2. **Create the template folder:**

```bash
mkdir share/templates/xx
cp share/templates/en/* share/templates/xx/
# Translate only the `header:` and `empty:` fields
```

3. **Use it:**

```bash
bund --lang xx autobahn roads
```

---

## 🪟 Windows EXE

Standalone `.exe` without a Perl installation via [PAR::Packer](https://metacpan.org/pod/PAR::Packer):

```bash
# With Strawberry Perl
pp -x -M LWP::Protocol::https -M Moo -a "share/;share/" -o bund.exe bin/bund
```

**Important:**
- Bundle XS modules (YAML::XS, JSON::XS) explicitly
- Ship SSL certificates (Mozilla::CA)
- Test on a clean Windows system

Alternative: Strawberry Perl Portable as a ZIP.

---

## 📚 Documentation

All 46 modules have complete POD documentation:

```bash
perldoc WWW::Bund                    # Main module
perldoc WWW::Bund::CLI               # CLI documentation
perldoc WWW::Bund::API::Autobahn     # API adapter
perldoc bund                         # Bin command
```

**POD features:**
- SYNOPSIS with usage examples for every module
- Complete description of all attributes (=attr)
- Documentation of all methods (=method)
- Cross-references between related modules
- Inline POD for automatic PodWeaver generation

**Scope:**
- 46 modules with POD
- 2,112+ lines of documentation
- 7 bin scripts with complete POD

---

## 🧪 Tests

```bash
prove -lr t/                       # All tests (2444)
prove -l t/00-load.t               # Module loading
prove -l t/cli.t                   # CLI functionality
WWW_BUND_LIVE_TEST=1 prove -l t/integration.t  # Live API tests
```

---

## 📝 License

This module is free software. It can be redistributed and/or modified under the
same terms as Perl itself.

---

## 👥 Author

**Torsten Raudssus** (GETTY) <torsten@raudss.us>

---

## 🔗 Links

- [bund.dev](https://bund.dev) - Official API registry
- [GitHub](https://github.com/Getty/p5-www-bund)
- [MetaCPAN](https://metacpan.org/pod/WWW::Bund)
- [Issues](https://github.com/Getty/p5-www-bund/issues)
