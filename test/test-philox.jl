using Test
using PhiloxRNG: philox4x32_10

@testset "philox known values from random123" begin
    # Values from random123-1.14.0/tests/kat_vectors

    # philox4x32 10-round vectors
    @test philox4x32_10(
        (0x00000000, 0x00000000, 0x00000000, 0x00000000), (0x00000000, 0x00000000)
    ) == (0x6627e8d5, 0xe169c58d, 0xbc57ac4c, 0x9b00dbd8)

    @test philox4x32_10(
        (0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff), (0xffffffff, 0xffffffff)
    ) == (0x408f276d, 0x41c83b0e, 0xa20bc7c6, 0x6d5451fd)

    @test philox4x32_10(
        (0x243f6a88, 0x85a308d3, 0x13198a2e, 0x03707344), (0xa4093822, 0x299f31d0)
    ) == (0xd16cfe09, 0x94fdcceb, 0x5001e420, 0x24126ea1)

    # UInt64 convenience method — same vectors, packed into UInt64s
    # ctr0 = hi32:lo32 = 85a308d3:243f6a88, ctr1 = 03707344:13198a2e, key = 299f31d0:a4093822
    @test philox4x32_10(
        0x0000000000000000, 0x0000000000000000, 0x0000000000000000
    ) == (0x6627e8d5, 0xe169c58d, 0xbc57ac4c, 0x9b00dbd8)

    @test philox4x32_10(
        0xffffffffffffffff, 0xffffffffffffffff, 0xffffffffffffffff
    ) == (0x408f276d, 0x41c83b0e, 0xa20bc7c6, 0x6d5451fd)

    @test philox4x32_10(
        0x85a308d3243f6a88, 0x0370734413198a2e, 0x299f31d0a4093822
    ) == (0xd16cfe09, 0x94fdcceb, 0x5001e420, 0x24126ea1)
end
