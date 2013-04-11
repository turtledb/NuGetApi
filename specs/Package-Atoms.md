# Package Atoms

One of the key things we want to do in API v3 which is more on the implementation side (but still relevant here) is to have a clean data model that scales horizontally and allows for multiple distributed backups. At the moment, the data relating to a package is stored in two places: The NuGet Gallery SQL Database, and the NuPkg file in Azure Blob storage. Neither location has the complete set of data, and while both **are** backed-up, restoring them is made more difficult by the potential for them becoming out of date.

This spec proposes a data model for NuGet that creates a single authoritative data store (which can be scaled horizontally and replicated freely) called "Atoms". The name deriving from the fact that this data format would be the smallest, indivisible, piece of data the Gallery stores.

## What is an Atom?
A Package "Atom" is three pieces of information

1. The Package File uploaded to the Gallery, **exactly** as it was received by the Gallery front-end.
2. The **current** state of package metadata that can be modified by the Gallery (i.e., the users who own the package, in the current Gallery model).
3. A cryptographic signature that verifies the data in #1 and #2 have not been tampered with since the last time the Gallery application modified them.
