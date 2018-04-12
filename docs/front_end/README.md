# Front-end Docs
All contributors should feel the ability to tackle any part of the stack. Front-end development can be have a high learning curve, so let's make it easy!

### Index
TODO

### Directory structure
```
web
│   index.html // Top level that gets served
│   ...
│
└─── app
│   │   app.module.ts // Module definitions go here
│   │   app-routing.module.ts // Maps URL routes to Components
│   │   ...
│   │
│   └─── URL Page components (ex. dashboard)
│   │   │   dashboard.component.html // Template
│   │   │   dashboard.component.scss // Stylings
│   │   │   dashboard.component.spec.ts // Unit tests
│   │   │   dashboard.component.ts // Business logic
│   │
│   └─── services // Logic helpers go here
│   │   │   data.service.ts // Backend communication
│   │   │   ...
│   │
│   └─── common // Shared code
│   │   │   constants.ts
│   │   │   ...
│   │   │
│   │   └─── components // shared structural components
│   │       │   ...
│   │
│   └─── models // Data models
│       │   project_summary.ts // Example
│       │   ....
│
└─── assets // Any artwork
│    │  ...
│
└─── global // global styles
│   │   grid.scss // Example
│   │   ...
│
└─── shared // styles that can be imported
    │   grid.scss // Example
    │   ...
```

