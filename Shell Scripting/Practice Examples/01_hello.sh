file=$1
if [ -e "$file" ]; then
    echo "File exists."
    [ -r "$file" ] && echo "Readable" || echo "Not readable"
    [ -w "$file" ] && echo "Writable" || echo "Not writable"
    [ -x "$file" ] && echo "Executable" || echo "Not executable"
else
    echo "Error: File does not exist."
fi