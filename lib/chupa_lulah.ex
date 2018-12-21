[
  [long: "--lul", argument: "<km>"],
  [argument: "<y>"],
  [argument: "<x>"],
  [literal: "move"],
  [literal: "pipi"],
  [literal: "tanta"],
  [literal: "cacca"],
  [literal: "do"],
  [argument: "<id>"],
  [argument: "<surname>"],
  [argument: "<name>"],
  [literal: "new"],
  [literal: "ship"],
  [short: "-h", long: "--help"],
  [long: "--version"],
  [default: "10", short: "-s", argument: "<kn>", long: "--speed"]
]
[
  {"<surname>", "Sbaracaccheo"},
  {"<name>", "Matteo"},
  {"new", true},
  {"ship", true}
]

[
  required: [
    xor: [
      [
        required: [
          {:literal, "ship"},
          {:literal, "new"},
          {:argument, "<name>"},
          :ellipses
        ]
      ],
      [
        required: [
          literal: "ship",
          argument: "<name>",
          literal: "move",
          argument: "<x>",
          argument: "<y>",
          optional: [{:long, "--speed", "<kn>"}]
        ]
      ],
      [
        required: [
          literal: "ship",
          literal: "shoot",
          argument: "<x>",
          argument: "<y>"
        ]
      ],
      [
        required: [
          literal: "mine",
          required: [xor: [[literal: "set"], [literal: "remove"]]],
          argument: "<x>",
          argument: "<y>",
          optional: [xor: [[long: "--moored"], [long: "--drifting"]]]
        ]
      ],
      [
        required: [
          literal: "cazzo",
          required: [
            xor: [[literal: "succhia", literal: "merda"], [literal: "ahahaha"]]
          ]
        ]
      ],
      [required: [xor: [[short: "-h"], [long: "--help"]]]],
      [required: [long: "--version"]],
      [
        required: [
          {:long, "--asgaberez", "<barnawi>"},
          {:short, "-a", "<aghagha>"}
        ]
      ],
      [
        required: [
          short: "-s",
          short: "-S",
          short: "-U",
          short: "-C",
          short: "-A",
          long: "--sambuca",
          argument: "BUCA"
        ]
      ],
      [
        required: [
          {:short, "-f", "<figa>"},
          {:long, "--figa"},
          {:argument, "<bambiga>"}
        ]
      ],
      [required: [{:short, "-l", "LOLLE"}, {:long, "--lalu", "BALU"}]],
      [required: [{:long, "--buga", "<ugah>"}]]
    ]
  ]
]
