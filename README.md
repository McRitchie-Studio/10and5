# 10and5

10&5 Hospitality: a restaurant mystery-shopper platform. Evaluators dine
anonymously and score each department (host, bartender, server, manager) against
the restaurant's standards: pass, fail or N/A, with notes. The restaurant gets an
**Action Plan** of every missed standard by department, compared with its last
visit and its last six. It lives at 10and5.mcritchie.studio.

This is a 2026 rebuild of Alex McRitchie's 2015-17 app,
[amcritchie/garret-app](https://github.com/amcritchie/garret-app) (Rails 4,
Bootstrap, jQuery). It keeps the two screens that made the app what it was, the
evaluator's scorecard and the restaurant's Action Plan, and leaves the rest
behind: no accounts, no evaluator applications or approvals, no password resets,
no email, no database. It is a showcase build for the
[McRitchie Studio App Builder](https://mcritchie.studio/build).

**Everything in this repo is demo data.** The three restaurants, their visits,
the evaluators and every note are invented. Every page says so.

## How it works

| Piece | Where |
|-------|-------|
| Departments, standards, restaurants and visits | `data/sample.yml`, the only store; there is no database |
| Loading the file | `app/models/sample.rb` |
| One visit: arrival and departure, the check, staff observations, a result per standard | `app/models/visit.rb` |
| A score (passed out of scored; N/A counts on neither side) | `app/models/score.rb` |
| The Action Plan: each miss against the visit before and the six before that | `app/models/action_plan.rb` |
| Pages | `/` restaurants · `/restaurants/:slug` visits · `/restaurants/:slug/visits/:n` scorecard · `…/action-plan` Action Plan · `/restaurants/:slug/evaluate` demo scorecard · `/standards` |
| The look | `app/assets/stylesheets/application.css` (plain CSS, light and dark, no JavaScript) |
| Health check | `/up` |

A visit in `data/sample.yml` lists only what did not pass: `missed` (a failed
standard and the evaluator's note), `na` (not observed this visit) and `notes`
(a note on a standard that passed). Every other standard passed.

The demo scorecard (`/restaurants/:slug/evaluate`) is a GET form. Submitting it
builds the Action Plan that scorecard would produce, compared with the
restaurant's real history, and saves nothing, so the app needs no session and
sets no cookie.

## Develop

```bash
bundle install
bin/rails server -p 4200
bin/rails test               # unit + request + production https probe
bin/rails test:system        # the pages in headless Chrome, desktop and phone
bin/ci                       # everything CI runs
```

## Deploy

Heroku app `mcr-10and5`, `heroku/ruby` buildpack, no add-ons, one `web` dyno
(`Procfile`; no release phase, since there is nothing to migrate). There is no
`config/credentials.yml.enc`: production reads `SECRET_KEY_BASE` from the
environment. Production forces HTTPS from `X-Forwarded-Proto` (`assume_ssl`
stays off) except `/up`, and sets no cookie; `ProductionSslTest` boots
production to prove both.

The repo runs the three-rung ladder: feature PRs go into `accepted`, then
`release`, then `main`. CI runs on every pull request and on pushes to
`accepted`, `release` and `main`.
