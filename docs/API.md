# API

This document covers the documentation for the API the Sinatra service provides.

## Used status codes

Status Code | Description
------------|--------------
200			| All good
400			| Bad request
401			| Unauthorized
403			| Forbidden
404			| Resource not found
500			| Server error

## Error descriptions

The server returns error messages in a unified format:

```json
{
	"message": "Provided key is invalid",
	"key": "InvalidParameter.KeyNotFound"
}
```

### `message`

A human-readable error string describing what went wrong. This is the message you want to show to the user

### `key`

The error key uses a notation that allows you to parse it at a precision level of your choosing. Each level is marked using a `.`

e.g. `InvalidParameter.KeyNotFound`

`InvalidParameter`: A parameter was invalid
`KeyNotFound`: The parameter was invalid because the key can't be found.

There might be any number of nested errors, with any strings using camel case.

As the API client you can now parse the first word before the first `.` and detect `InvalidParameter` and handle it as such. If you want to see why the `InvalidParameter` error was returned, you look at the error key that's behind the first `.`.

#### Available Error Codes

- `Authentication`
	- `ProviderCredentialNotFound`
	- `UserNotFound`
	- `InvalidLogin`
	- `Token`
		- `InvalidIssuer`
		- `MissingIssuedTime`
		- `Expired`
		- `Missing`
- `InvalidParameter`
	- `KeyNotFound`
- `Build`
	- `Missing`
- `Artifact`
	- `Missing`
- `Project`
	- `Missing`
- `Unknown`
