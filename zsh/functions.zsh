# -------------------------------------------------------------------
# display a neatly formatted path
# -------------------------------------------------------------------
function path() {
  echo $PATH | tr ":" "\n" | \
    awk "{ sub(\"/usr\",   \"$fg_no_bold[green]/usr$reset_color\"); \
           sub(\"/bin\",   \"$fg_no_bold[blue]/bin$reset_color\"); \
           sub(\"/opt\",   \"$fg_no_bold[cyan]/opt$reset_color\"); \
           sub(\"/sbin\",  \"$fg_no_bold[magenta]/sbin$reset_color\"); \
           sub(\"/local\", \"$fg_no_bold[yellow]/local$reset_color\"); \
           print }"
}


# -------------------------------------------------------------------
# nice mount (http://catonmat.net/blog/another-ten-one-liners-from-commandlingfu-explained)
# displays mounted drive information in a nicely formatted manner
# -------------------------------------------------------------------
function nicemount() { (echo "DEVICE PATH TYPE FLAGS" && mount | awk '$2="";1') | column -t ; }

# -------------------------------------------------------------------
# myIP address
# -------------------------------------------------------------------
function myip() {
  ifconfig lo0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "lo0       : " $2}'
  ifconfig en0 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en0 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en0 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en0 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en1 | grep 'inet ' | sed -e 's/:/ /' | awk '{print "en1 (IPv4): " $2 " " $3 " " $4 " " $5 " " $6}'
  ifconfig en1 | grep 'inet6 ' | sed -e 's/ / /' | awk '{print "en1 (IPv6): " $2 " " $3 " " $4 " " $5 " " $6}'
}


# -------------------------------------------------------------------
# sre#10m
# -------------------------------------------------------------------

function tss() {
  if [ -z "$GH_USER" ]; then
    echo "❌ GH_USER environment variable is not set."
    return 1
  fi

  if [ $# -eq 0 ]; then
    echo "❌ Please enter a client name."
    return 1
  fi

  options_to_login=($(tsh ls | grep "$1" | awk '{print $1}'))

  if [ ${#options_to_login[@]} -eq 0 ]; then
    echo "❌ No instances found for client name: $1"
    return 1
  fi

  echo "Please select an instance:"
  select opt in "${options_to_login[@]}"; do
    if [ -n "$opt" ]; then
      echo "Accessing $opt"
      tsh ssh "$GH_USER@$opt"
      break
    else
      echo "❌ Invalid selection. Please try again."
    fi
  done
}
