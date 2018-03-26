Project Layout
===

```
ci
├── [app](#app)
│   ├── [features](#features)
│   ├── [services](#services)
│   ├── [shared](#shared)
│   └── [workers](#workers)
├── docs
├── public
├── [spec](#spec)
├── [web](#web)
└── [vendor](#vendor)
```

app
---

The source files for the application front-end and backend live in this directory.

features
---

This directory contains controllers, views, and templates for the UI and API of the web application

services
----

Services are like controllers for your data

shared
---

workers
---

Background workers

spec
---

Rspec tests for the ruby implementation of the web application. Sub-folders here should match the relevant files under test in `app/`

web
---

Front-end code for the browser UI of the application

vendor
---

External dependencies