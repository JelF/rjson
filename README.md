# RJSON

RJSON describes RJSON (Ruby JSON) serializer and RJSON format.

The desiarilzation rules are simple:

## Array
Array always stays array

## String

There are controll sequenence prefixes, allowed at start of string,
to describe it's ruby type

`"foo"` is a string `"foo"`
`":foo"` is a symbol `:foo`
`"%:foo"` is a string `":foo"`
`"%%foo"` is a string `"%foo"`
`"a%foo"` is a string `"a%foo"`, because % is not at the start of string

## Hash

There is a private hash namespace, prefixed by `__rjson_`
Keys converted as strings, i.e. `":foo": "bar"` is `foo: "bar"`
and `"%__rjson_"` is `"__rjson_"` key outside private namespace

special keys are thrown inside a builder, defined by `__rjson_builder`
API is
```ruby
builder = options.delete("builder")
builder.camelize.constantize.new(options).build(data)
```

where options are private keys with prefix removed and data is the rest

## RSON::ObjectBuilder

`RJSON::ObjectBuilder` is the default builder. Serialization build it
It requires `__rjson_class` parameter, and creates an instance of
`__rjson_class`, threating all keys as ivars  
If there is a key, not begining with `@` it raises an error  
If there is a key, begining with `@@` it raises an error  


## Back compatibility with YAML

It is 100% back compatible, except YAML stores hash with `__rjson_` prefix
To provided it, JSON is red by YAML loader, which is 100%
back-compatible with JSON. If generic object found, nothing would be done
