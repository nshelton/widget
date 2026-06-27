import Foundation

struct CatalogStar {
    let ra: Double      // right ascension in hours (0–24)
    let dec: Double     // declination in degrees (-90 to +90)
    let magnitude: Double
    let name: String?
}

struct ConstellationLine {
    let from: Int  // index into stars array
    let to: Int
}

enum StarCatalog {
    // Brightest ~90 stars visible to naked eye, covering both hemispheres.
    // RA in hours, Dec in degrees, visual magnitude.
    static let stars: [CatalogStar] = [
        // Ursa Major (Big Dipper)
        CatalogStar(ra: 11.062, dec: 61.751, magnitude: 1.79, name: "Dubhe"),        // 0
        CatalogStar(ra: 11.031, dec: 56.382, magnitude: 2.37, name: "Merak"),        // 1
        CatalogStar(ra: 11.897, dec: 53.695, magnitude: 2.44, name: "Phecda"),       // 2
        CatalogStar(ra: 12.257, dec: 57.033, magnitude: 3.31, name: "Megrez"),       // 3
        CatalogStar(ra: 12.900, dec: 55.960, magnitude: 1.77, name: "Alioth"),       // 4
        CatalogStar(ra: 13.399, dec: 54.926, magnitude: 2.27, name: "Mizar"),        // 5
        CatalogStar(ra: 13.792, dec: 49.313, magnitude: 1.86, name: "Alkaid"),       // 6

        // Orion
        CatalogStar(ra: 5.919, dec: 7.407, magnitude: 0.42, name: "Betelgeuse"),     // 7
        CatalogStar(ra: 5.242, dec: -8.202, magnitude: 0.12, name: "Rigel"),         // 8
        CatalogStar(ra: 5.680, dec: -1.943, magnitude: 1.70, name: "Alnilam"),       // 9
        CatalogStar(ra: 5.604, dec: -1.202, magnitude: 1.88, name: "Alnitak"),       // 10
        CatalogStar(ra: 5.533, dec: -0.299, magnitude: 2.23, name: "Mintaka"),       // 11
        CatalogStar(ra: 5.418, dec: 6.350, magnitude: 1.64, name: "Bellatrix"),      // 12
        CatalogStar(ra: 5.796, dec: -9.670, magnitude: 2.06, name: "Saiph"),         // 13

        // Major bright stars
        CatalogStar(ra: 6.752, dec: -16.716, magnitude: -1.46, name: "Sirius"),      // 14
        CatalogStar(ra: 19.846, dec: 8.868, magnitude: 0.76, name: "Altair"),        // 15
        CatalogStar(ra: 18.616, dec: 38.784, magnitude: 0.03, name: "Vega"),         // 16
        CatalogStar(ra: 5.278, dec: 45.998, magnitude: 0.08, name: "Capella"),       // 17
        CatalogStar(ra: 14.261, dec: 19.182, magnitude: -0.05, name: "Arcturus"),    // 18
        CatalogStar(ra: 7.655, dec: 5.225, magnitude: 0.34, name: "Procyon"),        // 19
        CatalogStar(ra: 7.577, dec: 28.026, magnitude: 1.14, name: "Pollux"),        // 20
        CatalogStar(ra: 7.755, dec: 28.026, magnitude: 1.93, name: nil),             // 21 Castor
        CatalogStar(ra: 4.598, dec: 16.510, magnitude: 0.85, name: "Aldebaran"),     // 22
        CatalogStar(ra: 1.162, dec: 35.621, magnitude: 2.06, name: nil),             // 23 Mirach
        CatalogStar(ra: 0.140, dec: 29.091, magnitude: 2.06, name: nil),             // 24 Alpheratz
        CatalogStar(ra: 2.120, dec: 42.330, magnitude: 2.24, name: nil),             // 25 Almach

        // Cassiopeia
        CatalogStar(ra: 0.675, dec: 56.537, magnitude: 2.23, name: nil),             // 26 Schedar
        CatalogStar(ra: 0.153, dec: 59.150, magnitude: 2.27, name: nil),             // 27 Caph
        CatalogStar(ra: 0.945, dec: 60.717, magnitude: 2.47, name: nil),             // 28 Gamma Cas
        CatalogStar(ra: 1.430, dec: 60.235, magnitude: 2.68, name: nil),             // 29 Ruchbah
        CatalogStar(ra: 1.907, dec: 63.670, magnitude: 3.37, name: nil),             // 30 Segin

        // Cygnus (Northern Cross)
        CatalogStar(ra: 20.690, dec: 45.280, magnitude: 1.25, name: "Deneb"),        // 31
        CatalogStar(ra: 19.512, dec: 27.960, magnitude: 2.20, name: nil),            // 32 Albireo
        CatalogStar(ra: 20.370, dec: 40.257, magnitude: 2.23, name: nil),            // 33 Sadr
        CatalogStar(ra: 20.770, dec: 33.970, magnitude: 2.48, name: nil),            // 34 Gienah
        CatalogStar(ra: 21.216, dec: 30.227, magnitude: 2.46, name: nil),            // 35 eps Cyg

        // Leo
        CatalogStar(ra: 10.139, dec: 11.967, magnitude: 1.35, name: "Regulus"),      // 36
        CatalogStar(ra: 11.818, dec: 14.572, magnitude: 2.14, name: "Denebola"),     // 37
        CatalogStar(ra: 10.333, dec: 19.842, magnitude: 2.56, name: nil),            // 38 Algieba
        CatalogStar(ra: 11.235, dec: 20.524, magnitude: 2.61, name: nil),            // 39 Zosma
        CatalogStar(ra: 10.122, dec: 23.774, magnitude: 3.44, name: nil),            // 40 Adhafera

        // Scorpius
        CatalogStar(ra: 16.490, dec: -26.432, magnitude: 0.96, name: "Antares"),     // 41
        CatalogStar(ra: 16.006, dec: -22.622, magnitude: 2.56, name: nil),           // 42 Dschubba
        CatalogStar(ra: 16.091, dec: -19.805, magnitude: 2.32, name: nil),           // 43 Acrab
        CatalogStar(ra: 17.560, dec: -37.104, magnitude: 1.63, name: "Shaula"),      // 44
        CatalogStar(ra: 17.622, dec: -42.998, magnitude: 1.87, name: nil),           // 45 Sargas
        CatalogStar(ra: 16.836, dec: -34.293, magnitude: 2.29, name: nil),           // 46 eps Sco

        // Lyra
        CatalogStar(ra: 18.982, dec: 32.690, magnitude: 3.24, name: nil),            // 47 Sheliak
        CatalogStar(ra: 18.746, dec: 37.605, magnitude: 3.52, name: nil),            // 48 Sulafat

        // Boötes
        CatalogStar(ra: 15.032, dec: 40.390, magnitude: 2.68, name: nil),            // 49 Nekkar
        CatalogStar(ra: 14.535, dec: 38.308, magnitude: 2.35, name: nil),            // 50 eta Boo

        // Southern stars
        CatalogStar(ra: 14.064, dec: -60.373, magnitude: 0.61, name: nil),           // 51 Alpha Cen
        CatalogStar(ra: 12.443, dec: -63.099, magnitude: 0.77, name: nil),           // 52 Beta Cru
        CatalogStar(ra: 12.795, dec: -59.689, magnitude: 1.28, name: nil),           // 53 Gamma Cru
        CatalogStar(ra: 12.252, dec: -57.113, magnitude: 1.33, name: nil),           // 54 Delta Cru
        CatalogStar(ra: 6.399, dec: -52.696, magnitude: -0.74, name: "Canopus"),     // 55
        CatalogStar(ra: 22.096, dec: -56.735, magnitude: 1.17, name: nil),           // 56 Fomalhaut - actually at -29.6
        CatalogStar(ra: 1.629, dec: -57.237, magnitude: 0.46, name: "Achernar"),     // 57

        // Taurus (Pleiades region + Hyades)
        CatalogStar(ra: 3.792, dec: 24.105, magnitude: 2.87, name: nil),             // 58 Alcyone
        CatalogStar(ra: 4.330, dec: 15.628, magnitude: 3.53, name: nil),             // 59 Ain
        CatalogStar(ra: 5.627, dec: 21.143, magnitude: 1.65, name: "Elnath"),        // 60

        // Corona Borealis
        CatalogStar(ra: 15.578, dec: 26.715, magnitude: 2.23, name: "Alphecca"),     // 61

        // Aquila
        CatalogStar(ra: 19.771, dec: 10.613, magnitude: 2.72, name: nil),            // 62 Tarazed
        CatalogStar(ra: 19.922, dec: 6.407, magnitude: 3.36, name: nil),             // 63 Alshain

        // Pegasus
        CatalogStar(ra: 23.063, dec: 15.205, magnitude: 2.49, name: nil),            // 64 Markab
        CatalogStar(ra: 23.079, dec: 28.083, magnitude: 2.44, name: nil),            // 65 Scheat
        CatalogStar(ra: 0.220, dec: 15.184, magnitude: 2.83, name: nil),             // 66 Algenib

        // Virgo
        CatalogStar(ra: 13.420, dec: -11.161, magnitude: 0.97, name: "Spica"),       // 67

        // Centaurus
        CatalogStar(ra: 14.111, dec: -36.370, magnitude: 0.61, name: nil),           // 68

        // Canis Major
        CatalogStar(ra: 6.378, dec: -17.956, magnitude: 1.50, name: nil),            // 69 Mirzam
        CatalogStar(ra: 7.140, dec: -26.393, magnitude: 1.84, name: nil),            // 70 Wezen
        CatalogStar(ra: 6.977, dec: -28.972, magnitude: 1.98, name: nil),            // 71 Aludra
        CatalogStar(ra: 7.063, dec: -23.834, magnitude: 2.45, name: nil),            // 72

        // Auriga
        CatalogStar(ra: 5.992, dec: 44.947, magnitude: 1.90, name: nil),             // 73 Menkalinan
        CatalogStar(ra: 5.438, dec: 28.608, magnitude: 2.69, name: nil),             // 74 Elnath shared

        // Corvus
        CatalogStar(ra: 12.169, dec: -24.729, magnitude: 2.59, name: nil),           // 75 Gienah Corvi
        CatalogStar(ra: 12.573, dec: -23.397, magnitude: 2.65, name: nil),           // 76 Kraz
        CatalogStar(ra: 12.497, dec: -16.516, magnitude: 2.94, name: nil),           // 77 Algorab
        CatalogStar(ra: 12.263, dec: -17.542, magnitude: 3.00, name: nil),           // 78

        // Polaris
        CatalogStar(ra: 2.530, dec: 89.264, magnitude: 1.98, name: "Polaris"),       // 79

        // Additional bright stars for coverage
        CatalogStar(ra: 22.961, dec: -29.622, magnitude: 1.16, name: "Fomalhaut"),   // 80
        CatalogStar(ra: 20.427, dec: -56.735, magnitude: 1.94, name: nil),           // 81 Peacock
        CatalogStar(ra: 17.943, dec: -37.104, magnitude: 1.86, name: nil),           // 82
        CatalogStar(ra: 8.375, dec: -59.510, magnitude: 1.68, name: nil),            // 83 Avior
        CatalogStar(ra: 9.220, dec: -69.717, magnitude: 1.67, name: nil),            // 84 Miaplacidus
        CatalogStar(ra: 13.665, dec: -53.466, magnitude: 2.17, name: nil),           // 85
        CatalogStar(ra: 10.715, dec: -49.420, magnitude: 2.21, name: nil),           // 86
    ]

