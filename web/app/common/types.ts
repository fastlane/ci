import {HttpErrorResponse} from '@angular/common/http';

export interface CiHttpErrorResponse extends HttpErrorResponse {
  error: {key: string, message: string};
}

export interface UserDetails {
  github: {email: string};
}
