# User Stories
## Purpose
The purpose of this analysis is to find the best way to expose the main interactions in our UI. Defining the goals of the users and translating them to the actions needed to attain the goal will allow us to ensure our UI will be able to give the best experience. These User goals are generally written for a mobile-focused CI as to not limit ourselves to what we currently have implemented, but what the user would like to do with a CI.
## Terminology
Repo - Repository containing the source code (ex. Git Repository)
Project - Set of steps or actions that a CI performs
Build - Main entity created as a product of a workflow
Branch - A version control concept where you can make modification upon a snapshot of master.
Master - The main branch in a repo
User Goal - A goal that a user has
User Story - a short description of a feature told from the perspective of a user following the template: As a < type of user >, I want < some goal > so that < some reason >.
User Journey - describes the set of steps a user takes to complete a goal or accomplish a task
Critical User Journey - is a user journey that is either very common, or very important to get right, or both.
Use Cases - describe a complete interaction between the software and users
## Goal: I want to debug a build that failed
### [P0: As a developer, a GitHub Repo, I want every change to be submitted with the confidence that it doesn’t break the App](./debug_failed_buld.md)