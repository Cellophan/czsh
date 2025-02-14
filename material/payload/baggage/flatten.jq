# https://stackoverflow.com/questions/68180497/simple-command-to-flat-unflatten-json-files
# | reduce .[] as $x ([]; .[$x[0]] = $x[1])

#  | reduce .[] as $x ([]; . + ["" + $x[0] + "=" + "z"] )
#  | .[];


def key:
  map(if type == "number" then "[\(tostring)]" else . end) | join(".");

def flattenjson:
  [ . as $json | paths(scalars) | . as $path | [key, ($json | getpath($path))] ]
  | reduce .[] as $x ([]; . + ["" + $x[0] + "=" + "z"] )
  | .[];

flattenjson

