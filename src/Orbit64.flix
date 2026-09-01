///
/// Canonical, URL-safe tokens for twisty-cube states and move sequences.
///
/// The concrete codecs live in `Orbit64.State`, `Orbit64.Move`, and
/// `Orbit64.Move.Slp`. `Orbit64.Token` provides tagged decoding across them.
/// Keeping the root module free of codec functions makes the token family
/// explicit at every call site.
///
mod Orbit64 {}
