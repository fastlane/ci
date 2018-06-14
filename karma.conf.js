// Karma configuration file, see link for more information
// https://karma-runner.github.io/1.0/config/configuration-file.html

const coverage_reporters = [
  { type: 'text-summary' },
  { type : 'lcov', dir : 'coverage' }
];

module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine', '@angular/cli'],
    plugins: [
      require('karma-jasmine'),
      require('karma-coverage'),
      require('karma-coveralls'),
      require('karma-chrome-launcher'),
      require('karma-jasmine-html-reporter'),
      require('karma-coverage-istanbul-reporter'),
      require('@angular/cli/plugins/karma')
    ],
    client:{
      clearContext: false // leave Jasmine Spec Runner output visible in browser
    },
    coverageIstanbulReporter: {
      reports: [ 'html', 'lcovonly' ],
      fixWebpackSourcePaths: true
    },
    coverageReporter: {
      reporters: coverage_reporters,
    },
    angularCli: {
      environment: 'dev'
    },
    reporters: ['progress', 'kjhtml', 'coverage-istanbul', 'coverage', 'coveralls' ],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['Chrome']
  });
};
