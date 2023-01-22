function cdv -d "\$CODE specific cd"
  if count $argv &> /dev/null
    if test -e "$CODE/$argv[1]"
      cd "$CODE/$argv[1]"
    else
      cd (fd -1a -t d -d 1 "$argv[1]" "$CODE")
    end
  else
    cd $CODE
  end
end
