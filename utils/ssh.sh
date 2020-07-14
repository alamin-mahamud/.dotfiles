ssh-keygen -t rsa -b 4096 -C "alamin.ineedahelp@gmail.com"
eval "$(ssh-agent -s)"

FILE=$HOME/.ssh/config
if ! test -f "$FILE"; then
	echo "$FILE exists."
else
	touch $FILE
	echo "Host *
  	    AddKeysToAgent yes
  	    UseKeychain yes
  	    IdentityFile ~/.ssh/id_rsa" >> $FILE
	echo "Created $FILE!"
fi

ssh-add -K ~/.ssh/id_rsa
