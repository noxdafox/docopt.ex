defmodule Chupah do
  # @docopt """
  # Usage: cazzo_buddha_culo
  # """

  # @docopt """
  # Naval Fate.

  # Usage:
  #   naval_fate
  #   naval_fate ship new <name>...
  #   naval_fate ship <name> move <x> <y> [--speed=<kn>]
  #   naval_fate ship shoot <x> <y>
  #   naval_fate mine (set|remove) <x> <y> [--moored|--drifting]
  #   naval_fate cazzo (merda succhia | ahahaha)
  #   naval_fate -h | --help
  #   naval_fate --version
  #   naval_fate --asgaberez=<barnawi> -a <aghagha>
  #   naval_fate -sSUCA --sambuca BUCA
  #   naval_fate -f<figa> --figa <bambiga>
  #   naval_fate -lLOLLE --lalu BALU
  #   naval_fate --buga <ugah>

  # Options:
  #   -h --help     Show this screen.
  #   --version     Show version.
  #   -s <kn> --speed=<kn>  Speed in knots [default: 10].
  #   -f FILE --file=FILE  ciciu pasticiu  [default: asbinow].
  #   --moored      Moored (anchored) mine.
  #   --drifting    Drifting mine.
  #   -l LOLLE      asdasd.
  #   --lalu BALU    ciciu.
  #   --buga <ugah>  [default: mammetah].
  # """

  @docopt """
  Usage:
    naval_fate [--pass]
    naval_fate ship new <name>...
    naval_fate do (cacca | tanta pipi) [--speed=<kn>]
    naval_fate ship <name> move <x> <y> [--speed=<kn> --lul=<km>]

  Options:
    -h --help     Show this screen.
    --version     Show version.
    -s <kn> --speed=<kn>  Speed in knots [default: 10].

  """

  require Docopt

  def lulah(arguments) do
    Docopt.parse_arguments(arguments)
  end
end
