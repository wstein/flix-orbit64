///
/// Canonical, URL-safe tokens for twisty-cube states and move sequences.
///
/// State tokens are Orbit64 V2 (`Orbit64.V2`). Move sequences and structured
/// algorithms stay in `Orbit64.Move` and `Orbit64.Algorithm`. `Orbit64.Token`
/// dispatches those non-state classes and rejects the retired V1 state class.
///
pub mod Orbit64 {}
