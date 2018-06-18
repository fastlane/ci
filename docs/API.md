# API

This document covers the documentation for the API the Sinatra service provides.

## Used status codes

Status Code | Description
------------|--------------
200			| All good
400			| Something went wrong

## Error descriptions

The server returns error messages in a unified format:

```json
{
	"error": "Provided key is invalid",
	"error_code": "InvalidParameter.KeyNotFound"
}
```

### `error`

A human-readable error string describing what went wrong. This is the message you want to show to the user

### `error_code`

The error code uses a notation that allows you to parse it at a precision level of your choosing. Each level is marked using a `.`

e.g. `InvalidParameter.KeyNotFound`

`InvalidParameter`: A parameter was invalid
`KeyNotFound`: The parameter was invalid because the key can't be found.

There might be any number of nested errors, with any strings using camel case.

As the API client you can now parse the first word before the first `.` and detect `InvalidParameter` and handle it as such. If you want to see why the `InvalidParameter` error was returned, you look at the error code that's behind the first `.`.
