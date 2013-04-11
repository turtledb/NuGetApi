# Package Atoms

One of the key things we want to do in API v3 which is more on the implementation side (but still relevant here) is to have a clean data model that scales horizontally and allows for multiple distributed backups. At the moment, the data relating to a package is stored in two places: The NuGet Gallery SQL Database, and the NuPkg file in Azure Blob storage. Neither location has the complete set of data, and while both **are** backed-up, restoring them is made more difficult by the potential for them becoming out of date.

This spec proposes a data model for NuGet that creates a single authoritative data store (which can be scaled horizontally and replicated freely) called "Atoms". The name deriving from the fact that this data format would be the smallest, indivisible, piece of data the Gallery stores.

## What is an Atom?
A Package "Atom" is three pieces of information

1. The Package File uploaded to the Gallery, **exactly** as it was received by the Gallery front-end.
2. The **current** state of package metadata that can be modified by the Gallery (i.e., the users who own the package, in the current Gallery model).
3. A cryptographic signature that verifies the data in #1 and #2 have not been tampered with since the last time the Gallery application modified them.

To provide some concrete specification of what this looks like, consider the NuGet.Core package. The Package File specifies the owner as "Outercurve Foundation", but the [site](https://nuget.org/packages/NuGet.Core) shows a number of different owners. In this model, the _authoritative_ copy of the package would be an Atom. The suggested implementation of an Atom is a ZIP file (or other archive) containing the following three files:

* NuGet.Core.2.3.0-alpha003._hash_.packageatom
  * NuGet.Core.2.3.0-alpha003.nupkg
  * Metadata.json
  * Signature.sig

The NuPkg file is the exact same file provided by the user. The Metadata.json contains **all** metadata added to the package by the Gallery (for example, package owners) as well as a Hash of the content of the original NuPkg. The Signature file contains a cryptographic signature produced using a private key held by the Gallery (or some subsystem of it). This signature need not be generated from a fully trusted certificate chain, only from a self-generated key that is kept secure (see Security below).

## Why an Archive?
A ZIP file (or other Archive) is suggested because files are generally treated as single entities and there are mechanisms on most platforms (including Azure blob storage) to work Atomically with files. Thus, compacting all package data into a file allows us to take advantage of those atomic systems.

## Versioning
By creating a new Atom every time a package is changed, we can maintain a history of package changes. Policy should be applied regarding how long old versions are kept because while storage is cheap, it's not free ;).

## Security
TBD: Tell Barry I said that ;). I mostly just mean To Be Documented, I have an idea of how it would work in my head. Basically, if the key used to sign packages leaks, we have a mechanism to tell the client not to trust it any more.