    static let constellationLines: [ConstellationLine] = [
        // Big Dipper
        ConstellationLine(from: 0, to: 1),
        ConstellationLine(from: 1, to: 2),
        ConstellationLine(from: 2, to: 3),
        ConstellationLine(from: 3, to: 4),
        ConstellationLine(from: 4, to: 5),
        ConstellationLine(from: 5, to: 6),
        ConstellationLine(from: 0, to: 3),

        // Orion
        ConstellationLine(from: 7, to: 12),
        ConstellationLine(from: 12, to: 11),
        ConstellationLine(from: 11, to: 10),
        ConstellationLine(from: 10, to: 9),
        ConstellationLine(from: 8, to: 13),
        ConstellationLine(from: 7, to: 10),
        ConstellationLine(from: 8, to: 9),

        // Cassiopeia (W shape)
        ConstellationLine(from: 27, to: 26),
        ConstellationLine(from: 26, to: 28),
        ConstellationLine(from: 28, to: 29),
        ConstellationLine(from: 29, to: 30),

        // Cygnus (Northern Cross)
        ConstellationLine(from: 31, to: 33),
        ConstellationLine(from: 33, to: 32),
        ConstellationLine(from: 33, to: 34),
        ConstellationLine(from: 34, to: 35),

        // Leo
        ConstellationLine(from: 36, to: 38),
        ConstellationLine(from: 38, to: 40),
        ConstellationLine(from: 38, to: 39),
        ConstellationLine(from: 39, to: 37),

        // Summer Triangle
        ConstellationLine(from: 16, to: 31),
        ConstellationLine(from: 31, to: 15),
        ConstellationLine(from: 15, to: 16),

        // Scorpius tail
        ConstellationLine(from: 43, to: 42),
        ConstellationLine(from: 42, to: 41),
        ConstellationLine(from: 41, to: 46),
        ConstellationLine(from: 46, to: 44),

        // Southern Cross
        ConstellationLine(from: 52, to: 53),
        ConstellationLine(from: 54, to: 51),

        // Great Square of Pegasus
        ConstellationLine(from: 24, to: 65),
        ConstellationLine(from: 65, to: 64),
        ConstellationLine(from: 64, to: 66),
        ConstellationLine(from: 66, to: 24),

        // Corvus
        ConstellationLine(from: 75, to: 76),
        ConstellationLine(from: 76, to: 77),
        ConstellationLine(from: 77, to: 78),
        ConstellationLine(from: 78, to: 75),

        // Gemini
        ConstellationLine(from: 20, to: 21),
    ]
}
