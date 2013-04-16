## Status
Most API discussion so far has been about what the API should look like.
This document branches in a different direction 'how do we *actually* implement it, and what concerns are we addresing?'

## Relevant API Goals
-API should support some dynamic queries (search)
-API should eventually support some POST operations
-API usage should be trackable (mediate of requests to API, stats etc)
-Scalability


All these goals can be satisfied by a customizable stateless web role to act as the 'front-end' of the NuGet API.
The web role handles requests to api.nuget.org and resolves them in a manner appropriate to the request.

## Additional Architectural Goal
Blob serving. We wish to use blob storage to enable scalable, eventually consistent data served by the API.

## Additional Requirement
Authentication. The API should eventually accept calls to update data, which will need to be authenticated, 
and may expose per-user data in a way which requires authentication to access.

## Additional Architectural Goal
Robustness to database reliability. The API should not have a hard dependency on the database. 

## Additional Architectural Goal
Robustness to storage reliability. The API should be able to fail over to another 'storage' in the event blobs are unavailable.

## Further goal for the Web project
Design it to discover and expose data+feeds+searches automatically, without requiring changes to the web code 
and reducing frequency of redeployment+reconfiguration of the API front-end.



## Thoughts on where we go from here (can be tracked with issues)
1. Create a solution housing our web role project
1. Give it capability to be configured against backing blob data
1. Give it capability to serve from that backing blob data, and do any intercepting and 'fixing' or 'recording' desired, as we serve the data
1. Design and implement the mechanism of discovering feeds+data to serve from that backing blob data

We can leave it completely separate from the database initially (maybe forever? That would be nice.)
And leave authentication for a little bit later.