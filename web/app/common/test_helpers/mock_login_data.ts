import {LoginResponse} from '../../services/auth.service';

export const mockLoginResponse: LoginResponse = {
  token: '12345'
};

export const mockTokenNotExpired =
    // Expires Fri Sep 12 275760 17:00:00 GMT-0700 (PDT)
    // We'll hopefully never hit this date
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTYyMzkwMjIsImV' +
    '4cCI6ODY0MDAwMDAwMDAwMCwiaXNzIjoiZmFzdGxhbmUgY2kifQ.C452sd822u1btjo' +
    'VeCy__m0cJuX4DitHTRJbXo4nfLE';

export const mockTokenExpired =
    // Expires Mon Apr 19 -271821 17:00:00 GMT-0700 (PDT)
    // A long long long long time ago
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE1MTYyMzkwMjIsImV' +
    '4cCI6LTg2NDAwMDAwMDAwMDAsImlzcyI6ImZhc3RsYW5lIGNpIn0.x87X93hKwp5IgU' +
    'd14ztlC3zXbH9MuX41aifHLkgIwrA';
