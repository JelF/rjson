module RJSON
  # Contains RJSON version in 'a.b.c.d' format
  # a = 0, as RJSON is unreleased
  # b for MAJOR version, breaking back-compatibitily
  # c for MAJOR version, which does not break back-compatibitily
  # d for MINOR version, which does not change private API
  # Use '~> a.b.c.d' in case you rely on private API
  # (which is not you should do)
  # or '~> a.b.c' in case you don't
  # never use ' ~> a.b' or weaker, even if you have coverage and braveness
  # upgrading a or b requires stage testing
  VERSION = '0.1.1.0'.freeze
end
