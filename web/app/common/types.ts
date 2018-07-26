import {HttpErrorResponse} from '@angular/common/http';

export interface CiHttpErrorResponse extends HttpErrorResponse {
  error: {key: string, message: string};
}

export interface UserDetails {
  github: {email: string};
}

export type GitHubScope =
    ''|'repo'|'repo:status'|'repo_deployment'|'public_repo'|'repo:invite'|
    'admin:org'|'write:org'|'read:org'|'admin:public_key'|'write:public_key'|
    'read:public_key'|'admin:repo_hook'|'write:repo_hook'|'read:repo_hook'|
    'admin:org_hook'|'gist'|'notifications'|'user'|'read:user'|'user:email'|
    'user:follow'|'delete_repo'|'write:discussion'|'read:discussion'|
    'admin:gpg_key'|'write:gpg_key'|'read:gpg_key';
