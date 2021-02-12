pwd
cat ./src/main.lua > ./out/compiled.lua
input="./out/compiled.lua"

while read -r line
do
    printf 'Line: %s\n' "$line"

    current=$line
    last=$current
    secondlast=$last

    printf 'Loop: %s %s %s\n' "$current" "$last" "$secondlast"
done < $input

printf 'After: %s %s %s\n' "$current" "$last" "$secondlast"