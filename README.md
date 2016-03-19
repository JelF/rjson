# RJSON

RJSON describes RJSON (Ruby JSON) serializer and RJSON format.  
_IMPORTANT NOTE ABOUT SECURITY_:
RJSON parsing is insecure, you should parse only data you dumped yourself.

The desiarilzation rules are simple:

## Array
Array always stays array

## String

There are control sequence prefixes, allowed at start of string,
to describe it's ruby type

`"foo"` is a string `"foo"`
`":foo"` is a symbol `:foo`
`"%:foo"` is a string `":foo"`
`"%%foo"` is a string `"%foo"`
`"a%foo"` is a string `"a%foo"`, because % is not at the start of string
`'!"foo"'` is a string `"foo"`, which is coded by `"foo"` nested json
`'!{"foo": 123}'` is a hash `{ "foo" => 123 }`
`'%!"foo"'` is a string `'!"foo"'`

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
It requires `__rjson_class_name` parameter, and creates an instance of
`__rjson_class_name`, threating all keys as ivars  
If there is a key, not begining with `@` it raises an error  
If there is a key, begining with `@@` it raises an error  


## Back compatibility with YAML

It is 100% back compatible, except YAML stores hashes with keys with our
prefixes. To provided it, JSON is red by YAML loader, which is 100%
back-compatible with JSON. If generic object found, nothing would be done

## Contributing

* _Optional: read other issues, including closed_
* Make an issue, describing what you want to do and wait me (JelF),
or contact me in other way  
* [.rubocop.yml] contains not only rules for linter, but for humans too,
please check it before you start  
* Fork it  
* Make a branch  
* Make a pull request  

Or simply describe all you want me to do inside an issue,
this would also be helpful
