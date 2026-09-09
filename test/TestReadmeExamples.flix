/// The 100 Orbit64 state tokens published in ORBIT64-EXAMPLES.md.
///
/// The first twenty are named 3x3x3 patterns, beginning with solved. The
/// remaining eighty are a deterministic, seeded sample: twenty each for sizes
/// two through five. Keeping the documentation corpus executable makes a
/// changed rank, endian convention, or width fail before it is published.

def namedExamples(): List[(Int32, String)] = List#{
    // Named patterns.
    (3, "AAAAAAAAAAAA"),
    (3, "AAAABeBQZgAA"),
    (3, "KJZ7jorgHRfo"),
    (3, "KCvKi0WENEAA"),
    (3, "AAAAA-3ogAAA"),
    (3, "AAAAAAAAAL_o"),
    (3, "KTD3xwJ7BgAA"),
    (3, "AAAAAAJNIt8A"),
    (3, "NhMVf5SjhgAA"),
    (3, "Bwi59VLKJogA"),
    (3, "A_K5MO7Gjgf4"),
    (3, "AjJept404AAA"),
    (3, "A4he8ox9NQQo"),
    (3, "DFdcV70mUaDo"),
    (3, "MNWw_fhsb_5Q"),
    (3, "EBmpoOQbOkAA"),
    (3, "AAAekndXgAAA"),
    (3, "EBmpoOQbMgAA"),
    (3, "F-sL_n05VW_4"),
    (3, "B3Azxve5BW_4")
}

def randomTwoExamples(): List[(Int32, String)] = List#{
    (2, "ASj79"), (2, "CrRYm"), (2, "Amjka"), (2, "BVQaG"),
    (2, "ALV8G"), (2, "CMS0m"), (2, "AxzxP"), (2, "D36jK"),
    (2, "BNcbL"), (2, "A00ev"), (2, "D3m1M"), (2, "CoeJ4"),
    (2, "DD-1D"), (2, "DBY4w"), (2, "DdXjV"), (2, "E4zeN"),
    (2, "Drzco"), (2, "CZ5g_"), (2, "CYVMd"), (2, "D6BcP")
}

def randomThreeExamples(): List[(Int32, String)] = List#{
    (3, "AebrMQDGIp0Y"), (3, "B_7na2IjVReI"), (3, "M3Fo9OBFtLeH"),
    (3, "D43T566hd_BK"), (3, "C74b3GZ9sNjP"), (3, "JSOrygifSQ9R"),
    (3, "ABqKvn8US5eU"), (3, "KcKVeVhRWxXu"), (3, "BUreBVbi5iMU"),
    (3, "FHAqilB0Aa0a"), (3, "BxZGmWobFuL-"), (3, "GFLRF-Wu1ZIV"),
    (3, "M2uZrNtxX7ou"), (3, "Fea9c1vQkT7o"), (3, "Ck3gVxuwYhJF"),
    (3, "HVHwtzhJwSAB"), (3, "KHNhUtSA90wQ"), (3, "DTv0NFFEn1ma"),
    (3, "Jg2S42xw8ut9"), (3, "NKeb5_R-wr9z")
}

def randomFourExamples(): List[(Int32, String)] = List#{
    (4, "B2954Bvce2qC68kqGCXzXZNvU5H"),
    (4, "AOTEMXlaHcv9IHxxLGyZq-CfDqz"),
    (4, "AOs2OeT0Z8xn2Ewl8-repJmqUpv"),
    (4, "Bbe9nyHCbMMxQPBx02MqxZk8qNL"),
    (4, "AFKzBjJLYnumqjKfadMm9HC-MYC"),
    (4, "BquQPAi4N-Ho9cC3wR9glmK5C3_"),
    (4, "BTl5wOvfuwSZkiKnXrhsbD_XgDY"),
    (4, "BHFvpovl3YJtB2K1vy6hCDKWFWt"),
    (4, "AVbuJ7zgP4xOmeo3KZ_SzJoOHOy"),
    (4, "B2hqbRa_QOzudrpyAYK6o6Gjpcr"),
    (4, "AWFxhtjHJGTQ3239xrQ7V9F58MT"),
    (4, "Ao0lzTI5rI2RcXkxfGUtALCWePb"),
    (4, "BFlPSHJk1cLTfpD8Vp2DMIQdVdO"),
    (4, "AVU7jDmjpjxWhPfOJITIEFgyO1z"),
    (4, "AiH5CdKIZZVeR004lwOcrsdSujT"),
    (4, "B383rBqxTTLpq0JDJGlzZMwGhhi"),
    (4, "AG6lcYUu9WrIpD52FrdE5sjKpwx"),
    (4, "BkZRba59wYNArJmEmJvt81XgztQ"),
    (4, "AZp6Hq0H77b159R4bauYRJGYVCW"),
    (4, "AUtLUubXAmXQKcXNDQsOBZWHnPd")
}

def randomFiveExamples(): List[(Int32, String)] = List#{
    (5, "AvS6-HtG-C7Jh7ScbCTPUW7og3xXOhLInHugqLe5UuH"),
    (5, "AJQoG7cPtMbbwLcCHXD8TQ2RbDT_AfvOaqYVqhmhFuA"),
    (5, "ARLQXNS9Krli_YrY_A9QVmZ8L31ycnEN1VGopcY9zrg"),
    (5, "AOmDQE1JHJNyJUAt6QU3ZeUZZnUsYZ_5LWVEoE0Uasa"),
    (5, "AWn7iMbbl1JfOwGqm3PVA2L9hFxZEAEhOTQQTJFh7BH"),
    (5, "Atm3PKSoPoWXnVI9iOjWQbMECV_9ytWe_ebUumRmp2G"),
    (5, "AzoDX42ToXBeRf5H6dnqIvKqXQFyw0p7XDDJGaCrKlq"),
    (5, "ADeE-tVcmzc3-2_fn6SlTWEV9hWVKARgnKCqz8QLlby"),
    (5, "AWp8nHaK9il2FqbeCHJ4XjyqVeKKppv3n86Rf42SHAm"),
    (5, "ABnDtiZokyHmms3p6LtBXgycxjr6osyPInwOohl4M_a"),
    (5, "AYdjc0FLPLj9ln8zqi186p5-p9oCjWBsTm-iV7bXqYl"),
    (5, "AXKe03aBZ3_1iHoRq-goXbZ_1UDuK3xw9rQy7QjmJlj"),
    (5, "ARPZhAe4VUXj324SZ0Hw9jrNQUUNDXjjzwrnWB6lUM1"),
    (5, "AM2FFUybwIh6NDzsI8JPViL5h2S4kiK0A60KT5ZCsVB"),
    (5, "A3sr5zTV5JTnnr5x6DWMpZfBoPa6rScgo7MVf_FggzM"),
    (5, "AmLkUIMLuHZGzTN5Wrx9ee5DNn1uAG_HKq0qxQuXApU"),
    (5, "AsYwhJY1cjkL82sdoWKi3lV9eUlNb8a-raM8DHyue_x"),
    (5, "AXGLnbTKXqKxd_oXf_CAMU1jZIOgs5vfBcSMkdJJrE8"),
    (5, "APYf0C4g2trHzzfhD0PyexpL6BjwfwJw4xepbWZc2P3"),
    (5, "A3kv9rOq4LrmEub0WLlGlgPIOn5wGJBYyckrG7H69rb")
}

def examples(): List[(Int32, String)] =
    List.append(namedExamples(), List.append(randomTwoExamples(),
        List.append(randomThreeExamples(), List.append(randomFourExamples(),
            randomFiveExamples()))))

@Test
def publishedStateExamplesAreCanonicalAndRoundTrip(): Unit \ Assert =
    let corpus = examples();
    Assert.assertEq(expected = 100, List.length(corpus));
    corpus |> List.forEach(match (n, token) ->
        match Orbit64.State.decode(n, token) {
            case Err(e) => Assert.assert(false,
                RichString.fromString("published example ${token} did not decode: ${e}"))
            case Ok(state) => {
                Assert.assertEq(expected = Ok(token), Orbit64.State.encode(n, state));
                match Orbit64.Net.toFacelets(n, state) {
                    case Err(e) => Assert.assert(false,
                        RichString.fromString("published example ${token} did not render: ${e}"))
                    case Ok(facelets) => Assert.assertEq(expected = Ok(state),
                        Orbit64.Net.fromFacelets(n, facelets))
                }
            }
        })
